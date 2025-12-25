local BaseItem = {}
BaseItem.__index = BaseItem

function BaseItem.new(id, category, name, displayName, iconId, maxStack)
	local self = setmetatable({}, BaseItem)	
	
	self.CurrentStack = 1 
	self.Id = id
	self.Category = category
	self.DisplayName = displayName
	self.Name = name
	self.IconId = iconId
	self.MaxStack = maxStack
	
	return self
end


function BaseItem:Activate(player)
	print("BaseItem Activate")
end

function BaseItem:Merge(item)
	if not item.Id or (self.Id == item.Id) then
		-- either no item in dest, or both types are the same

		local result = self.CurrentStack + item.CurrentStack
		item.CurrentStack = math.min(result, item.MaxStack)
		self.CurrentStack = result - item.MaxStack

		if self.CurrentStack < 1 then
			-- source depleted; destroy the item
			-- handle this your own way, I'll just unassign its type
			self = nil
		end
	end
end


return BaseItem
