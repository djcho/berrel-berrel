--[[
	OilBarrelItem: 기름통 아이템
	ToolItem을 상속하여 구현
]]

local ToolItem = require(script.Parent.ToolItem)

local OilBarrelItem = setmetatable({}, ToolItem)
OilBarrelItem.__index = OilBarrelItem

function OilBarrelItem.new()
	local self = ToolItem.new("OilBarrel")
	setmetatable(self, OilBarrelItem)
	return self
end

function OilBarrelItem:Activate(_player)
	-- OilBarrel 활성화 로직
end

function OilBarrelItem:Equip(_player)
	-- 기름통 장착 시 커스텀 로직
end

function OilBarrelItem:Unequip(_player)
	-- 기름통 해제 시 커스텀 로직
end

return OilBarrelItem
