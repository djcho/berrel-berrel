-- GuiFactory: 동적으로 GUI 요소를 생성하는 모듈
local GuiFactory = {}

-- MoveableFrame (툴바 슬롯) 생성
function GuiFactory.CreateMoveableFrame()
	-- MoveableFrame (외부 컨테이너)
	local moveableFrame = Instance.new("Frame")
	moveableFrame.Name = "MoveableFrame"
	moveableFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	moveableFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	moveableFrame.BackgroundTransparency = 1
	moveableFrame.BorderSizePixel = 0
	moveableFrame.Position = UDim2.new(0, 1, 0, 1)
	moveableFrame.Size = UDim2.new(0.111, 0, 1, 0)

	-- ToolItem (내부 프레임)
	local toolItem = Instance.new("Frame")
	toolItem.Name = "ToolItem"
	toolItem.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	toolItem.BackgroundTransparency = 0.8
	toolItem.BorderColor3 = Color3.fromRGB(77, 77, 77)
	toolItem.BorderSizePixel = 1
	toolItem.Position = UDim2.new(0, 0, -0.00422, 0)
	toolItem.Size = UDim2.new(1, 0, 1, 0)
	toolItem.Parent = moveableFrame

	-- Icon (ImageButton)
	local icon = Instance.new("ImageButton")
	icon.Name = "Icon"
	icon.BackgroundTransparency = 1
	icon.BorderSizePixel = 1
	icon.Position = UDim2.new(0, 1, 0, 1)
	icon.Size = UDim2.new(0.99, 0, 1, 0)
	icon.AutoButtonColor = true
	icon.LayoutOrder = 1
	icon.Parent = toolItem

	-- Number (슬롯 번호)
	local number = Instance.new("TextLabel")
	number.Name = "Number"
	number.BackgroundColor3 = Color3.fromRGB(77, 77, 77)
	number.BackgroundTransparency = 0
	number.BorderColor3 = Color3.fromRGB(77, 77, 77)
	number.BorderSizePixel = 0
	number.Position = UDim2.new(0, 0, 0, 0)
	number.Size = UDim2.new(0.2, 0, 0.2, 0)
	number.Font = Enum.Font.SourceSans
	number.Text = "1"
	number.TextColor3 = Color3.fromRGB(255, 255, 255)
	number.TextScaled = true
	number.TextWrapped = true
	number.Parent = toolItem

	-- Number UITextSizeConstraint
	local numberConstraint = Instance.new("UITextSizeConstraint")
	numberConstraint.MaxTextSize = 14
	numberConstraint.MinTextSize = 1
	numberConstraint.Parent = number

	-- Stack (남은 탄환 수)
	local stack = Instance.new("TextLabel")
	stack.Name = "Stack"
	stack.BackgroundTransparency = 1
	stack.Position = UDim2.new(0.679, 0, 0.648, 0)
	stack.Size = UDim2.new(0.32, 0, 0.347, 0)
	stack.Font = Enum.Font.LuckiestGuy
	stack.Text = "0"
	stack.TextColor3 = Color3.fromRGB(255, 255, 255)
	stack.TextScaled = true
	stack.TextWrapped = true
	stack.TextStrokeTransparency = 0
	stack.LayoutOrder = 1
	stack.Parent = toolItem

	-- Stack UITextSizeConstraint
	local stackConstraint = Instance.new("UITextSizeConstraint")
	stackConstraint.MaxTextSize = 23
	stackConstraint.MinTextSize = 1
	stackConstraint.Parent = stack

	-- ToolName (StringValue)
	local toolName = Instance.new("StringValue")
	toolName.Name = "ToolName"
	toolName.Value = ""
	toolName.Parent = toolItem

	-- Selected (BoolValue)
	local selected = Instance.new("BoolValue")
	selected.Name = "Selected"
	selected.Value = false
	selected.Parent = toolItem

	-- SelectedEvent (BindableEvent)
	local selectedEvent = Instance.new("BindableEvent")
	selectedEvent.Name = "SelectedEvent"
	selectedEvent.Parent = toolItem

	-- DeselectedEvent (BindableEvent)
	local deselectedEvent = Instance.new("BindableEvent")
	deselectedEvent.Name = "DeselectedEvent"
	deselectedEvent.Parent = toolItem

	-- ReloadOverlay (ImageLabel)
	local reloadOverlay = Instance.new("ImageLabel")
	reloadOverlay.Name = "ReloadOverlay"
	reloadOverlay.BackgroundTransparency = 1
	reloadOverlay.Size = UDim2.new(1, 0, 1, 0)
	reloadOverlay.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
	reloadOverlay.ImageTransparency = 0.5
	reloadOverlay.Visible = false
	reloadOverlay.Parent = toolItem

	-- ToolItem LocalScript 로직 설정
	GuiFactory.SetupToolItemBehavior(toolItem)

	return moveableFrame
end

-- ToolItem 동작 설정 (선택/해제 애니메이션)
function GuiFactory.SetupToolItemBehavior(toolItem)
	local number = toolItem:WaitForChild("Number")
	local icon = toolItem:WaitForChild("Icon")
	local selected = toolItem:WaitForChild("Selected")
	local selectedEvent = toolItem:WaitForChild("SelectedEvent")
	local deselectedEvent = toolItem:WaitForChild("DeselectedEvent")

	local originPosition = toolItem.Position
	local orignBackgroundColor = toolItem.BackgroundColor3
	local orignBorderColor = toolItem.BorderColor3
	local numberOriginBackgroundColor = number.BackgroundColor3
	local numberOriginBorderColor = number.BorderColor3
	local numberOriginTextColor = number.TextColor3

	local function OnDeselectedToolBar()
		selected.Value = false
		toolItem.BorderColor3 = orignBorderColor
		number.BackgroundColor3 = numberOriginBackgroundColor
		number.BorderColor3 = numberOriginBorderColor
		number.TextColor3 = numberOriginTextColor
		toolItem:TweenPosition(
			originPosition,
			Enum.EasingDirection.In,
			Enum.EasingStyle.Sine,
			0.1,
			true
		)
	end

	local function OnSelectedToolBar()
		selected.Value = true
		toolItem.BorderColor3 = Color3.new(1, 1, 1)
		number.BackgroundColor3 = Color3.new(1, 1, 1)
		number.BorderColor3 = Color3.new(1, 1, 1)
		number.TextColor3 = Color3.new(0, 0, 0)
		toolItem:TweenPosition(
			UDim2.new(
				toolItem.Position.X.Scale, toolItem.Position.X.Offset,
				toolItem.Position.Y.Scale - 0.15, toolItem.Position.Y.Offset
			),
			Enum.EasingDirection.In,
			Enum.EasingStyle.Sine,
			0.1,
			true
		)
	end

	local function OnMouseEnter()
		toolItem.BackgroundColor3 = Color3.fromRGB(171, 128, 102)
	end

	local function OnMouseLeave()
		toolItem.BackgroundColor3 = orignBackgroundColor
	end

	icon.MouseEnter:Connect(OnMouseEnter)
	icon.MouseLeave:Connect(OnMouseLeave)
	deselectedEvent.Event:Connect(OnDeselectedToolBar)
	selectedEvent.Event:Connect(OnSelectedToolBar)
end

-- ToolBar 메인 Frame 생성
function GuiFactory.CreateToolBarFrame()
	local frame = Instance.new("Frame")
	frame.Name = "Frame"
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.BackgroundTransparency = 1
	frame.BorderSizePixel = 0
	frame.Position = UDim2.new(0.5, 0, 0.939, 0)
	frame.Size = UDim2.new(0.483, 0, 0.099, 0)

	local listLayout = Instance.new("UIListLayout")
	listLayout.FillDirection = Enum.FillDirection.Horizontal
	listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	listLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Parent = frame

	return frame
end

return GuiFactory
