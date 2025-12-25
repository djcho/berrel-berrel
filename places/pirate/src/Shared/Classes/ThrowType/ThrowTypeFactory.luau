-- ThrowTypeFactory (ModuleScript)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SimpleThrowType = require(ReplicatedStorage:WaitForChild("Classes"):WaitForChild("ThrowType"):WaitForChild("SimpleThrowType"))
local ChargingThrowType = require(ReplicatedStorage:WaitForChild("Classes"):WaitForChild("ThrowType"):WaitForChild("ChargingThrowType"))
local BarrelInfo = require(game.ServerScriptService:WaitForChild("BarrelSystem"):WaitForChild("BarrelInfo"))

local ThrowTypeFactory = {}

function ThrowTypeFactory.createThrowType(tool)
	local toolName = tool.Name
	local barrelInfo = BarrelInfo[toolName]
	if not barrelInfo then
		error("Unknown tool type: " .. toolName)
	end

	local throwTypeClass = barrelInfo.throwType
	if throwTypeClass == "SimpleThrowType" then
		return SimpleThrowType.new(barrelInfo)
	elseif throwTypeClass == "ChargingThrowType" then
		return ChargingThrowType.new(barrelInfo)
	else
		error("Unknown throw type: " .. throwTypeClass)
	end
end

return ThrowTypeFactory
