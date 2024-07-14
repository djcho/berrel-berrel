local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local EnumData = require(ReplicatedStorage.Classes.EnumData)
local OilBarrelItem = require(ServerStorage.Classes.Items.OilBarrelItem)
local FireBarrelItem = require(ServerStorage.Classes.Items.FireBarrelItem)
local NormalBarrelUpgradeItem = require(ServerStorage.Classes.Items.NormalBarrelUpgradeItem)

local ItemDescriptor = {
	ItemList = {
		OilBarrel = OilBarrelItem.new(),
		FireBarrel = FireBarrelItem.new(),
		NormalBarrelUpgrade = NormalBarrelUpgradeItem.new(),
	}
}

function ItemDescriptor:GetItemObject(itemId)
	for _,v in pairs(self.ItemList) do
		if v.Id == itemId then
			return v
		end
	end
end

return ItemDescriptor
