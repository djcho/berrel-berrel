--[[
	GuiIconManager: 로비 GUI 아이콘들을 동적으로 생성하고 관리

	생성되는 아이콘:
	- ShopGuiIcon (보물 상점)
	- GameRoomGuiIcon (선원 모집)
	- TrailShopGuiIcon (Trail 상점)
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- 다른 GUI들이 로드될 때까지 대기
local shopGui = playerGui:WaitForChild("ShopGui", 10)
local gameRoomGui = playerGui:WaitForChild("GameRoomGui", 10)
local trailShopGui = playerGui:WaitForChild("TrailShopGui", 10)

-- 해적 테마 색상
local COLORS = {
	gold = Color3.fromRGB(255, 200, 50),
	parchment = Color3.fromRGB(210, 180, 140),
	black = Color3.fromRGB(0, 0, 0),
}

-- 아이콘 설정
local ICON_CONFIG = {
	{
		name = "ShopGuiIcon",
		imageId = "rbxassetid://111865988369771",
		labelText = "보물 상점",
		position = UDim2.new(0, 20, 1, -130),
		onClick = function()
			-- 게임룸 GUI 닫기
			if gameRoomGui then
				local mainFrame = gameRoomGui:FindFirstChild("MainFrame")
				if mainFrame then
					mainFrame.Visible = false
				end
			end
			-- Trail 상점 GUI 닫기
			if trailShopGui then
				trailShopGui.Enabled = false
			end
			-- 상점 GUI 열기
			if shopGui then
				shopGui.Enabled = true
			end
		end
	},
	{
		name = "GameRoomGuiIcon",
		imageId = "rbxassetid://131431773353571",
		labelText = "선원 모집",
		position = UDim2.new(0, 140, 1, -130),
		onClick = function()
			-- 상점 GUI 닫기
			if shopGui then
				shopGui.Enabled = false
			end
			-- Trail 상점 GUI 닫기
			if trailShopGui then
				trailShopGui.Enabled = false
			end
			-- 게임룸 GUI 열기
			if gameRoomGui then
				local mainFrame = gameRoomGui:FindFirstChild("MainFrame")
				if mainFrame then
					mainFrame.Visible = true
					-- 게임 목록 요청
					local requestEvent = ReplicatedStorage:FindFirstChild("RequestGameList")
					if requestEvent then
						requestEvent:FireServer()
					end
				end
			end
		end
	},
	{
		name = "TrailShopGuiIcon",
		imageId = "rbxassetid://111865988369771",
		labelText = "Trail 상점",
		position = UDim2.new(0, 260, 1, -130),
		onClick = function()
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
		end
	},
}

-- 호버 애니메이션 설정
local BUTTON_SIZE = UDim2.new(0, 100, 0, 100)
local BUTTON_SIZE_CHANGE = 15
local BUTTON_POSITION_CHANGE = 5
local LABEL_SIZE = UDim2.new(0, 80, 0, 20)
local LABEL_SIZE_CHANGE = 5
local LABEL_POSITION_CHANGE = 2

-- 아이콘 생성 함수
local function createIcon(config)
	-- ScreenGui 생성
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = config.name
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = playerGui

	-- ImageButton 생성
	local button = Instance.new("ImageButton")
	button.Name = "ImageButton"
	button.Size = BUTTON_SIZE
	button.Position = config.position
	button.BackgroundTransparency = 1
	button.Image = config.imageId
	button.Parent = screenGui

	-- TextLabel 생성
	local textLabel = Instance.new("TextLabel")
	textLabel.Name = "TextLabel"
	textLabel.Size = LABEL_SIZE
	textLabel.Position = UDim2.new(0.5, -40, 1, 5)
	textLabel.BackgroundTransparency = 1
	textLabel.TextColor3 = COLORS.gold
	textLabel.Text = config.labelText
	textLabel.TextSize = 14
	textLabel.Font = Enum.Font.GothamBold
	textLabel.Parent = screenGui

	-- 텍스트 테두리 효과
	local stroke = Instance.new("UIStroke")
	stroke.Color = COLORS.black
	stroke.Thickness = 1
	stroke.Parent = textLabel

	-- 원래 크기와 위치 저장
	local originalButtonSize = button.Size
	local originalButtonPosition = button.Position
	local originalLabelSize = textLabel.Size
	local originalLabelPosition = textLabel.Position

	-- 마우스 오버 시 크기와 위치 조정
	button.MouseEnter:Connect(function()
		button:TweenSizeAndPosition(
			UDim2.new(
				originalButtonSize.X.Scale,
				originalButtonSize.X.Offset + BUTTON_SIZE_CHANGE,
				originalButtonSize.Y.Scale,
				originalButtonSize.Y.Offset + BUTTON_SIZE_CHANGE
			),
			UDim2.new(
				originalButtonPosition.X.Scale,
				originalButtonPosition.X.Offset - BUTTON_POSITION_CHANGE,
				originalButtonPosition.Y.Scale,
				originalButtonPosition.Y.Offset - BUTTON_POSITION_CHANGE
			),
			Enum.EasingDirection.Out,
			Enum.EasingStyle.Quad,
			0.1,
			true
		)
		textLabel:TweenSizeAndPosition(
			UDim2.new(
				originalLabelSize.X.Scale,
				originalLabelSize.X.Offset + LABEL_SIZE_CHANGE,
				originalLabelSize.Y.Scale,
				originalLabelSize.Y.Offset + LABEL_SIZE_CHANGE
			),
			UDim2.new(
				originalLabelPosition.X.Scale,
				originalLabelPosition.X.Offset - LABEL_POSITION_CHANGE,
				originalLabelPosition.Y.Scale,
				originalLabelPosition.Y.Offset - LABEL_POSITION_CHANGE
			),
			Enum.EasingDirection.Out,
			Enum.EasingStyle.Quad,
			0.1,
			true
		)
	end)

	-- 마우스가 떠날 시 원래 크기와 위치로 복원
	button.MouseLeave:Connect(function()
		button:TweenSizeAndPosition(
			originalButtonSize,
			originalButtonPosition,
			Enum.EasingDirection.Out,
			Enum.EasingStyle.Quad,
			0.1,
			true
		)
		textLabel:TweenSizeAndPosition(
			originalLabelSize,
			originalLabelPosition,
			Enum.EasingDirection.Out,
			Enum.EasingStyle.Quad,
			0.1,
			true
		)
	end)

	-- 클릭 이벤트
	button.MouseButton1Click:Connect(config.onClick)

	return screenGui
end

-- 모든 아이콘 생성
for _, config in ipairs(ICON_CONFIG) do
	createIcon(config)
end

print("[GuiIconManager] GUI 아이콘 생성 완료")
