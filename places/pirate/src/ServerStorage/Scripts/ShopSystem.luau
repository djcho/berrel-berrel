local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local ItemDescriptor = require(ServerStorage.Scripts.ItemDescriptor)
local requestItemCount = ReplicatedStorage:WaitForChild("RequestItemCount")
local OilBarrelItem = require(ServerStorage.Scripts.Items.OilBarrelItem)
local FireBarrelItem = require(ServerStorage.Scripts.Items.FireBarrelItem)
local EnumData = require(ReplicatedStorage.Classes.EnumData)
local ItemDb = require(ServerStorage.Scripts.Items.Database.ItemDb)

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
				ItemDb.Tool["OilBarrel"],
				ItemDb.Tool["FireBarrel"],
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
			for _, item in pairs(v.ItemList) do
				table.insert(itemList, ItemDescriptor:GetItemObject(item.Id))
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
