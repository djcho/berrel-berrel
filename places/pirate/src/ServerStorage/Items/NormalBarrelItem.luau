local BaseItem = require(script.Parent.BaseItem)
local Equipable = require(script.Parent.Equipable)

local ItemDbTools = require(script.Parent.Database.ItemDb).Tool
local ItemInfo = ItemDbTools["NormalBarrel"]

local NormalBarrelItem = setmetatable({}, BaseItem)
NormalBarrelItem.__index = NormalBarrelItem

-- Inherit Equipable interface
for k, v in pairs(Equipable) do
	if NormalBarrelItem[k] == nil then
		NormalBarrelItem[k] = v
	end
end

function NormalBarrelItem.new()
	local self = setmetatable(BaseItem.new(ItemInfo.Id, ItemInfo.Category, ItemInfo.Name, ItemInfo.DisplayName, ItemInfo.IconId, ItemInfo.MaxStack), NormalBarrelItem)

	self.Price = ItemInfo.Price
	self.Damage = ItemInfo.Damage
	self.DotDamage = ItemInfo.DotDamage
	self.Cooldown = ItemInfo.Cooldown	
	self.ThrowType = ItemInfo.ThrowType
	self.MaxRange = ItemInfo.MaxRange
	self.ChargingSpeed = ItemInfo.ChargingSpeed
	self.ExplosionRadius = ItemInfo.ExplosionRadius
	self.MaxShots = ItemInfo.MaxShots
	self.ReloadTime = ItemInfo.ReloadTime
	self.Model = ItemInfo.Model

	return self
end

function NormalBarrelItem:Activate(player)
	print("NormalBarrelItem Activate")
end

-- Implement Equipable interface methods
function NormalBarrelItem:Equip(player)
	print(player.Name .. " equipped the NormalBarrel")
	-- Add custom logic for equipping the item
end

function NormalBarrelItem:Unequip(player)
	print(player.Name .. " unequipped the NormalBarrel")
	-- Add custom logic for unequipping the item
end

return NormalBarrelItem
