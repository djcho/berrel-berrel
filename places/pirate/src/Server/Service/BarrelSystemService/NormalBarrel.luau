--[[
	NormalBarrel: 기본통
	가장 기본적인 배럴로, 폭발 시 데미지만 줍니다.
	독과 조합 시 즉발 폭발 효과!
]]

local ServerStorage = game:GetService("ServerStorage")
local TweenService = game:GetService("TweenService")

local BaseBarrel = require(script.Parent.BaseBarrel)
local CommonUtil = require(ServerStorage.Scripts.CommonUtil)

local NormalBarrel = setmetatable({}, BaseBarrel)
NormalBarrel.__index = NormalBarrel

function NormalBarrel.new(player, toolInfo, level)
	local self = BaseBarrel.new(player, toolInfo, level)
	setmetatable(self, NormalBarrel)
	return self
end

function NormalBarrel:OnTouched(hitPart)
	self:DealDamageToTarget(hitPart, self.HitDamage)
end

function NormalBarrel:Throw(targetPosition)
	BaseBarrel.Throw(self, targetPosition)
end

-- 독 구름 확인
function NormalBarrel:CheckPoisonCombo(hitPosition)
	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Exclude
	overlapParams.FilterDescendantsInstances = {self.Player.Character}

	local partsInRadius = workspace:GetPartBoundsInRadius(hitPosition, 10, overlapParams)

	for _, part in partsInRadius do
		if part.Parent and part.Parent.Name:match("Poison") then
			return part.Parent
		end
	end
	return nil
end

-- 독 즉발 폭발 효과 (기본통 + 독)
function NormalBarrel:ExplodePoison(poisonModel, explosionOrigin)
	-- 독 구름 즉시 폭발 - 범위 내 모든 적에게 즉시 독 데미지
	local explosionRadius = 15
	local instantDamage = 25

	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Exclude
	overlapParams.FilterDescendantsInstances = {self.Player.Character}

	local partsInRadius = workspace:GetPartBoundsInRadius(explosionOrigin, explosionRadius, overlapParams)
	local processedCharacters = {}

	for _, part in partsInRadius do
		local character = part.Parent
		local humanoid = character and character:FindFirstChild("Humanoid")

		if humanoid and not processedCharacters[character] then
			processedCharacters[character] = true

			local targetPlayer = game.Players:GetPlayerFromCharacter(character)
			local isSameTeam = CommonUtil:IsSameTeam(self.Player, targetPlayer)

			if not isSameTeam then
				self:SetCreatorTag(humanoid)
				humanoid:TakeDamage(instantDamage)
			end
		end
	end

	-- 독 구름 크기 증가 후 빠르게 소멸
	for _, part in poisonModel:GetChildren() do
		if part:IsA("BasePart") then
			local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			local newSize = part.Size * 2
			local tween = TweenService:Create(part, tweenInfo, {Size = newSize, Transparency = 0.8})
			tween:Play()
		end
	end

	-- 폭발 이펙트
	local effectFolder = ServerStorage:FindFirstChild("Effect")
	if effectFolder then
		local poisonEffect = effectFolder:FindFirstChild("SplashPoison")
		if poisonEffect then
			local effectPart = Instance.new("Part")
			effectPart.Size = Vector3.new(1, 1, 1)
			effectPart.Position = explosionOrigin
			effectPart.Anchored = true
			effectPart.CanCollide = false
			effectPart.Transparency = 1
			effectPart.Parent = workspace

			local effect = poisonEffect:Clone()
			effect.Parent = effectPart
			if effect:IsA("ParticleEmitter") then
				effect:Emit(40)
			end

			game.Debris:AddItem(effectPart, 2)
		end
	end

	-- 독 구름 빠르게 제거
	local modelDestroyer = poisonModel:FindFirstChild("ModelDestroyer")
	if modelDestroyer and modelDestroyer.Configuration and modelDestroyer.Configuration.WaitTime then
		modelDestroyer.Configuration.WaitTime.Value = 2  -- 2초 후 소멸
	end
end

function NormalBarrel:Explode(hitPart, hitPosition)
	if BaseBarrel.Explode(self, hitPart, hitPosition) == false then
		return
	end

	local explosionOrigin = self.BarrelPart.Position

	-- 독 조합 체크
	local poisonModel = self:CheckPoisonCombo(explosionOrigin)
	if poisonModel then
		-- 기본통 + 독 = 독 즉발 폭발
		self:ExplodePoison(poisonModel, explosionOrigin)
	end
end

return NormalBarrel
