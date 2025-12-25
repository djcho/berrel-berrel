local MockDataStore = {}
MockDataStore.__index = MockDataStore

local PAGE_SIZE = 10

function MockDataStore.new()
	local self = setmetatable({}, MockDataStore)
	self.data = {}
	return self
end

function MockDataStore:GetAsync(key)
	return self.data[key]
end

function MockDataStore:SetAsync(key, value)
	self.data[key] = value
end

function MockDataStore:RemoveAsync(key)
	self.data[key] = nil
end

function MockDataStore:UpdateAsync(key, transformFunction)
	local currentValue = self.data[key]
	local newValue = transformFunction(currentValue)
	if newValue ~= nil then
		self.data[key] = newValue
	end
	return newValue
end

function MockDataStore:ListKeysAsync()
	local keys = {}
	for key in pairs(self.data) do
		table.insert(keys, key)
	end

	local currentIndex = 1
	local function getPage()
		local page = {}
		for i = currentIndex, math.min(currentIndex + PAGE_SIZE - 1, #keys) do
			table.insert(page, keys[i])
		end
		currentIndex = currentIndex + PAGE_SIZE
		return page
	end

	return {
		GetCurrentPage = function()
			return getPage()
		end,
		AdvanceToNextPageAsync = function()
			if currentIndex > #keys then
				return nil
			end
			return getPage()
		end,
		IsFinished = function()
			return currentIndex > #keys
		end
	}
end

return MockDataStore
