--[[
	PoisonBarrel: 독구름통
	독 구름을 생성하여 지속 피해를 줍니다. 기름과 조합하면 독성 슬라임!
]]

local ServerStorage = game:GetService("ServerStorage")

local BaseBarrel = require(script.Parent.BaseBarrel)
local ItemDb = require(ServerStorage.Items.Database.ItemDb)

local PoisonBarrel = setmetatable({}, BaseBarrel)
PoisonBarrel.__index = PoisonBarrel

function PoisonBarrel.new(player, toolInfo, level)
	local self = BaseBarrel.new(player, toolInfo, level)
	setmetatable(self, PoisonBarrel)

	-- ItemDb에서 독 전용 설정 가져오기
	local itemConfig = ItemDb.Tool["PoisonBarrel"]
	self.PoisonModel = itemConfig.PoisonModel or "PoisonFog"
	self.PoisonDuration = itemConfig.PoisonDuration or 15
	self.ToxicSlimeDuration = itemConfig.ToxicSlimeDuration or 20
	self.ToxicSlimeDamageMultiplier = itemConfig.ToxicSlimeDamageMultiplier or 1.5

	return self
end

function PoisonBarrel:OnTouched(hitPart)
	self:DealDamageToTarget(hitPart, self.HitDamage)
end

function PoisonBarrel:Throw(targetPosition)
	BaseBarrel.Throw(self, targetPosition)
end

-- 기름 웅덩이 위에 떨어졌는지 확인
function PoisonBarrel:CheckOilCombo(hitPosition)
	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Exclude
	overlapParams.FilterDescendantsInstances = {self.Player.Character}

	local partsInRadius = workspace:GetPartBoundsInRadius(hitPosition, 10, overlapParams)

	for _, part in partsInRadius do
		if part.Parent and part.Parent.Name:match("Oil") then
			return part.Parent
		end
	end
	return nil
end

-- 기름을 독성 슬라임으로 변환
function PoisonBarrel:ConvertOilToToxicSlime(oilModel)
	oilModel.Name = "ToxicOil"

	for _, part in oilModel:GetChildren() do
		if part:IsA("BasePart") then
			part.Color = Color3.fromRGB(128, 0, 128)
			part.Material = Enum.Material.Neon
		end
	end

	local existingBindable = oilModel:FindFirstChild("OnPartRemoving")
	if not existingBindable then
		local bindableEvent = Instance.new("BindableEvent")
		bindableEvent.Name = "OnPartRemoving"
		bindableEvent.Parent = oilModel
	end

	local existingPoisonDamage = oilModel:FindFirstChild("ToxicSlimeDamage")
	if not existingPoisonDamage then
		local toxicSlimeDamage = ServerStorage.Scripts.PoisonDamage:Clone()
		toxicSlimeDamage.Name = "ToxicSlimeDamage"
		toxicSlimeDamage:SetAttribute("PoisonOwner", self.Player.Name)
		toxicSlimeDamage:SetAttribute("DamageMultiplier", self.ToxicSlimeDamageMultiplier)
		toxicSlimeDamage.Parent = oilModel
	end

	local modelDestroyer = oilModel:FindFirstChild("ModelDestroyer")
	if modelDestroyer and modelDestroyer.Configuration and modelDestroyer.Configuration.WaitTime then
		modelDestroyer.Configuration.WaitTime.Value = self.ToxicSlimeDuration
	end
end

function PoisonBarrel:Explode(hitPart, hitPosition)
	if BaseBarrel.Explode(self, hitPart, hitPosition) == false then
		return
	end

	-- 기름 위에 떨어졌는지 확인
	local oilModel = self:CheckOilCombo(hitPosition)
	if oilModel then
		-- 기름 + 가스 = 독성 슬라임!
		self:ConvertOilToToxicSlime(oilModel)
		return
	end

	local poisonModel = ServerStorage.Models:FindFirstChild(self.PoisonModel)
	if poisonModel then
		local modelClone = self:CloneAndPositionModel(poisonModel, hitPosition)
		self:AttachScriptsToModel(modelClone)
	end
end

function PoisonBarrel:CloneAndPositionModel(poisonModel, hitPosition)
	local modelClone = poisonModel:Clone()
	modelClone.Parent = workspace
	modelClone:SetPrimaryPartCFrame(CFrame.new(hitPosition) * CFrame.Angles(0, math.rad(math.random(0, 180)), 0))
	return modelClone
end

function PoisonBarrel:AttachScriptsToModel(modelClone)
	local bindableEvent = Instance.new("BindableEvent")
	bindableEvent.Name = "OnPartRemoving"
	bindableEvent.Parent = modelClone

	local modelDestroyer = ServerStorage.Scripts.ModelDestroyer:Clone()

	local configuration = Instance.new("Configuration")
	configuration.Name = "Configuration"
	configuration.Parent = modelDestroyer

	local waitTime = Instance.new("IntValue")
	waitTime.Name = "WaitTime"
	waitTime.Value = self.PoisonDuration
	waitTime.Parent = configuration

	modelDestroyer.Parent = modelClone

	local slower = ServerStorage.Scripts.Slower:Clone()
	slower.Parent = modelClone

	local poisonDamage = ServerStorage.Scripts.PoisonDamage:Clone()
	poisonDamage:SetAttribute("PoisonOwner", self.Player.Name)
	poisonDamage.Parent = modelClone
end

return PoisonBarrel
