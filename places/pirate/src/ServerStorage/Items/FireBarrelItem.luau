--[[
	FireBarrelItem: 화염통 아이템
	ToolItem을 상속하여 구현
]]

local ToolItem = require(script.Parent.ToolItem)

local FireBarrelItem = setmetatable({}, ToolItem)
FireBarrelItem.__index = FireBarrelItem

function FireBarrelItem.new()
	local self = ToolItem.new("FireBarrel")
	setmetatable(self, FireBarrelItem)
	return self
end

function FireBarrelItem:Activate(_player)
	-- FireBarrel 활성화 로직
end

function FireBarrelItem:Equip(_player)
	-- 화염통 장착 시 커스텀 로직
end

function FireBarrelItem:Unequip(_player)
	-- 화염통 해제 시 커스텀 로직
end

return FireBarrelItem
