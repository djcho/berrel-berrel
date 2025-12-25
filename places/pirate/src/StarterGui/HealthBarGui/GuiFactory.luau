-- HealthBarGui GuiFactory: 동적으로 GUI 요소를 생성하는 모듈
local GuiFactory = {}

-- HealthBar Frame 생성
function GuiFactory.CreateHealthBar()
	-- HealthBar (외부 프레임)
	local healthBar = Instance.new("Frame")
	healthBar.Name = "HealthBar"
	healthBar.AnchorPoint = Vector2.new(0.5, 0.5)
	healthBar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	healthBar.BackgroundTransparency = 0.7
	healthBar.BorderColor3 = Color3.fromRGB(255, 255, 255)
	healthBar.BorderSizePixel = 1
	healthBar.Position = UDim2.new(0.5, 0, 0.844, 0)
	healthBar.Size = UDim2.new(0.331, 0, 0.027, 0)

	-- GreenFrame (체력 바)
	local greenFrame = Instance.new("Frame")
	greenFrame.Name = "GreenFrame"
	greenFrame.BackgroundColor3 = Color3.fromRGB(44, 238, 131)
	greenFrame.BorderSizePixel = 0
	greenFrame.Size = UDim2.new(1, 0, 1, 0)
	greenFrame.Parent = healthBar

	-- HealthStatus (체력 숫자)
	local healthStatus = Instance.new("TextLabel")
	healthStatus.Name = "HealthStatus"
	healthStatus.BackgroundTransparency = 1
	healthStatus.BorderSizePixel = 0
	healthStatus.Position = UDim2.new(0, 0, 0.1, 0)
	healthStatus.Size = UDim2.new(1, 0, 1, 0)
	healthStatus.Font = Enum.Font.LuckiestGuy
	healthStatus.Text = "100"
	healthStatus.TextColor3 = Color3.fromRGB(255, 255, 255)
	healthStatus.TextScaled = true
	healthStatus.TextWrapped = true
	healthStatus.TextStrokeTransparency = 0
	healthStatus.Parent = healthBar

	-- UITextSizeConstraint
	local textConstraint = Instance.new("UITextSizeConstraint")
	textConstraint.MaxTextSize = 20
	textConstraint.MinTextSize = 1
	textConstraint.Parent = healthStatus

	return healthBar
end

-- GuiId IntValue 생성
function GuiFactory.CreateGuiId(value)
	local guiId = Instance.new("IntValue")
	guiId.Name = "GuiId"
	guiId.Value = value or 800
	return guiId
end

return GuiFactory
