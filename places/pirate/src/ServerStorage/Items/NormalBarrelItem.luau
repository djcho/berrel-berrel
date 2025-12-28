--[[
	NormalBarrelItem: 기본통 아이템
	ToolItem을 상속하여 구현
]]

local ToolItem = require(script.Parent.ToolItem)

local NormalBarrelItem = setmetatable({}, ToolItem)
NormalBarrelItem.__index = NormalBarrelItem

function NormalBarrelItem.new()
	local self = ToolItem.new("NormalBarrel")
	setmetatable(self, NormalBarrelItem)
	return self
end

function NormalBarrelItem:Activate(_player)
	-- NormalBarrel 활성화 로직
end

function NormalBarrelItem:Equip(_player)
	-- 기본통 장착 시 커스텀 로직
end

function NormalBarrelItem:Unequip(_player)
	-- 기본통 해제 시 커스텀 로직
end

return NormalBarrelItem
