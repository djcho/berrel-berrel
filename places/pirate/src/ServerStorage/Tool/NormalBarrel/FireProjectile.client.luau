local ReplicatedStorage = game:GetService("ReplicatedStorage")

local tool = script.Parent
local toolName = tool.Name
local RequestToolInfo = ReplicatedStorage:WaitForChild("BarrelSystem"):WaitForChild("RequestToolInfo")
local SimpleThrowType = require(ReplicatedStorage:WaitForChild("Classes"):WaitForChild("ThrowType"):WaitForChild("SimpleThrowType"))
local ChargingThrowType = require(ReplicatedStorage:WaitForChild("Classes"):WaitForChild("ThrowType"):WaitForChild("ChargingThrowType"))

local toolInfo = RequestToolInfo:InvokeServer(toolName)
if not toolInfo then
	error("Unknown tool type: " .. toolName)
end

local throwType = nil
local throwTypeClass = toolInfo.ThrowType
if throwTypeClass == "SimpleThrowType" then
	throwType = SimpleThrowType.new(toolInfo)
elseif throwTypeClass == "ChargingThrowType" then
	throwType = ChargingThrowType.new(toolInfo)
else
	error("Unknown throw type: " .. throwTypeClass)
end

throwType:initialize(tool)

-- 업그레이드 시 ToolInfo 실시간 업데이트
local shopSystem = ReplicatedStorage:WaitForChild("ShopSystem")
local toolInfoUpdateEvent = shopSystem:WaitForChild("ToolInfoUpdateEvent")
toolInfoUpdateEvent.OnClientEvent:Connect(function(barrelName, upgradedStats)
	if barrelName == toolName then
		-- 업그레이드된 스탯 적용
		throwType.ToolInfo.Damage = upgradedStats.Damage
		throwType.ToolInfo.MaxRange = upgradedStats.MaxRange
		throwType.ToolInfo.ReloadTime = upgradedStats.ReloadTime
		throwType.ToolInfo.MaxShots = upgradedStats.MaxShots
		throwType.ToolInfo.ExplosionRadius = upgradedStats.ExplosionRadius
	end
end)
