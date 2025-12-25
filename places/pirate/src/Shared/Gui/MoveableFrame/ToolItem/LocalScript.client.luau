local ReplicatedStorage = game:GetService("ReplicatedStorage")
local moveableFrame = script.Parent.Parent
local toolItem = script.Parent
local number = toolItem:WaitForChild("Number")
local selectedEvent = toolItem:WaitForChild("SelectedEvent")
local deselectedEvent = toolItem:WaitForChild("DeselectedEvent")
local icon = toolItem:WaitForChild("Icon") 

local originPosition = toolItem.Position
local orignBackgroundColor = toolItem.BackgroundColor3
local orignBorderColor = toolItem.BorderColor3
local numberOriginBackgroundColor = number.BackgroundColor3
local numberOriginBorderColor = number.BorderColor3
local numberOriginTextColor = number.TextColor3

local selected = toolItem:WaitForChild("Selected")
local function OnDeselectedToolBar()
	
	selected.Value = false
	toolItem.BorderColor3 = orignBorderColor
	number.BackgroundColor3 = numberOriginBackgroundColor
	number.BorderColor3 = numberOriginBorderColor
	number.TextColor3 = numberOriginTextColor
	toolItem:TweenPosition(
		originPosition,           -- Final position the tween should reach
		Enum.EasingDirection.In, -- Direction of the easing
		Enum.EasingStyle.Sine,   -- Kind of easing to apply
		0.1,                       -- Duration of the tween in seconds
		true                    -- Whether in-progress tweens are interrupted		
	)
end


local function OnSelectedToolBar()
	selected.Value = true
	toolItem.BorderColor3 = Color3.new(1,1,1)
	number.BackgroundColor3 = Color3.new(1,1,1)
	number.BorderColor3 = Color3.new(1,1,1)
	number.TextColor3 = Color3.new(0,0,0)
	toolItem:TweenPosition(
		UDim2.new(toolItem.Position.X.Scale, toolItem.Position.X.Offset, 
			toolItem.Position.Y.Scale - 0.15, toolItem.Position.Y.Offset),           -- Final position the tween should reach
		Enum.EasingDirection.In, -- Direction of the easing
		Enum.EasingStyle.Sine,   -- Kind of easing to apply
		0.1,                       -- Duration of the tween in seconds
		true                    -- Whether in-progress tweens are interrupted		
	)
end


local function OnMouseButton1Down()
	if selected.Value then
		
	end
	OnSelectedToolBar()
end


local function OnMouseEnter()
	toolItem.BackgroundColor3 = Color3.new(0.67, 0.5, 0.4)
end


local function OnMouseLeave()
	toolItem.BackgroundColor3 = orignBackgroundColor
end


icon.MouseEnter:Connect(OnMouseEnter)
icon.MouseLeave:Connect(OnMouseLeave)

deselectedEvent.Event:Connect(OnDeselectedToolBar)
selectedEvent.Event:Connect(OnSelectedToolBar)