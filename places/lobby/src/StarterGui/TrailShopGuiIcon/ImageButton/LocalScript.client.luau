local button = script.Parent
local parent = button.Parent
local playerGui = script.Parent.Parent.Parent
local trailShopGui = playerGui:WaitForChild("TrailShopGui", 10)
local shopGui = playerGui:FindFirstChild("ShopGui")
local gameRoomGui = playerGui:FindFirstChild("GameRoomGui")

-- 해적 테마 색상
local COLORS = {
	gold = Color3.fromRGB(255, 200, 50),
	parchment = Color3.fromRGB(210, 180, 140),
}

-- TextLabel 동적 생성
local function createTextLabel()
	local textLabel = Instance.new("TextLabel")
	textLabel.Name = "TextLabel"
	textLabel.Size = UDim2.new(0, 80, 0, 20)
	textLabel.Position = UDim2.new(0.5, -40, 1, 5)
	textLabel.BackgroundTransparency = 1
	textLabel.TextColor3 = COLORS.gold
	textLabel.Text = "Trail 상점"
	textLabel.TextSize = 14
	textLabel.Font = Enum.Font.GothamBold
	textLabel.Parent = parent

	-- 텍스트 테두리 효과
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(0, 0, 0)
	stroke.Thickness = 1
	stroke.Parent = textLabel

	return textLabel
end

local textLabel = parent:FindFirstChild("TextLabel") or createTextLabel()

-- 원래 크기와 위치 저장
local originalButtonSize = button.Size
local originalTextLabelSize = textLabel.Size
local originalButtonPosition = button.Position
local originalTextLabelPosition = textLabel.Position

-- 크기와 위치 변화량 설정
local buttonSizeChange = 15
local buttonPositionChange = 5
local textLabelSizeChange = 5
local textLabelPositionChange = 2

-- 마우스 오버 시 크기와 위치 조정
button.MouseEnter:Connect(function()
	button:TweenSizeAndPosition(
		UDim2.new(originalButtonSize.X.Scale, originalButtonSize.X.Offset + buttonSizeChange, originalButtonSize.Y.Scale, originalButtonSize.Y.Offset + buttonSizeChange),
		UDim2.new(originalButtonPosition.X.Scale, originalButtonPosition.X.Offset - buttonPositionChange, originalButtonPosition.Y.Scale, originalButtonPosition.Y.Offset - buttonPositionChange),
		"Out", "Quad", 0.1, true
	)
	textLabel:TweenSizeAndPosition(
		UDim2.new(originalTextLabelSize.X.Scale, originalTextLabelSize.X.Offset + textLabelSizeChange, originalTextLabelSize.Y.Scale, originalTextLabelSize.Y.Offset + textLabelSizeChange),
		UDim2.new(originalTextLabelPosition.X.Scale, originalTextLabelPosition.X.Offset - textLabelPositionChange, originalTextLabelPosition.Y.Scale, originalTextLabelPosition.Y.Offset - textLabelPositionChange),
		"Out", "Quad", 0.1, true
	)
end)

-- 마우스가 떠날 시 원래 크기와 위치로 복원
button.MouseLeave:Connect(function()
	button:TweenSizeAndPosition(
		originalButtonSize,
		originalButtonPosition,
		"Out", "Quad", 0.1, true
	)
	textLabel:TweenSizeAndPosition(
		originalTextLabelSize,
		originalTextLabelPosition,
		"Out", "Quad", 0.1, true
	)
end)

-- 버튼 클릭 시 TrailShopGui 열기 (다른 GUI는 닫기)
button.MouseButton1Click:Connect(function()
	-- 게임룸 GUI 닫기
	if gameRoomGui then
		local mainFrame = gameRoomGui:FindFirstChild("MainFrame")
		if mainFrame then
			mainFrame.Visible = false
		end
	end
	-- 상점 GUI 닫기
	if shopGui then
		shopGui.Enabled = false
	end
	-- Trail 상점 GUI 열기
	if trailShopGui then
		trailShopGui.Enabled = true
	end
end)
