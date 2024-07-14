local ShopNpc = {}
ShopNpc.__index = ShopNpc

function ShopNpc.new(id, name, npcModel, npcParent, position, rotation, shopItemList, guiId)
	local self = setmetatable(ShopNpc, {})
	
	self.NpcModel = npcModel:Clone()
	self.NpcModel.Parent = npcParent
	
	self.NpcModel.NpcId.Value = id
	self.NpcModel.Humanoid.DisplayName = name
	self.NpcModel:SetPrimaryPartCFrame(CFrame.new(position.X, position.Y, position.Z)
		* CFrame.Angles(math.rad(rotation.X), math.rad(rotation.Y), math.rad(rotation.Z)))
	self.ShopItemList = shopItemList
	self.GuiId = guiId
	
	return self
end

return ShopNpc
