local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local screenGui = script.Parent

-- 설정
local LOBBY_PLACE_ID = 18517272972

-- 해적 테마 색상
local COLORS = {
	woodDark = Color3.fromRGB(62, 39, 22),
	gold = Color3.fromRGB(255, 200, 50),
	goldDark = Color3.fromRGB(180, 140, 30),
	red = Color3.fromRGB(150, 40, 40),
	black = Color3.fromRGB(20, 15, 10),
}

-- 나가기 버튼 생성
local leaveButton = Instance.new("TextButton")
leaveButton.Name = "LeaveButton"
leaveButton.Size = UDim2.new(0, 50, 0, 50)
leaveButton.Position = UDim2.new(0, 20, 0, 20)
leaveButton.BackgroundColor3 = COLORS.woodDark
leaveButton.TextColor3 = COLORS.gold
leaveButton.Text = "X"
leaveButton.TextSize = 24
leaveButton.Font = Enum.Font.GothamBlack
leaveButton.Parent = screenGui

local buttonCorner = Instance.new("UICorner")
buttonCorner.CornerRadius = UDim.new(0, 10)
buttonCorner.Parent = leaveButton

local buttonStroke = Instance.new("UIStroke")
buttonStroke.Color = COLORS.goldDark
buttonStroke.Thickness = 2
buttonStroke.Parent = leaveButton

-- 확인 다이얼로그
local confirmFrame = Instance.new("Frame")
confirmFrame.Name = "ConfirmFrame"
confirmFrame.Size = UDim2.new(0, 300, 0, 150)
confirmFrame.Position = UDim2.new(0.5, -150, 0.5, -75)
confirmFrame.BackgroundColor3 = COLORS.woodDark
confirmFrame.Visible = false
confirmFrame.Parent = screenGui

local confirmCorner = Instance.new("UICorner")
confirmCorner.CornerRadius = UDim.new(0, 12)
confirmCorner.Parent = confirmFrame

local confirmStroke = Instance.new("UIStroke")
confirmStroke.Color = COLORS.goldDark
confirmStroke.Thickness = 3
confirmStroke.Parent = confirmFrame

-- 확인 텍스트
local confirmText = Instance.new("TextLabel")
confirmText.Name = "ConfirmText"
confirmText.Size = UDim2.new(1, -20, 0, 50)
confirmText.Position = UDim2.new(0, 10, 0, 20)
confirmText.BackgroundTransparency = 1
confirmText.TextColor3 = COLORS.gold
confirmText.Text = "정말 나가시겠습니까?"
confirmText.TextSize = 20
confirmText.Font = Enum.Font.GothamBold
confirmText.Parent = confirmFrame

-- 예 버튼
local yesButton = Instance.new("TextButton")
yesButton.Name = "YesButton"
yesButton.Size = UDim2.new(0, 100, 0, 40)
yesButton.Position = UDim2.new(0.5, -110, 1, -60)
yesButton.BackgroundColor3 = COLORS.red
yesButton.TextColor3 = COLORS.gold
yesButton.Text = "나가기"
yesButton.TextSize = 16
yesButton.Font = Enum.Font.GothamBold
yesButton.Parent = confirmFrame

local yesCorner = Instance.new("UICorner")
yesCorner.CornerRadius = UDim.new(0, 8)
yesCorner.Parent = yesButton

-- 아니오 버튼
local noButton = Instance.new("TextButton")
noButton.Name = "NoButton"
noButton.Size = UDim2.new(0, 100, 0, 40)
noButton.Position = UDim2.new(0.5, 10, 1, -60)
noButton.BackgroundColor3 = COLORS.gold
noButton.TextColor3 = COLORS.black
noButton.Text = "취소"
noButton.TextSize = 16
noButton.Font = Enum.Font.GothamBold
noButton.Parent = confirmFrame

local noCorner = Instance.new("UICorner")
noCorner.CornerRadius = UDim.new(0, 8)
noCorner.Parent = noButton

-- 나가기 버튼 클릭 시 확인 다이얼로그 표시
leaveButton.MouseButton1Click:Connect(function()
	confirmFrame.Visible = true
end)

-- 예 버튼 클릭 시 로비로 이동
yesButton.MouseButton1Click:Connect(function()
	yesButton.Text = "이동 중..."
	TeleportService:Teleport(LOBBY_PLACE_ID, player)
end)

-- 아니오 버튼 클릭 시 다이얼로그 숨기기
noButton.MouseButton1Click:Connect(function()
	confirmFrame.Visible = false
end)

-- 호버 효과
leaveButton.MouseEnter:Connect(function()
	leaveButton.BackgroundColor3 = COLORS.red
end)

leaveButton.MouseLeave:Connect(function()
	leaveButton.BackgroundColor3 = COLORS.woodDark
end)
