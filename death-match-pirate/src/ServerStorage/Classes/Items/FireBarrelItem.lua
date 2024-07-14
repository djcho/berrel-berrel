local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EnumData = require(ReplicatedStorage.Classes.EnumData)

local ServerStorage = game:GetService("ServerStorage")
local BaseItem = require(ServerStorage.Classes.Items.BaseItem)
local Inventory = require(ServerStorage.Classes.Inventory)
local fireBarrelTool = ServerStorage.Tool.FireBarrel

local ITEM_CATEGORY = "Tool"
local ITEM_NAME = "FireBarrel"
local ITEM_DISPLAY_NAME = "화염통"
local ITEM_ID = EnumData.ItemId.FireBarrel
local ITEM_PRICE = 5
local ITEM_ASSET_ID = "rbxassetid://8309080802"

local FireBarrelItem = {}
FireBarrelItem.__index = FireBarrelItem
setmetatable(FireBarrelItem, BaseItem)

function FireBarrelItem.new()
	local self = BaseItem.new(ITEM_CATEGORY, ITEM_NAME, ITEM_DISPLAY_NAME, ITEM_ID, ITEM_PRICE, ITEM_ASSET_ID, fireBarrelTool)	
	setmetatable(self, FireBarrelItem)
	return self
end


function FireBarrelItem:Activate(player)	
	if Inventory:AddItem(self) then
		return
	end	
end

return FireBarrelItem
