--[[
	PoisonBarrelItem: 독구름통 아이템
	ToolItem을 상속하여 구현
]]

local ToolItem = require(script.Parent.ToolItem)

local PoisonBarrelItem = setmetatable({}, ToolItem)
PoisonBarrelItem.__index = PoisonBarrelItem

function PoisonBarrelItem.new()
	local self = ToolItem.new("PoisonBarrel")
	setmetatable(self, PoisonBarrelItem)
	return self
end

function PoisonBarrelItem:Activate(_player)
	-- PoisonBarrel 활성화 로직
end

function PoisonBarrelItem:Equip(_player)
	-- 독구름통 장착 시 커스텀 로직
end

function PoisonBarrelItem:Unequip(_player)
	-- 독구름통 해제 시 커스텀 로직
end

return PoisonBarrelItem
