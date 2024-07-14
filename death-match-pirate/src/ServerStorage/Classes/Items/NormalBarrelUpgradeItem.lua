local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EnumData = require(ReplicatedStorage.Classes.EnumData)

local ServerStorage = game:GetService("ServerStorage")
local BaseItem = require(ServerStorage.Classes.Items.BaseItem)

local ITEM_CATEGORY = "General"
local ITEM_NAME = "NormalBarrelUpgrade"
local ITEM_DISPLAY_NAME = "기본통 업그레이드"
local ITEM_ID = EnumData.ItemId.NormalBarrelUpgradeItem
local ITEM_PRICE = 2
local ITEM_ASSET_ID = "rbxassetid://8309081025"

local NormalBarrelUpgradeItem = {}
NormalBarrelUpgradeItem.__index = NormalBarrelUpgradeItem
setmetatable(NormalBarrelUpgradeItem, BaseItem)

function NormalBarrelUpgradeItem.new()
	local self = BaseItem.new(ITEM_CATEGORY, ITEM_NAME, ITEM_DISPLAY_NAME, ITEM_ID, ITEM_PRICE, ITEM_ASSET_ID)	
	setmetatable(self, NormalBarrelUpgradeItem)
	return self
end

function NormalBarrelUpgradeItem:Activate(player)

end

return NormalBarrelUpgradeItem
