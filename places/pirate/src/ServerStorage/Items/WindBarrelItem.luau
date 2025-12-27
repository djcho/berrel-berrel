local BaseItem = require(script.Parent.BaseItem)
local Equipable = require(script.Parent.Equipable)

local ItemDbTools = require(script.Parent.Database.ItemDb).Tool
local ItemInfo = ItemDbTools["WindBarrel"]

local WindBarrelItem = setmetatable({}, BaseItem)
WindBarrelItem.__index = WindBarrelItem

-- Inherit Equipable interface
for k, v in pairs(Equipable) do
	if WindBarrelItem[k] == nil then
		WindBarrelItem[k] = v
	end
end

function WindBarrelItem.new()
	local self = setmetatable(BaseItem.new(ItemInfo.Id, ItemInfo.Category, ItemInfo.Name, ItemInfo.DisplayName, ItemInfo.IconId, ItemInfo.MaxStack), WindBarrelItem)

	self.Price = ItemInfo.Price
	self.Damage = ItemInfo.Damage
	self.DotDamage = ItemInfo.DotDamage
	self.Cooldown = ItemInfo.Cooldown
	self.ThrowType = ItemInfo.ThrowType
	self.MaxRange = ItemInfo.MaxRange
	self.ChargingSpeed = ItemInfo.ChargingSpeed
	self.ExplosionRadius = ItemInfo.ExplosionRadius
	self.KnockbackForce = ItemInfo.KnockbackForce
	self.MaxShots = ItemInfo.MaxShots
	self.ReloadTime = ItemInfo.ReloadTime
	self.Model = ItemInfo.Model

	return self
end

function WindBarrelItem:Activate(player)
	print("WindBarrelItem Activate")
end

-- Implement Equipable interface methods
function WindBarrelItem:Equip(player)
	print(player.Name .. " equipped the WindBarrel")
end

function WindBarrelItem:Unequip(player)
	print(player.Name .. " unequipped the WindBarrel")
end

return WindBarrelItem
