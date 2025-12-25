local button = script.Parent
local textLabel = button.Parent:FindFirstChild("TextLabel")
local shopGui = script.Parent.Parent.Parent:FindFirstChild("ShopGui") -- ShopGui가 부모 객체에 있다고 가정

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

-- 버튼 클릭 시 ShopGui 출력
button.MouseButton1Click:Connect(function()
	if shopGui then
		shopGui.Enabled = true -- ShopGui를 활성화
	end
end)
