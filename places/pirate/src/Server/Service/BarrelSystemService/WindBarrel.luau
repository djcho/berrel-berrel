-- 서비스 로드
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- 모듈 로드
local BaseBarrel = require(script.Parent.BaseBarrel)

-- WindBarrel 클래스 정의
local WindBarrel = setmetatable({}, BaseBarrel)
WindBarrel.__index = WindBarrel

-- 바람 효과 설정
local KNOCKBACK_FORCE = 80  -- 넉백 힘
local KNOCKBACK_RADIUS = 15  -- 넉백 범위
local WIND_SPREAD_RADIUS = 20  -- 가스/기름 확산 범위

-- 새로운 WindBarrel 객체 생성 함수
function WindBarrel.new(player, level, toolInfo)
	local self = BaseBarrel.new(player, ServerStorage.Parts.WindBarrel, level)
	setmetatable(self, WindBarrel)
	self.HitDamage = toolInfo.Damage
	self.MaxRange = toolInfo.MaxRange
	self.Name = toolInfo.Name
	self.ExplosionRadius = toolInfo.ExplosionRadius or KNOCKBACK_RADIUS
	self.KnockbackForce = toolInfo.KnockbackForce or KNOCKBACK_FORCE
	return self
end

-- 배럴이 다른 객체와 충돌했을 때 호출되는 함수
function WindBarrel:OnTouched(hitPart)
	self:DealDamageToTarget(hitPart, self.HitDamage)
end

-- 배럴을 목표 위치로 던지는 함수
function WindBarrel:Throw(targetPosition)
	BaseBarrel.Throw(self, targetPosition, self.MaxRange)
end

-- 넉백 적용 함수
function WindBarrel:ApplyKnockback(character, explosionOrigin)
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChild("Humanoid")

	if not humanoidRootPart or not humanoid or humanoid.Health <= 0 then
		return
	end

	-- 넉백 방향 계산 (폭발 중심에서 캐릭터로)
	local direction = (humanoidRootPart.Position - explosionOrigin).Unit
	direction = Vector3.new(direction.X, 0.3, direction.Z).Unit  -- 약간 위로

	-- BodyVelocity로 넉백 적용
	local bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
	bodyVelocity.Velocity = direction * self.KnockbackForce
	bodyVelocity.Parent = humanoidRootPart

	-- 0.3초 후 제거
	game.Debris:AddItem(bodyVelocity, 0.3)
end

-- 가스/기름 확산 효과 (바람으로 밀어냄)
function WindBarrel:SpreadPoolsWithWind(explosionOrigin)
	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Exclude
	overlapParams.FilterDescendantsInstances = {self.Player.Character}

	local partsInRadius = workspace:GetPartBoundsInRadius(explosionOrigin, WIND_SPREAD_RADIUS, overlapParams)
	local processedModels = {}

	for _, part in partsInRadius do
		if part.Parent and not processedModels[part.Parent] then
			local parentName = part.Parent.Name

			-- 가스 구름 확산
			if parentName:match("Poison") then
				processedModels[part.Parent] = true
				self:PushModel(part.Parent, explosionOrigin, 25)  -- 가스는 가볍게 많이 밀림

				-- 가스 범위 확대 효과
				for _, poisonPart in part.Parent:GetChildren() do
					if poisonPart:IsA("BasePart") then
						-- PoisonFog는 OriginalSize가 없으므로 현재 Size 사용
						local currentSize = poisonPart.Size
						local newSize = currentSize * 1.3  -- 30% 확대
						local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Sine)
						local tween = TweenService:Create(poisonPart, tweenInfo, {Size = newSize})
						tween:Play()
					end
				end

				-- 불이 붙어있으면 WindBoosted 설정
				for _, child in part.Parent:GetDescendants() do
					if child.Name == "ToxicFireSpread" or child.Name == "FireSpread" then
						child:SetAttribute("WindBoosted", true)
					end
				end

			-- 기름 웅덩이 밀어내기
			elseif parentName:match("Oil") then
				processedModels[part.Parent] = true
				self:PushModel(part.Parent, explosionOrigin, 15)  -- 기름은 무거워서 덜 밀림

				-- 불이 붙어있으면 WindBoosted 설정
				for _, child in part.Parent:GetDescendants() do
					if child.Name == "FireSpread" then
						child:SetAttribute("WindBoosted", true)
					end
				end
			end
		end
	end
end

-- 모델을 바람 방향으로 밀어내는 함수
function WindBarrel:PushModel(model, explosionOrigin, distance)
	local primaryPart = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
	if not primaryPart then return end

	-- 밀어낼 방향 계산
	local direction = (primaryPart.Position - explosionOrigin).Unit
	direction = Vector3.new(direction.X, 0, direction.Z).Unit

	local targetPosition = primaryPart.Position + direction * distance

	-- 부드럽게 이동
	local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

	for _, part in model:GetChildren() do
		if part:IsA("BasePart") then
			local offset = part.Position - primaryPart.Position
			local targetPos = targetPosition + offset
			local tween = TweenService:Create(part, tweenInfo, {Position = targetPos})
			tween:Play()
		end
	end
end

-- 배럴이 폭발할 때 호출되는 함수
function WindBarrel:Explode(hitPart, hitPosition)
	if BaseBarrel.Explode(self, hitPart, hitPosition) == false then
		return
	end

	local explosionOrigin = self.BarrelPart.Position
	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Exclude
	overlapParams.FilterDescendantsInstances = {self.Player.Character}
	local partsInRadius = workspace:GetPartBoundsInRadius(explosionOrigin, self.ExplosionRadius, overlapParams)

	-- 범위 내 캐릭터에 넉백 적용
	local processedCharacters = {}
	for _, part in partsInRadius do
		local character = part.Parent
		local humanoid = character and character:FindFirstChild("Humanoid")

		if humanoid and not processedCharacters[character] then
			processedCharacters[character] = true

			-- 팀킬 방지
			local targetPlayer = game.Players:GetPlayerFromCharacter(character)
			if targetPlayer and targetPlayer ~= self.Player then
				if not (self.Player.Team and targetPlayer.Team and self.Player.Team == targetPlayer.Team) then
					self:ApplyKnockback(character, explosionOrigin)
					self:DealDamageToTarget(part, self.HitDamage)
				end
			elseif not targetPlayer then
				-- NPC인 경우
				self:ApplyKnockback(character, explosionOrigin)
				self:DealDamageToTarget(part, self.HitDamage)
			end
		end
	end

	-- 가스/기름/불 확산 효과
	self:SpreadPoolsWithWind(explosionOrigin)

	-- 폭발 사운드 재생
	local remoteEvent = ReplicatedStorage:WaitForChild("PlaySoundEvent")
	remoteEvent:FireAllClients("WindBarrelExplode", 0, 1.5)

	-- 바람 이펙트
	local effect = ServerStorage.Effect.BrokenWood:Clone()
	effect.Parent = workspace
	effect.Position = self.BarrelPart.Position

	-- 바람 파티클 효과 (있다면)
	local windEffect = ServerStorage.Effect:FindFirstChild("WindBurst")
	if windEffect then
		local effect2 = windEffect:Clone()
		effect2.Parent = workspace
		effect2.Position = self.BarrelPart.Position
		game.Debris:AddItem(effect2, 1)
	end

	game.Debris:AddItem(effect, 0.5)
end

return WindBarrel
