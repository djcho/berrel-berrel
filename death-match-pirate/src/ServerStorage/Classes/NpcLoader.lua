local NpcLoader = {}
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--------------------NPC-------------------
local ShopNpc = require(ServerStorage.Classes.ShopNpc) 
local ShopSystem = require(ServerStorage.Classes.ShopSystem)
local EnumData = require(ReplicatedStorage.Classes.EnumData)

local SHOP_NPC_GUI_ID = 802

function NpcLoader:Initialize()
	self.RequestNpcInfo = ReplicatedStorage:WaitForChild("RequestNpcInfo")
	self.RequestNpcInfo.OnServerInvoke = function(player, npcId)
		return self:ResponseNpcInfo(npcId)
	end
	
	local shopItemList = ShopSystem:GetShopItemList(EnumData.NpcId.InvasionHelper)
	local invasionHelperModel = ServerStorage.Npc.InvasionHelper
	
	---------------------- Shop NPC -----------------------
	self.NpcList = {
		redTeamShopNpc = ShopNpc.new(EnumData.NpcId.InvasionHelper, "상점", invasionHelperModel, workspace.TeamA, 
			Vector3.new(413.958, 49.14, -67.547), Vector3.new(0, 90, 0), shopItemList, SHOP_NPC_GUI_ID),
		--blueTeamShopNpc = WorldNpc.new("0002", "상점", InvasionHelperModel, Vector3.new(413.958, 49.14, -67.547), Vector3.new(0, 90, 0))
	}
end

function NpcLoader:GetNpcByNpcId(npcId)
	for _, v in pairs(self.NpcList) do
		if v.NpcModel.NpcId.Value == npcId then
			return v
		end
	end
	return nil
end

function NpcLoader:ResponseNpcInfo(npcId)
	local npc = self:GetNpcByNpcId(npcId)
	if not npc then
		return nil
	end

	local npcInfo = {}
	npcInfo.NpcId = npc.NpcModel.NpcId.Value
	npcInfo.GuiId = npc.GuiId
	npcInfo.ShopItemList = npc.ShopItemList

	return npcInfo
end

function NpcLoader:GetShopItemListByNpcId(guiId)
	for _, v in pairs(self.NpcList) do
		if v.GuiId == guiId then
			return v.ShopItemList
		end
	end
	return nil
end


return NpcLoader
