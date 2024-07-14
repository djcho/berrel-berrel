local BaseItem = {}
BaseItem.__index = BaseItem

function BaseItem.new(category, name, displayName, id, price, textureId, toolObject)
	local self = setmetatable({}, BaseItem)	
	
	self.Category = category
	self.DisplayName = displayName
	self.Name = name
	self.Id = id
	self.Price = price
	self.TextureId = textureId
	self.Tool = toolObject
	
	return self
end


function BaseItem:Activate(player)
	print("BaseItem Activate")
end

return BaseItem
