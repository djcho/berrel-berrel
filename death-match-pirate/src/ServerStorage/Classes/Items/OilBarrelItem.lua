local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EnumData = require(ReplicatedStorage.Classes.EnumData)

local ServerStorage = game:GetService("ServerStorage")
local BaseItem = require(ServerStorage.Classes.Items.BaseItem)
local Inventory = require(ServerStorage.Classes.Inventory)
local oilBarrelTool = ServerStorage.Tool.OilBarrel

local ITEM_CATEGORY = "Tool"
local ITEM_NAME = "OilBarrel"
local ITEM_DISPLAY_NAME = "기름통"
local ITEM_ID = EnumData.ItemId.OilBarrel
local ITEM_PRICE = 3
local ITEM_ASSET_ID = "rbxassetid://8309080500"

local OilBarrelItem = {}
OilBarrelItem.__index = OilBarrelItem
setmetatable(OilBarrelItem, BaseItem)

function OilBarrelItem.new()
	local self = BaseItem.new(ITEM_CATEGORY, ITEM_NAME, ITEM_DISPLAY_NAME, ITEM_ID, ITEM_PRICE, ITEM_ASSET_ID, oilBarrelTool)
	setmetatable(self, OilBarrelItem)
	return self
end

function OilBarrelItem:Activate(player)	
	if Inventory:IsExist(self.Tool) then
		return
	end	
end

return OilBarrelItem
