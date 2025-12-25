-- SingletonBase.lua
local SingletonBase = {}
SingletonBase.__index = SingletonBase

function SingletonBase:new(subclass)
	error("Cannot instantiate a singleton class directly. Use getInstance().")
end

function SingletonBase:getInstance()
	if not self._instance then
		self._instance = setmetatable({}, self)
		if self.Initialize then
			self._instance:Initialize()
		end
	end
	return self._instance
end

return SingletonBase
