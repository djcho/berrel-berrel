--[[
	FireBarrel: 화염통
	기름이나 독에 불을 붙여 강력한 데미지를 줍니다.
]]

local ServerStorage = game:GetService("ServerStorage")

local BaseBarrel = require(script.Parent.BaseBarrel)
local ItemDb = require(ServerStorage.Items.Database.ItemDb)

local FireBarrel = setmetatable({}, BaseBarrel)
FireBarrel.__index = FireBarrel

function FireBarrel.new(player, toolInfo, level)
	local self = BaseBarrel.new(player, toolInfo, level)
	setmetatable(self, FireBarrel)

	-- ItemDb에서 불 전용 설정 가져오기
	local itemConfig = ItemDb.Tool["FireBarrel"]
	self.FireDuration = itemConfig.FireDuration or 10
	self.ToxicFireDuration = itemConfig.ToxicFireDuration or 12

	return self
end

function FireBarrel:OnTouched(hitPart)
	self:DealDamageToTarget(hitPart, self.HitDamage)
end

function FireBarrel:Throw(targetPosition)
	BaseBarrel.Throw(self, targetPosition)
end

function FireBarrel:Explode(hitPart, hitPosition)
	if BaseBarrel.Explode(self, hitPart, hitPosition) == false then
		return
	end

	local explosionOrigin = self.BarrelPart.Position
	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Exclude
	overlapParams.FilterDescendantsInstances = {self.Player.Character}
	local partsInRadius = workspace:GetPartBoundsInRadius(explosionOrigin, self.ExplosionRadius, overlapParams)

	local processedModels = {}

	for _, part in partsInRadius do
		if part.Name ~= "Baseplate" and part.Parent and not processedModels[part.Parent] then
			-- 독 웅덩이에 불을 붙이면 독성 화염 (ToxicFireSpread) 사용
			if part.Parent.Name:match("Poison") then
				processedModels[part.Parent] = true
				for _, poisonPart in part.Parent:GetChildren() do
					if poisonPart:IsA("BasePart") and not poisonPart:FindFirstChild("ToxicFireSpread") and not poisonPart:FindFirstChild("FireSpread") then
						local toxicFireScript = ServerStorage.Scripts.ToxicFireSpread:Clone()
						toxicFireScript:SetAttribute("FireStarter", self.Player.Name)
						toxicFireScript.Parent = poisonPart
					end
				end

				local modelDestroyer = part.Parent:FindFirstChild("ModelDestroyer")
				if modelDestroyer and modelDestroyer.Configuration and modelDestroyer.Configuration.WaitTime then
					modelDestroyer.Configuration.WaitTime.Value = self.ToxicFireDuration
				end
			-- 기름 웅덩이는 기존 FireSpread 사용
			elseif part.Parent.Name:match("Oil") then
				processedModels[part.Parent] = true
				local isToxicOil = part.Parent.Name:match("Toxic")

				for _, oilPart in part.Parent:GetChildren() do
					if oilPart:IsA("BasePart") and not oilPart:FindFirstChild("FireSpread") and not oilPart:FindFirstChild("ToxicFireSpread") then
						local fireScript
						if isToxicOil then
							fireScript = ServerStorage.Scripts.ToxicFireSpread:Clone()
						else
							fireScript = ServerStorage.Scripts.FireSpread:Clone()
						end
						fireScript:SetAttribute("FireStarter", self.Player.Name)
						fireScript.Parent = oilPart
					end
				end

				local modelDestroyer = part.Parent:FindFirstChild("ModelDestroyer")
				if modelDestroyer and modelDestroyer.Configuration and modelDestroyer.Configuration.WaitTime then
					modelDestroyer.Configuration.WaitTime.Value = isToxicOil and self.ToxicFireDuration or self.FireDuration
				end
			end
		end
	end
end

return FireBarrel
