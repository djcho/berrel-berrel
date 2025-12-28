--[[
	OilBarrel: 기름통
	바닥에 기름을 뿌려 적의 이동속도를 늦춥니다.
]]

local ServerStorage = game:GetService("ServerStorage")
local TweenService = game:GetService("TweenService")

local BaseBarrel = require(script.Parent.BaseBarrel)
local ItemDb = require(ServerStorage.Items.Database.ItemDb)

local OilBarrel = setmetatable({}, BaseBarrel)
OilBarrel.__index = OilBarrel

function OilBarrel.new(player, toolInfo, level)
	local self = BaseBarrel.new(player, toolInfo, level)
	setmetatable(self, OilBarrel)

	-- ItemDb에서 기름 전용 설정 가져오기
	local itemConfig = ItemDb.Tool["OilBarrel"]
	self.OilModels = itemConfig.OilModels or {"Oil1", "Oil2", "Oil3"}
	self.OilDuration = itemConfig.OilDuration or 15

	return self
end

function OilBarrel:OnTouched(hitPart)
	self:DealDamageToTarget(hitPart, self.HitDamage)
end

function OilBarrel:Throw(targetPosition)
	BaseBarrel.Throw(self, targetPosition)
end

function OilBarrel:Explode(hitPart, hitPosition)
	if BaseBarrel.Explode(self, hitPart, hitPosition) == false then
		return
	end

	local oilModel = self:ChooseRandomOilModel()
	local modelClone = self:CloneAndPositionModel(oilModel, hitPosition)
	self:AttachScriptsToModel(modelClone)
	self:AnimateOilSpread(modelClone)
end

function OilBarrel:ChooseRandomOilModel()
	local randomIndex = math.random(1, #self.OilModels)
	local modelName = self.OilModels[randomIndex]
	return ServerStorage.Models:FindFirstChild(modelName)
end

function OilBarrel:CloneAndPositionModel(oilModel, hitPosition)
	local modelClone = oilModel:Clone()
	modelClone.Parent = workspace
	modelClone:SetPrimaryPartCFrame(CFrame.new(hitPosition) * CFrame.Angles(0, math.rad(math.random(0, 180)), 0))
	return modelClone
end

function OilBarrel:AttachScriptsToModel(modelClone)
	local modelDestroyer = ServerStorage.Scripts.ModelDestroyer:Clone()

	local configuration = Instance.new("Configuration")
	configuration.Name = "Configuration"
	configuration.Parent = modelDestroyer

	local waitTime = Instance.new("IntValue")
	waitTime.Name = "WaitTime"
	waitTime.Value = self.OilDuration
	waitTime.Parent = configuration

	modelDestroyer.Parent = modelClone

	local slower = ServerStorage.Scripts.Slower:Clone()
	slower.Parent = modelClone

	for _, part in pairs(modelClone:GetChildren()) do
		if part.Name:match("Oil") then
			part:SetAttribute("OriginalSize", part.Size)
			part.Size = Vector3.new(0, part.Size.Y, 0)
		end
	end
end

function OilBarrel:AnimateOilSpread(modelClone)
	for _, part in pairs(modelClone:GetChildren()) do
		if part:IsA("BasePart") then
			local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
			local originalSize = part:GetAttribute("OriginalSize")
			local goal = {Size = originalSize}
			local tween = TweenService:Create(part, tweenInfo, goal)
			tween:Play()
		end
	end
end

return OilBarrel
