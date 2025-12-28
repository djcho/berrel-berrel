-- 상수 설정
local TIME_DIVISOR = 100
local GRAVITY_SCALE = 0.5

local RAYCAST_OFFSET = 4000  -- 레이캐스트 오프셋 설정
local MAX_BARREL_LEVEL = 4  -- 최대 배럴 레벨 설정
local DEFAULT_LEVEL = 1  -- 기본 레벨 설정

-- 서비스 로드
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local throwingBarrelEvent = ReplicatedStorage:WaitForChild("ThrowingBarrelEvent")
local RunService = game:GetService('RunService')
local SoundService = game:GetService("SoundService")
local LoudSpeaker = require(ServerStorage.Scripts.LoudSpeaker)
local CommonUtil = require(ServerStorage.Scripts.CommonUtil)
local ItemDb = require(ServerStorage.Items.Database.ItemDb)

-- BaseBarrel 클래스 정의
local BaseBarrel = {}
BaseBarrel.__index = BaseBarrel

-- 새로운 배럴 객체 생성 함수
-- toolInfo: ToolItem 인스턴스 (ItemDb의 설정을 포함)
function BaseBarrel.new(player, toolInfo, level)
	local self = setmetatable({}, BaseBarrel)

	self.Player = player
	self.Level = level or DEFAULT_LEVEL
	self.onTouchedBarrelCooldown = false

	-- toolInfo에서 시각/효과 설정 가져오기
	self.ToolInfo = toolInfo
	self.HitDamage = toolInfo.Damage
	self.DotDamage = toolInfo.DotDamage or 0
	self.MaxRange = toolInfo.MaxRange
	self.ExplosionRadius = toolInfo.ExplosionRadius or 5
	self.Name = toolInfo.DisplayName

	-- ItemDb에서 시각/효과 설정 가져오기
	local itemConfig = ItemDb.Tool[toolInfo.Name]
	if itemConfig then
		self.PartName = itemConfig.PartName
		self.FallbackPartName = itemConfig.FallbackPartName
		self.ExplodeEffects = itemConfig.ExplodeEffects or {}
		self.ExplodeSound = itemConfig.ExplodeSound
		self.TrailParticle = itemConfig.TrailParticle
	end

	-- 파트 생성 (PartName 사용)
	local partName = self.PartName or toolInfo.Name

	-- ServerStorage/Parts에서 파트 찾기
	local partsFolder = ServerStorage:FindFirstChild("Parts")
	local barrelPart = partsFolder and partsFolder:FindFirstChild(partName)

	-- Fallback 파트 사용
	if not barrelPart and self.FallbackPartName and partsFolder then
		barrelPart = partsFolder:FindFirstChild(self.FallbackPartName)
	end

	if barrelPart then
		self.BarrelPart = barrelPart:Clone()
		local newPosition = player.Character.HumanoidRootPart.Position + Vector3.new(20, 22, -2)
		self.BarrelPart.CFrame = CFrame.new(newPosition)
		self.BarrelPart.CanTouch = true
		self.BarrelPart.CanCollide = true
		self.BarrelPart.Parent = workspace
		self.BarrelPart:SetNetworkOwner(nil)

		-- 잔상 효과 추가 (TrailParticle 설정이 있으면)
		-- 경로: ServerStorage/Trail/[TrailParticle]
		if self.TrailParticle then
			local trailFolder = ServerStorage:FindFirstChild("Trail")
			if trailFolder then
				local trailTemplate = trailFolder:FindFirstChild(self.TrailParticle)
				if trailTemplate then
					if trailTemplate:IsA("Trail") then
						-- Trail 객체인 경우: 두 개의 Attachment 필요
						local attachment0 = Instance.new("Attachment")
						attachment0.Name = "TrailAttachment0"
						attachment0.Position = Vector3.new(0, 0.5, 0)
						attachment0.Parent = self.BarrelPart

						local attachment1 = Instance.new("Attachment")
						attachment1.Name = "TrailAttachment1"
						attachment1.Position = Vector3.new(0, -0.5, 0)
						attachment1.Parent = self.BarrelPart

						local trail = trailTemplate:Clone()
						trail.Attachment0 = attachment0
						trail.Attachment1 = attachment1
						trail.Parent = self.BarrelPart
					elseif trailTemplate:IsA("ParticleEmitter") then
						-- ParticleEmitter인 경우: Attachment 하나에 붙임
						local attachment = Instance.new("Attachment")
						attachment.Name = "TrailAttachment"
						attachment.Parent = self.BarrelPart

						local trail = trailTemplate:Clone()
						trail.Parent = attachment
					end
				end
			end
		end

		-- 배럴이 다른 객체와 충돌할 때 이벤트 연결
		self.BarrelPart.Touched:Connect(function(touchedPart)
			if not self:IsPlayerOrEquipmentPart(touchedPart) and self.BarrelPart:CanCollideWith(touchedPart) then
				self:OnTouchingBarrel(touchedPart)
			end
		end)
	else
		warn("[BaseBarrel] Part not found: " .. tostring(partName))
	end

	return self
end

-- 배럴이 플레이어나 장비의 일부인지 확인하는 함수
function BaseBarrel:IsPlayerOrEquipmentPart(touchedPart)
	local character = self.Player.Character
	if not character then return false end

	-- 플레이어의 캐릭터 파츠 확인
	for _, part in ipairs(character:GetChildren()) do
		if part == touchedPart then
			return true
		end
	end

	-- 플레이어의 장비 파츠 확인
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		for _, accessory in ipairs(humanoid:GetAccessories()) do
			local handle = accessory:FindFirstChildWhichIsA("BasePart")
			if handle == touchedPart then
				return true
			end
		end
	end

	return false
end

-- 배럴을 목표 위치로 던지는 함수
function BaseBarrel:Throw(targetPosition)
	local player = self.Player

	local x0 = player.Character.HumanoidRootPart.Position + Vector3.new(0, 2, 0)
	local mousePosition = targetPosition

	-- 캐릭터와 마우스 위치 간의 벡터 계산
	local direction = (mousePosition - x0).unit
	x0 = x0 + direction * 2

	local distance = (targetPosition - x0).magnitude
	if distance > self.MaxRange then
		distance = self.MaxRange
		targetPosition = x0 + (targetPosition - x0).unit * self.MaxRange
	end

	local t = distance / TIME_DIVISOR
	local g = Vector3.new(0, -game.Workspace.Gravity * GRAVITY_SCALE, 0)
	local v0 = (targetPosition - x0 - 0.5 * g * t * t) / t

	local startTime = tick()

	-- 클라이언트에 투사체 생성 이벤트 전송 (렌더링은 클라이언트가 담당)
	-- 서버 투사체는 판정용으로만 사용하고 투명하게 처리
	throwingBarrelEvent:FireAllClients(self.BarrelPart, x0, v0, g, t)
	self.BarrelPart.Transparency = 1  -- 서버 투사체 숨김 (클라이언트에서 렌더링)

	-- 서버에서 투사체 위치 업데이트 (판정용, 시각적 렌더링은 클라이언트)
	local heartbeatConnection
	local tornadoInfluence = Vector3.new(0, 0, 0)  -- 토네이도 영향 누적

	heartbeatConnection = RunService.Heartbeat:Connect(function()
		-- 배럴이 이미 파괴되었는지 확인
		if not self.BarrelPart or not self.BarrelPart.Parent then
			heartbeatConnection:Disconnect()
			return
		end

		local nt = tick() - startTime
		if nt > t * 2 then
			heartbeatConnection:Disconnect()
			if self.BarrelPart and self.BarrelPart.Parent then
				self.BarrelPart:Destroy()
			end
			return
		end

		-- 기본 포물선 위치
		local basePosition = 0.5 * g * nt * nt + v0 * nt + x0

		-- 토네이도 영향 체크
		for _, child in workspace:GetChildren() do
			if child.Name == "Tornado" and child:IsA("BasePart") then
				local toTornado = child.Position - basePosition
				local distToTornado = toTornado.Magnitude
				local tornadoRadius = 20  -- 토네이도 영향 범위

				if distToTornado < tornadoRadius then
					-- 토네이도에 가까울수록 강하게 끌림
					local pullStrength = (tornadoRadius - distToTornado) / tornadoRadius
					local tangent = Vector3.new(-toTornado.Z, 0, toTornado.X).Unit
					local inward = toTornado.Unit

					-- 스윙바이 효과: 회전 + 약간 끌림
					tornadoInfluence = tornadoInfluence + (tangent * 3 + inward * 1.5) * pullStrength
				end
			end
		end

		self.BarrelPart.Position = basePosition + tornadoInfluence
	end)
end

-- 배럴이 폭발하는 함수 (하위 클래스에서 재정의)
function BaseBarrel:Explode(hitPart, _hitPosition)
	if self:IsInWater(hitPart) then
		self:FloatOnWater(hitPart)
		return false
	end

	-- 폭발 이펙트 재생 (ItemDb 설정 사용)
	self:PlayExplodeEffects()

	return true
end

-- 폭발 이펙트와 사운드 재생 (ItemDb 설정 기반)
function BaseBarrel:PlayExplodeEffects()
	-- 폭발 사운드 재생
	if self.ExplodeSound then
		local remoteEvent = ReplicatedStorage:FindFirstChild("PlaySoundEvent")
		if remoteEvent then
			remoteEvent:FireAllClients(self.ExplodeSound, 0, 1)
		end
	end

	-- 폭발 이펙트 재생
	if self.ExplodeEffects and self.BarrelPart then
		local barrelPosition = self.BarrelPart.Position

		-- workspace에 고정된 파트 생성 (이펙트 표시용)
		local effectPart = Instance.new("Part")
		effectPart.Name = "EffectAnchor"
		effectPart.Size = Vector3.new(1, 1, 1)
		effectPart.Position = barrelPosition
		effectPart.Anchored = true
		effectPart.CanCollide = false
		effectPart.Transparency = 1
		effectPart.Parent = workspace

		local effectFolder = ServerStorage:FindFirstChild("Effect")
		local particlesToEmit = {}

		if effectFolder then
			for _, effectName in ipairs(self.ExplodeEffects) do
				local effectTemplate = effectFolder:FindFirstChild(effectName)

				if effectTemplate then
					if effectTemplate:IsA("ParticleEmitter") then
						local effect = effectTemplate:Clone()
						effect.Enabled = false
						effect.Parent = effectPart
						local emitCount = effect:GetAttribute("EmitCount") or 10
						table.insert(particlesToEmit, {emitter = effect, count = emitCount})
					else
						for _, child in ipairs(effectTemplate:GetDescendants()) do
							if child:IsA("ParticleEmitter") then
								local effect = child:Clone()
								effect.Enabled = false
								effect.Parent = effectPart
								local emitCount = effect:GetAttribute("EmitCount") or 10
								table.insert(particlesToEmit, {emitter = effect, count = emitCount})
							end
						end
					end
				end
			end
		end

		-- 클라이언트 복제 대기 후 Emit 호출
		task.defer(function()
			for _, data in ipairs(particlesToEmit) do
				data.emitter:Emit(data.count)
			end
		end)

		-- 2초 후 이펙트 파트 제거
		game.Debris:AddItem(effectPart, 2)
	end
end

-- 배럴 레벨을 업그레이드하는 함수
function BaseBarrel:UpgradeLevel()
	if self.Level == MAX_BARREL_LEVEL then
		return
	end

	self.Level += 1
	local barrelScale = 1.5
	CommonUtil:ScaleModel(self.BarrelPart, barrelScale)
end

-- 충돌한 파트의 플레이어에게 피해를 주는 공통 함수 (팀킬 방지 포함)
function BaseBarrel:DealDamageToTarget(hitPart, damage)
	local humanoid = CommonUtil:GetHumanoidByPart(hitPart)
	if not humanoid then
		return false
	end

	-- 자기 자신 체크
	if humanoid.Parent.Name == self.Player.Character.Name then
		return false
	end

	-- 팀킬 방지
	local targetPlayer = CommonUtil:GetPlayerByPart(hitPart)
	if CommonUtil:IsSameTeam(self.Player, targetPlayer) then
		return false
	end

	-- creator 태그 설정 (킬/어시스트 추적용)
	self:SetCreatorTag(humanoid)

	humanoid:TakeDamage(damage)
	return true
end

-- creator 태그 설정 함수 (킬/어시스트 시스템용)
function BaseBarrel:SetCreatorTag(humanoid)
	-- 기존 creator 태그 제거
	local existingCreator = humanoid:FindFirstChild("creator")
	if existingCreator then
		existingCreator:Destroy()
	end

	-- 새 creator 태그 생성
	local creator = Instance.new("ObjectValue")
	creator.Name = "creator"
	creator.Value = self.Player
	creator.Parent = humanoid

	-- 5초 후 자동 제거 (어시스트 시간 제한)
	game.Debris:AddItem(creator, 5)
end

-- 레이캐스트를 사용하여 주어진 위치에서 Y 축을 따라 위치를 계산하는 함수
function BaseBarrel:GetPositionFromSubjectUsingYRaycast(subjectPosition)
	-- 배럴 파트를 제외할 객체들을 모은 테이블 생성
	local excludeList = {}
	table.insert(excludeList, self.BarrelPart)

	-- ServerStorage/Effect 내부의 모든 객체 이름을 가져옴
	local effectNames = {}
	local effectFolder = game:GetService("ServerStorage"):FindFirstChild("Effect")
	if effectFolder then
		for _, v in pairs(effectFolder:GetDescendants()) do
			if v:IsA("BasePart") then
				table.insert(effectNames, v.Name)
			end
		end
	end

	-- 워크스페이스에서 Oil 모델 전체, PoisonFog 모델 전체를 제외 목록에 추가
	for _, child in workspace:GetChildren() do
		if child:IsA("Model") and (child.Name:match("Oil") or child.Name:match("Poison")) then
			table.insert(excludeList, child)  -- 모델 전체를 추가하면 하위 파트도 제외됨
		end
	end

	-- 워크스페이스에서 SlowPart, 이펙트 파트들, WindZone, Tornado 제외
	for _, v in pairs(workspace:GetDescendants()) do
		if v:IsA("BasePart") then
			local shouldExclude = v.Name:match("SlowPart")
				or v.Name == "WindZone"
				or v.Name == "Tornado"
				or v.Name == "EffectAnchor"
				or v:GetAttribute("WindBarrelZone")
				or table.find(effectNames, v.Name)
			if shouldExclude then
				table.insert(excludeList, v)
			end
		end
	end

	-- 레이캐스트 매개변수 설정
	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = excludeList
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude

	-- 레이캐스트 시작 위치 설정 (Y축으로 오프셋 적용)
	local raycastPosition = Vector3.new(subjectPosition.X, subjectPosition.Y + RAYCAST_OFFSET, subjectPosition.Z)
	-- 레이캐스트 수행 (아래로 5000 스터드 거리)
	local raycastDirection = Vector3.new(0, -5000, 0)
	local raycastResult = workspace:Raycast(raycastPosition, raycastDirection, raycastParams)

	return raycastResult
end


-- 배럴이 다른 객체와 충돌했을 때 호출되는 함수 (하위 클래스에서 재정의)
function BaseBarrel:OnTouched(hitPart)
end

-- 배럴이 다른 객체와 충돌했을 때 호출되는 함수
function BaseBarrel:OnTouchingBarrel(hitPart)
	self.onTouchedBarrelCooldown = true

	-- 폭발 위치 저장 (Destroy 전에)
	local barrelPosition = self.BarrelPart.Position
	local raycastResult = self:GetPositionFromSubjectUsingYRaycast(barrelPosition)

	if raycastResult then
		-- 폭발 효과 및 OnTouched 먼저 실행 (BarrelPart가 아직 존재할 때)
		self:OnTouched(hitPart)
		self:Explode(hitPart, raycastResult.Position)
	end

	-- 이펙트 재생 후 파트 파괴
	if self.BarrelPart and self.BarrelPart.Parent then
		self.BarrelPart:Destroy()
	end

	self.onTouchedBarrelCooldown = false
end

function BaseBarrel:IsInWater(hitPart)
	if hitPart:IsA("Terrain") then
		local position = hitPart.Position
		local region = Region3.new(position - Vector3.new(1, 1, 1), position + Vector3.new(1, 1, 1))
		local success, materials = pcall(function()
			return workspace.Terrain:ReadVoxels(region, Vector3int16.new(1, 1, 1))
		end)

		-- ReadVoxels가 성공적으로 호출되지 않은 경우 (예외 발생 시)
		if not success then
			-- 예외가 발생하면 물 위에 있다고 가정
			return true
		end

		-- ReadVoxels가 성공적으로 호출된 경우 해당 지역의 물질이 Water인지 확인
		if materials and materials[1][1][1] == Enum.Material.Water then
			return true
		end
	end
	return false
end


-- 물 위에 떠 있도록 하는 함수
function BaseBarrel:FloatOnWater(_position)
	local loudSpeaker = LoudSpeaker.new()
	loudSpeaker:PlayLoudly(SoundService.SplashWater)

	-- 현재 배럴 위치와 속도 저장
	local currentPosition = self.BarrelPart.Position
	local currentVelocity = self.BarrelPart.AssemblyLinearVelocity or Vector3.new(0, -20, 0)

	local barrelClone = self.BarrelPart:Clone()
	barrelClone.Name = "FloatingBarrel"
	barrelClone.Transparency = 0
	barrelClone.CanCollide = false  -- 물과 충돌 안함
	barrelClone.Anchored = false
	barrelClone.Position = currentPosition
	barrelClone.Parent = workspace

	-- 물 표면 높이 계산 (대략적으로 현재 위치 기준)
	local waterSurfaceY = currentPosition.Y + 2  -- 물 표면 추정

	-- 물리 시뮬레이션으로 자연스럽게 떨어지다가 물 위에 뜨기
	local floatForce = Instance.new("BodyForce")
	floatForce.Name = "FloatForce"
	floatForce.Force = Vector3.new(0, 0, 0)  -- 처음엔 힘 없음
	floatForce.Parent = barrelClone

	-- 초기 속도 적용 (던진 방향 유지)
	barrelClone.AssemblyLinearVelocity = currentVelocity * 0.3  -- 물 저항으로 속도 감소

	-- 부력 시뮬레이션
	local startTime = tick()
	local floatHeight = waterSurfaceY - 1  -- 물 위로 살짝 나오는 높이
	local dampening = 0.95  -- 출렁임 감쇠

	task.spawn(function()
		local heartbeatConnection
		heartbeatConnection = RunService.Heartbeat:Connect(function()
			if not barrelClone or not barrelClone.Parent then
				heartbeatConnection:Disconnect()
				return
			end

			local elapsed = tick() - startTime
			local pos = barrelClone.Position

			-- 물 속에 들어갔을 때 부력 적용
			if pos.Y < floatHeight then
				local depth = floatHeight - pos.Y
				local buoyancy = math.min(depth * 800, 2000)  -- 깊이에 비례한 부력
				floatForce.Force = Vector3.new(0, buoyancy, 0)

				-- 수평 속도 감쇠 (물 저항)
				local vel = barrelClone.AssemblyLinearVelocity
				barrelClone.AssemblyLinearVelocity = Vector3.new(vel.X * dampening, vel.Y, vel.Z * dampening)
			else
				-- 물 위로 나오면 중력만 적용
				floatForce.Force = Vector3.new(0, 0, 0)
			end

			-- 회전 감쇠 (물에서 안정화)
			local angVel = barrelClone.AssemblyAngularVelocity
			barrelClone.AssemblyAngularVelocity = angVel * 0.98

			-- 5초 후 서서히 가라앉기 시작
			if elapsed > 5 then
				heartbeatConnection:Disconnect()
				floatForce:Destroy()

				-- 서서히 가라앉으면서 사라지기
				task.spawn(function()
					for i = 1, 20 do
						if not barrelClone or not barrelClone.Parent then break end
						barrelClone.Transparency = i / 20
						barrelClone.Position = barrelClone.Position - Vector3.new(0, 0.1, 0)
						task.wait(0.1)
					end
					if barrelClone and barrelClone.Parent then
						barrelClone:Destroy()
					end
				end)
			end
		end)
	end)
end

return BaseBarrel
