local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local ItemDescriptor = require(ServerStorage.Classes.ItemDescriptor)
local requestItemCount = ReplicatedStorage:WaitForChild("RequestItemCount")
local OilBarrelItem = require(ServerStorage.Classes.Items.OilBarrelItem)
local FireBarrelItem = require(ServerStorage.Classes.Items.FireBarrelItem)
local NormalBarrelUpgradeItem = require(ServerStorage.Classes.Items.NormalBarrelUpgradeItem)
local EnumData = require(ReplicatedStorage.Classes.EnumData)

local ShopSystem = {}

function ShopSystem:Initialize()
	self.ShopItemTable = {
		{
			NpcId = 000, 
			ItemList = {
			}
		},
		{
			NpcId = EnumData.NpcId.InvasionHelper,
			ItemList = {
				EnumData.ItemId.OilBarrel,
				EnumData.ItemId.FireBarrel,
				EnumData.ItemId.NormalBarrelUpgradeItem
			}
		}
	}
	self.RequestItemCount = ReplicatedStorage:WaitForChild("RequestItemCount")
	self.RequestItemCount.OnServerInvoke = function(player, itemId)
		return self:CountItem(player, itemId)
	end
	self.ActivateItemEvent = ReplicatedStorage:WaitForChild("ActivateItemEvent")
	self.ActivateItemEvent.OnServerEvent:Connect(function(player, itemId)
		self:ActivateItem(player, itemId)
	end)
end

function ShopSystem:GetShopItemList(npcId)
	local itemList = {}
	for _, v in pairs(self.ShopItemTable) do
		if v.NpcId == npcId then
			for _, itemId in pairs(v.ItemList) do
				table.insert(itemList, ItemDescriptor:GetItemObject(itemId))
			end
			break
		end
	end
	return itemList	
end

function ShopSystem:CountItem(player, itemId)
	local itemObj = ItemDescriptor:GetItemObject(itemId)
	if player.leaderstats.Coins.Value < itemObj.Price then
		return {Result = false, Message = "금액이 부족합니다."}
	end

	player.leaderstats.Coins.Value -= itemObj.Price
	return {Result = true, Message = "구매 완료!"}
end

function ShopSystem:ActivateItem(player, itemId)
	local itemObj = ItemDescriptor:GetItemObject(itemId)
	itemObj:Activate(player)
end

return ShopSystem
