local InventoryItem = {}
InventoryItem.__index = InventoryItem
setmetatable(InventoryItem, {})

function InventoryItem.new(item, count, maxCount)
	local self = setmetatable({}, InventoryItem)
	self.Item = item
	self.Count = count
	self.MaxCount = maxCount
	return self
end


function InventoryItem.Merge(source, dest)
	if not dest.Item or (source.Item == dest.Item) then
		-- either no item in dest, or both types are the same

		local result = source.Count + dest.Count
		dest.Count = math.min(result, dest.MaxCount)
		source.Count = result - dest.MaxCount

		if source.Count < 1 then
			-- source depleted; destroy the item
			-- handle this your own way, i'll just unassign its type
			source.Item = nil
		end
	end
end


return InventoryItem
