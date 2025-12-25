-- ScreenGui GuiFactory: 동적으로 GUI 요소를 생성하는 모듈
local GuiFactory = {}

-- CurrentGold TextLabel 생성
function GuiFactory.CreateCurrentGold()
	local currentGold = Instance.new("TextLabel")
	currentGold.Name = "CurrentGold"
	currentGold.AnchorPoint = Vector2.new(0.5, 0.5)
	currentGold.BackgroundTransparency = 1
	currentGold.BorderSizePixel = 0
	currentGold.Position = UDim2.new(0.92, 0, 0.95, 0)
	currentGold.Size = UDim2.new(0.173, 0, 0.078, 0)
	currentGold.Font = Enum.Font.Gotham
	currentGold.Text = "골드 : 0"
	currentGold.TextColor3 = Color3.fromRGB(255, 255, 255)
	currentGold.TextScaled = true
	currentGold.TextWrapped = true
	currentGold.TextStrokeTransparency = 0
	currentGold.TextXAlignment = Enum.TextXAlignment.Left

	-- UIAspectRatioConstraint
	local aspectRatio = Instance.new("UIAspectRatioConstraint")
	aspectRatio.AspectRatio = 4
	aspectRatio.Parent = currentGold

	-- UITextSizeConstraint
	local textConstraint = Instance.new("UITextSizeConstraint")
	textConstraint.MaxTextSize = 28
	textConstraint.MinTextSize = 1
	textConstraint.Parent = currentGold

	return currentGold
end

-- AlertMessage Frame 생성
function GuiFactory.CreateAlertFrame()
	local frame = Instance.new("Frame")
	frame.Name = "Frame"
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.BackgroundTransparency = 1
	frame.Position = UDim2.new(0.5, 0, 0.2, 0)
	frame.Size = UDim2.new(0.51, 0, 0.038, 0)
	frame.ZIndex = 0

	-- AlertMessage TextLabel
	local alertMessage = Instance.new("TextLabel")
	alertMessage.Name = "AlertMessage"
	alertMessage.BackgroundTransparency = 1
	alertMessage.Size = UDim2.new(1, 0, 1, 0)
	alertMessage.Font = Enum.Font.Gotham
	alertMessage.Text = ""
	alertMessage.TextColor3 = Color3.fromRGB(255, 0, 0)
	alertMessage.TextScaled = true
	alertMessage.TextWrapped = true
	alertMessage.LayoutOrder = 10
	alertMessage.Parent = frame

	-- UITextSizeConstraint for AlertMessage
	local alertTextConstraint = Instance.new("UITextSizeConstraint")
	alertTextConstraint.MaxTextSize = 26
	alertTextConstraint.MinTextSize = 1
	alertTextConstraint.Parent = alertMessage

	-- UIAspectRatioConstraint for Frame
	local frameAspect = Instance.new("UIAspectRatioConstraint")
	frameAspect.AspectRatio = 24.577
	frameAspect.Parent = frame

	return frame
end

-- GuiId IntValue 생성
function GuiFactory.CreateGuiId(value)
	local guiId = Instance.new("IntValue")
	guiId.Name = "GuiId"
	guiId.Value = value or 801
	return guiId
end

return GuiFactory
