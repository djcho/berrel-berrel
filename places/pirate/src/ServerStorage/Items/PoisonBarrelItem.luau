local BaseItem = require(script.Parent.BaseItem)
local Equipable = require(script.Parent.Equipable)

local ItemDbTools = require(script.Parent.Database.ItemDb).Tool
local ItemInfo = ItemDbTools["PoisonBarrel"]

local PoisonBarrelItem = {}
PoisonBarrelItem.__index = PoisonBarrelItem
setmetatable(PoisonBarrelItem, BaseItem)

-- Inherit Equipable interface
for k, v in pairs(Equipable) do
	if PoisonBarrelItem[k] == nil then
		PoisonBarrelItem[k] = v
	end
end

function PoisonBarrelItem.new()
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

	setmetatable(self, PoisonBarrelItem)
	return self
end


function PoisonBarrelItem:Activate(player)
end

-- Implement Equipable interface methods
function PoisonBarrelItem:Equip(player)
	print(player.Name .. " equipped the FireBarrel")
	-- Add custom logic for equipping the item
end

function PoisonBarrelItem:Unequip(player)
	print(player.Name .. " unequipped the FireBarrel")
	-- Add custom logic for unequipping the item
end

return PoisonBarrelItem
