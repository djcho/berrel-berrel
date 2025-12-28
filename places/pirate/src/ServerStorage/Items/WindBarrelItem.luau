--[[
	WindBarrelItem: 바람통 아이템
	ToolItem을 상속하여 구현
]]

local ToolItem = require(script.Parent.ToolItem)

local WindBarrelItem = setmetatable({}, ToolItem)
WindBarrelItem.__index = WindBarrelItem

function WindBarrelItem.new()
	local self = ToolItem.new("WindBarrel")
	setmetatable(self, WindBarrelItem)
	return self
end

function WindBarrelItem:Activate(_player)
	-- WindBarrel 활성화 로직
end

function WindBarrelItem:Equip(_player)
	-- 바람통 장착 시 커스텀 로직
end

function WindBarrelItem:Unequip(_player)
	-- 바람통 해제 시 커스텀 로직
end

return WindBarrelItem
