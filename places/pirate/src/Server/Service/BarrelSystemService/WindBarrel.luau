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
	-- TODO: Studio에서 WindBarrel 파트 생성 후 변경
	local windBarrelPart = ServerStorage.Parts:FindFirstChild("WindBarrel") or ServerStorage.Parts.NormalBarrel
	local self = BaseBarrel.new(player, windBarrelPart, level)
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

-- 바닥 높이를 찾는 함수
function WindBarrel:FindGroundHeight(position, model)
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = {model}

	-- 위에서 아래로 레이캐스트
	local rayOrigin = Vector3.new(position.X, position.Y + 50, position.Z)
	local rayDirection = Vector3.new(0, -100, 0)

	local result = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
	if result then
		return result.Position.Y
	end
	return position.Y  -- 바닥을 못 찾으면 현재 높이 유지
end

-- 모델을 바람 방향으로 밀어내는 함수
function WindBarrel:PushModel(model, explosionOrigin, distance)
	local primaryPart = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
	if not primaryPart then return end

	-- 밀어낼 방향 계산
	local direction = (primaryPart.Position - explosionOrigin).Unit
	direction = Vector3.new(direction.X, 0, direction.Z).Unit

	local targetPosition = primaryPart.Position + direction * distance

	-- 목표 위치의 바닥 높이 찾기
	local groundY = self:FindGroundHeight(targetPosition, model)

	-- 파트들의 최저 높이 계산 (바닥에 붙이기 위해)
	local lowestY = math.huge
	for _, part in model:GetChildren() do
		if part:IsA("BasePart") then
			local bottomY = part.Position.Y - part.Size.Y / 2
			if bottomY < lowestY then
				lowestY = bottomY
			end
		end
	end

	-- 바닥에 맞춰 높이 조정
	local heightAdjustment = groundY - lowestY + 0.1  -- 0.1은 바닥 위에 살짝 띄움
	targetPosition = Vector3.new(targetPosition.X, primaryPart.Position.Y + heightAdjustment, targetPosition.Z)

	-- 부드럽게 이동
	local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

	local lastTween = nil
	for _, part in model:GetChildren() do
		if part:IsA("BasePart") then
			local offset = part.Position - primaryPart.Position
			local targetPos = targetPosition + offset
			local tween = TweenService:Create(part, tweenInfo, {Position = targetPos})
			tween:Play()
			lastTween = tween
		end
	end

	-- Tween 완료 후 Slower/PoisonDamage 스크립트 재시작 (영역 재계산)
	if lastTween then
		lastTween.Completed:Connect(function()
			self:RefreshZoneScripts(model)
		end)
	end
end

-- Slower, PoisonDamage 스크립트를 재시작하여 영역 재계산
function WindBarrel:RefreshZoneScripts(model)
	-- 기존 스크립트들의 cleanup을 위해 BindableEvent 호출
	local bindableEvent = model:FindFirstChild("OnPartRemoving")
	if bindableEvent then
		bindableEvent:Fire()  -- cleanup 트리거 (속도 복구 등)
	end

	-- 잠시 대기 후 새 스크립트 생성 (cleanup 완료 대기)
	task.wait(0.1)

	-- 새 BindableEvent 생성 (기존 것은 cleanup에서 사용됨)
	local newBindableEvent = Instance.new("BindableEvent")
	newBindableEvent.Name = "OnPartRemoving"
	newBindableEvent.Parent = model

	-- Slower 스크립트 재시작
	local slower = model:FindFirstChild("Slower")
	if slower then
		slower:Destroy()
		local newSlower = ServerStorage.Scripts.Slower:Clone()
		newSlower.Parent = model
	end

	-- PoisonDamage 스크립트 재시작
	local poisonDamage = model:FindFirstChild("PoisonDamage")
	if poisonDamage then
		local ownerName = poisonDamage:GetAttribute("PoisonOwner")
		local damageMultiplier = poisonDamage:GetAttribute("DamageMultiplier")
		poisonDamage:Destroy()
		local newPoisonDamage = ServerStorage.Scripts.PoisonDamage:Clone()
		if ownerName then
			newPoisonDamage:SetAttribute("PoisonOwner", ownerName)
		end
		if damageMultiplier then
			newPoisonDamage:SetAttribute("DamageMultiplier", damageMultiplier)
		end
		newPoisonDamage.Parent = model
	end

	-- ToxicSlimeDamage 스크립트도 재시작
	local toxicDamage = model:FindFirstChild("ToxicSlimeDamage")
	if toxicDamage then
		local ownerName = toxicDamage:GetAttribute("PoisonOwner")
		local damageMultiplier = toxicDamage:GetAttribute("DamageMultiplier")
		toxicDamage:Destroy()
		local newToxicDamage = ServerStorage.Scripts.PoisonDamage:Clone()
		newToxicDamage.Name = "ToxicSlimeDamage"
		if ownerName then
			newToxicDamage:SetAttribute("PoisonOwner", ownerName)
		end
		if damageMultiplier then
			newToxicDamage:SetAttribute("DamageMultiplier", damageMultiplier)
		end
		newToxicDamage.Parent = model
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
