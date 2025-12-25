local BaseItem = require(script.Parent.BaseItem)
local Equipable = require(script.Parent.Equipable)

local ItemDbTools = require(script.Parent.Database.ItemDb).Tool
local ItemInfo = ItemDbTools["FireBarrel"]

local FireBarrelItem = {}
FireBarrelItem.__index = FireBarrelItem
setmetatable(FireBarrelItem, BaseItem)

-- Inherit Equipable interface
for k, v in pairs(Equipable) do
	if FireBarrelItem[k] == nil then
		FireBarrelItem[k] = v
	end
end

function FireBarrelItem.new()
	local self = BaseItem.new(ItemInfo.Id, ItemInfo.Category, ItemInfo.Name, ItemInfo.DisplayName, ItemInfo.IconId, ItemInfo.MaxStack)

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

	setmetatable(self, FireBarrelItem)
	return self
end

function FireBarrelItem:Activate(player)
end

function FireBarrelItem:Merge(player)
	BaseItem:Merge(player)
end

-- Implement Equipable interface methods
function FireBarrelItem:Equip(player)
	print(player.Name .. " equipped the FireBarrel")
	-- Add custom logic for equipping the item
end

function FireBarrelItem:Unequip(player)
	print(player.Name .. " unequipped the FireBarrel")
	-- Add custom logic for unequipping the item
end

return FireBarrelItem
