-- ConinAreaService ModuleScript in ServerScriptService/Scripts/Service
local SingletonBase = require(game:GetService("ServerScriptService"):WaitForChild("Common"):WaitForChild("SingletonBase"))
local CoinAreaService = setmetatable({}, { __index = SingletonBase })
CoinAreaService.__index = CoinAreaService

function CoinAreaService:Initialize()
	-- ConinAreaService 초기화 로직
	print("ConinAreaService initialized!")
end

return CoinAreaService
