local ReplicatedStorage = game:GetService("ReplicatedStorage")

local tool = script.Parent
local RequestToolInfo = ReplicatedStorage:WaitForChild("BarrelSystem"):WaitForChild("RequestToolInfo")
local SimpleThrowType = require(ReplicatedStorage:WaitForChild("Classes"):WaitForChild("ThrowType"):WaitForChild("SimpleThrowType"))
local ChargingThrowType = require(ReplicatedStorage:WaitForChild("Classes"):WaitForChild("ThrowType"):WaitForChild("ChargingThrowType"))

local toolInfo = RequestToolInfo:InvokeServer(tool.Name)
if not toolInfo then
	error("Unknown tool type: " .. tool.Name)
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
