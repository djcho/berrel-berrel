local shopNpcGui = script.Parent
local backgroundFrame = shopNpcGui:WaitForChild("BackgroundFrame")
local leftFrame = backgroundFrame:WaitForChild("LeftFrame")

local selectedItemImage = leftFrame:WaitForChild("SelectedItemImage")
local purchaseButton = leftFrame:WaitForChild("PurchaseButton")
local itemId = leftFrame:WaitForChild("ItemId")
local itemName = leftFrame:WaitForChild("ItemName")
local itemPrice = leftFrame:WaitForChild("ItemPrice")

local rightFrame = backgroundFrame:WaitForChild("RightFrame")
local topFrame = rightFrame:WaitForChild("TopFrame")
local playerGold = topFrame:WaitForChild("PlayerGold")

local closeButton = rightFrame:WaitForChild("CloseButton")

local player = game.Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local requestItemPriceEvent = ReplicatedStorage:WaitForChild("RequestItemPrice")
local LocalUserData = require(game.ReplicatedStorage.Classes.LocalUserData)
local localUserData = LocalUserData.ReturnData(player)
local alretMessageEvent = ReplicatedStorage:WaitForChild("AlretMessageEvent")
local ShopManager = require(ReplicatedStorage.Classes.ShopManager)
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Initialize ShopManager object
local shopManager = ShopManager.new(alretMessageEvent)

function GetItemListByCategory(shopItemList, category)
	local itemList = {}
	for _, v in pairs(shopItemList) do
		if v.Category == category then
			table.insert(itemList, v)
		end
	end
	return itemList
end

function OnOpenGui(shopItemList)
	localUserData.Shopping = true
	backgroundFrame.Visible = true
	leftFrame.Visible = true
	rightFrame.Visible = true	
	
	local toolItemList = GetItemListByCategory(shopItemList, "Tool")
	local generalItemList = GetItemListByCategory(shopItemList, "General")
	
	shopManager:DisplayItems(rightFrame.Items, toolItemList, OnClickItem)
	shopManager:DisplayItems(rightFrame.Upgrade, generalItemList, OnClickItem)

	playerGold.Text = player.leaderstats.Coins.Value
end

function OnCloseGui()
	shopManager:ClearItems()
	
	localUserData.Shopping = false
	backgroundFrame.Visible = false
	leftFrame.Visible = false
	rightFrame.Visible = false	
	itemName.Text = ""
	itemPrice.Text = ""
	itemId = nil
	selectedItemImage.Image = ""
end


function OnClickItem(item)
	itemId = item.Id
	selectedItemImage.Image = item.TextureId
	itemName.Text = item.DisplayName
	itemPrice.Text = item.Price
end


function OnPurchase()
	if itemId == nil then
		return
	end

	shopManager:PurchaseItem(itemId)
end


local openGuiEvent = script.Parent:WaitForChild("OpenGuiEvent")
openGuiEvent.Event:Connect(function(npcInfo)
	if not npcInfo  then
		return
	end
	
	if npcInfo.GuiId == script.Parent:FindFirstChild("GuiId").Value then
		OnOpenGui(npcInfo.ShopItemList)
	end
end)

purchaseButton.MouseButton1Click:Connect(OnPurchase)
closeButton.MouseButton1Up:Connect(OnCloseGui)

