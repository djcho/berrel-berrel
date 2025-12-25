local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local EnumData = require(ReplicatedStorage.Classes.EnumData)
local OilBarrelItem = require(ServerStorage.Scripts.Items.OilBarrelItem)
local FireBarrelItem = require(ServerStorage.Scripts.Items.FireBarrelItem)

local ItemDescriptor = {
	ItemList = {
		OilBarrel = OilBarrelItem.new(),
		FireBarrel = FireBarrelItem.new(),
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
