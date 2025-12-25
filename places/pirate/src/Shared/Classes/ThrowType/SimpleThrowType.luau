-- SimpleThrowType.lua

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local BaseThrowType = require(ReplicatedStorage:WaitForChild("Classes"):WaitForChild("ThrowType"):WaitForChild("BaseThrowType"))
local SimpleThrowType = setmetatable({}, BaseThrowType)
SimpleThrowType.__index = SimpleThrowType

-- SimpleThrowType 객체를 생성하는 생성자 함수
function SimpleThrowType.new(barrelInfo)
	local self = setmetatable(BaseThrowType.new(barrelInfo), SimpleThrowType)
	return self
end

-- 도구를 초기화하는 함수
function SimpleThrowType:initialize(tool)
	-- 부모 클래스의 초기화 함수 호출
	BaseThrowType.initialize(self, tool)
	-- 도구 장착 시 호출되는 이벤트 연결
	self.Tool.Equipped:Connect(function(mouse)
		self:onEquipped(mouse) -- 도구 장착 시 호출
		-- 마우스 왼쪽 버튼 누를 때 연결
		mouse.Button1Down:Connect(function() self:onMouseDown() end)
	end)
	-- 도구 해제 시 호출되는 이벤트 연결
	self.Tool.Unequipped:Connect(function() self:onUnequipped() end)

	-- 모바일 터치 지원 추가
	UserInputService.TouchStarted:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		if input.UserInputType == Enum.UserInputType.Touch then
			self:onMouseDown()
		end
	end)
end

return SimpleThrowType
