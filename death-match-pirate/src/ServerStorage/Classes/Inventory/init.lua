local StarterPack = game:GetService("StarterPack")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
--local newBackPackItemAdded = ServerStorage.Event.NewBackPackItem--Added
local InventoryItem = require(script.InventoryItem)
local toolBarAddItemEvent = ReplicatedStorage.RemoteEvent.ToolBarAddItemEvent

local Inventory = {}

local DEFAULT_ITEM_STACKS = {
	OilBarrel = 5,
	FireBarrel = 5
}

local MAX_STACKS = {
	NormalBarrel = 1,
	OilBarrel = 99,
	FireBarrel = 99
}

function Inventory.new(player)
	local self = setmetatable({}, Inventory)
	return self
end

function Inventory:Initialize(player)
	self.Player = player
	self.InventoryItemList = {}
end

function Inventory:IsExist(itemId)
	for _, v in pairs(self.InventoryItemList) do
		if v.Item.Id == itemId then
			return true
		end
	end
	return false
end

function Inventory:GetInventoryItem(itemId)
	for _, v in pairs(self.InventoryItemList) do
		if v.Item.Id == itemId and v.Count ~= MAX_STACKS[v.Item.Name] then
			return v
		end
	end
end

function Inventory:AddItem(item)
	local newInventoryItem = InventoryItem.new(item, DEFAULT_ITEM_STACKS[item.Name])
	if not self:IsExist(item.Id) then
		table.insert(self.InventoryItemList, newInventoryItem)
		
		if item.Category == "Tool"  then
			local toolItem = item.Tool:Clone()
			toolItem.Parent = self.Player.Backpack
		end
		return
	end
	
	local inventoryItem = self:GetInventoryItem(item.Id)
	if not inventoryItem then
		error("Failed to AddItem, Item id is not valid")
	end
	
	self:Merge(newInventoryItem, InventoryItem)
	if newInventoryItem.Item  then
		table.insert(self.InventoryItemList, newInventoryItem)
	end
	table.insert(self.InventoryItemList, InventoryItem)
end

return Inventory
