local TeleportService = game:GetService("TeleportService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local screenGui = script.Parent

-- 설정
local LOBBY_PLACE_ID = 18517272972

-- 해적 테마 색상
local COLORS = {
	woodDark = Color3.fromRGB(62, 39, 22),
	woodLight = Color3.fromRGB(90, 60, 35),
	gold = Color3.fromRGB(255, 200, 50),
	goldDark = Color3.fromRGB(180, 140, 30),
	red = Color3.fromRGB(180, 50, 50),
	redDark = Color3.fromRGB(120, 30, 30),
	green = Color3.fromRGB(50, 150, 80),
	black = Color3.fromRGB(20, 15, 10),
	white = Color3.fromRGB(255, 255, 255),
}

-- 나가기 버튼 (좌측 하단, 원형 아이콘 스타일)
local leaveButton = Instance.new("ImageButton")
leaveButton.Name = "LeaveButton"
leaveButton.Size = UDim2.new(0, 56, 0, 56)
leaveButton.Position = UDim2.new(0, 20, 1, -76)
leaveButton.BackgroundColor3 = COLORS.woodDark
leaveButton.Image = ""
leaveButton.AutoButtonColor = false
leaveButton.Parent = screenGui

local buttonCorner = Instance.new("UICorner")
buttonCorner.CornerRadius = UDim.new(0.5, 0)
buttonCorner.Parent = leaveButton

local buttonStroke = Instance.new("UIStroke")
buttonStroke.Color = COLORS.gold
buttonStroke.Thickness = 3
buttonStroke.Parent = leaveButton

-- 문 아이콘 (텍스트로 대체)
local doorIcon = Instance.new("TextLabel")
doorIcon.Name = "DoorIcon"
doorIcon.Size = UDim2.new(1, 0, 1, 0)
doorIcon.BackgroundTransparency = 1
doorIcon.Text = "🚪"
doorIcon.TextSize = 28
doorIcon.Font = Enum.Font.GothamBold
doorIcon.TextColor3 = COLORS.gold
doorIcon.Parent = leaveButton

-- 그림자 효과
local shadow = Instance.new("Frame")
shadow.Name = "Shadow"
shadow.Size = UDim2.new(1, 4, 1, 4)
shadow.Position = UDim2.new(0, 2, 0, 2)
shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
shadow.BackgroundTransparency = 0.5
shadow.ZIndex = -1
shadow.Parent = leaveButton

local shadowCorner = Instance.new("UICorner")
shadowCorner.CornerRadius = UDim.new(0.5, 0)
shadowCorner.Parent = shadow

-- 확인 다이얼로그 (반투명 배경)
local overlay = Instance.new("Frame")
overlay.Name = "Overlay"
overlay.Size = UDim2.new(1, 0, 1, 0)
overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
overlay.BackgroundTransparency = 0.6
overlay.Visible = false
overlay.ZIndex = 10
overlay.Parent = screenGui

local confirmFrame = Instance.new("Frame")
confirmFrame.Name = "ConfirmFrame"
confirmFrame.Size = UDim2.new(0, 320, 0, 180)
confirmFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
confirmFrame.AnchorPoint = Vector2.new(0.5, 0.5)
confirmFrame.BackgroundColor3 = COLORS.woodDark
confirmFrame.ZIndex = 11
confirmFrame.Parent = overlay

local confirmCorner = Instance.new("UICorner")
confirmCorner.CornerRadius = UDim.new(0, 16)
confirmCorner.Parent = confirmFrame

local confirmStroke = Instance.new("UIStroke")
confirmStroke.Color = COLORS.gold
confirmStroke.Thickness = 3
confirmStroke.Parent = confirmFrame

-- 상단 장식 바
local topBar = Instance.new("Frame")
topBar.Name = "TopBar"
topBar.Size = UDim2.new(1, 0, 0, 40)
topBar.BackgroundColor3 = COLORS.woodLight
topBar.ZIndex = 12
topBar.Parent = confirmFrame

local topBarCorner = Instance.new("UICorner")
topBarCorner.CornerRadius = UDim.new(0, 16)
topBarCorner.Parent = topBar

-- 하단 모서리 가리기
local topBarFix = Instance.new("Frame")
topBarFix.Size = UDim2.new(1, 0, 0, 20)
topBarFix.Position = UDim2.new(0, 0, 1, -20)
topBarFix.BackgroundColor3 = COLORS.woodLight
topBarFix.BorderSizePixel = 0
topBarFix.ZIndex = 12
topBarFix.Parent = topBar

-- 타이틀
local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "Title"
titleLabel.Size = UDim2.new(1, 0, 1, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "⚓ 로비로 돌아가기"
titleLabel.TextColor3 = COLORS.gold
titleLabel.TextSize = 18
titleLabel.Font = Enum.Font.GothamBold
titleLabel.ZIndex = 13
titleLabel.Parent = topBar

-- 확인 텍스트
local confirmText = Instance.new("TextLabel")
confirmText.Name = "ConfirmText"
confirmText.Size = UDim2.new(1, -20, 0, 40)
confirmText.Position = UDim2.new(0, 10, 0, 55)
confirmText.BackgroundTransparency = 1
confirmText.TextColor3 = COLORS.white
confirmText.Text = "정말 게임을 나가시겠습니까?"
confirmText.TextSize = 16
confirmText.Font = Enum.Font.Gotham
confirmText.ZIndex = 12
confirmText.Parent = confirmFrame

-- 버튼 컨테이너
local buttonContainer = Instance.new("Frame")
buttonContainer.Name = "ButtonContainer"
buttonContainer.Size = UDim2.new(1, -40, 0, 50)
buttonContainer.Position = UDim2.new(0, 20, 1, -70)
buttonContainer.BackgroundTransparency = 1
buttonContainer.ZIndex = 12
buttonContainer.Parent = confirmFrame

local buttonLayout = Instance.new("UIListLayout")
buttonLayout.FillDirection = Enum.FillDirection.Horizontal
buttonLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
buttonLayout.Padding = UDim.new(0, 20)
buttonLayout.Parent = buttonContainer

-- 예 버튼
local yesButton = Instance.new("TextButton")
yesButton.Name = "YesButton"
yesButton.Size = UDim2.new(0, 120, 0, 44)
yesButton.BackgroundColor3 = COLORS.red
yesButton.TextColor3 = COLORS.white
yesButton.Text = "나가기"
yesButton.TextSize = 16
yesButton.Font = Enum.Font.GothamBold
yesButton.AutoButtonColor = false
yesButton.ZIndex = 13
yesButton.Parent = buttonContainer

local yesCorner = Instance.new("UICorner")
yesCorner.CornerRadius = UDim.new(0, 10)
yesCorner.Parent = yesButton

local yesStroke = Instance.new("UIStroke")
yesStroke.Color = COLORS.redDark
yesStroke.Thickness = 2
yesStroke.Parent = yesButton

-- 아니오 버튼
local noButton = Instance.new("TextButton")
noButton.Name = "NoButton"
noButton.Size = UDim2.new(0, 120, 0, 44)
noButton.BackgroundColor3 = COLORS.green
noButton.TextColor3 = COLORS.white
noButton.Text = "계속하기"
noButton.TextSize = 16
noButton.Font = Enum.Font.GothamBold
noButton.AutoButtonColor = false
noButton.ZIndex = 13
noButton.Parent = buttonContainer

local noCorner = Instance.new("UICorner")
noCorner.CornerRadius = UDim.new(0, 10)
noCorner.Parent = noButton

local noStroke = Instance.new("UIStroke")
noStroke.Color = Color3.fromRGB(30, 100, 50)
noStroke.Thickness = 2
noStroke.Parent = noButton

-- 애니메이션 함수
local function tweenButton(button, targetColor)
	local tween = TweenService:Create(button, TweenInfo.new(0.15), {BackgroundColor3 = targetColor})
	tween:Play()
end

-- 다이얼로그 표시 애니메이션
local function showDialog()
	overlay.Visible = true
	confirmFrame.Size = UDim2.new(0, 0, 0, 0)
	confirmFrame.Position = UDim2.new(0.5, 0, 0.5, 0)

	local tween = TweenService:Create(confirmFrame, TweenInfo.new(0.2, Enum.EasingStyle.Back), {
		Size = UDim2.new(0, 320, 0, 180)
	})
	tween:Play()
end

local function hideDialog()
	local tween = TweenService:Create(confirmFrame, TweenInfo.new(0.15), {
		Size = UDim2.new(0, 0, 0, 0)
	})
	tween:Play()
	tween.Completed:Wait()
	overlay.Visible = false
end

-- 나가기 버튼 클릭
leaveButton.MouseButton1Click:Connect(function()
	showDialog()
end)

-- 호버 효과 (나가기 버튼)
leaveButton.MouseEnter:Connect(function()
	tweenButton(leaveButton, COLORS.woodLight)
	buttonStroke.Color = COLORS.white
end)

leaveButton.MouseLeave:Connect(function()
	tweenButton(leaveButton, COLORS.woodDark)
	buttonStroke.Color = COLORS.gold
end)

-- 예 버튼
yesButton.MouseButton1Click:Connect(function()
	yesButton.Text = "이동 중..."

	-- Studio에서는 텔레포트 불가
	local RunService = game:GetService("RunService")
	if RunService:IsStudio() then
		warn("[LeaveGameGui] Studio에서는 텔레포트할 수 없습니다.")
		yesButton.Text = "Studio 불가"
		task.wait(1)
		yesButton.Text = "나가기"
		hideDialog()
		return
	end

	TeleportService:Teleport(LOBBY_PLACE_ID, player)
end)

yesButton.MouseEnter:Connect(function()
	tweenButton(yesButton, COLORS.redDark)
end)

yesButton.MouseLeave:Connect(function()
	tweenButton(yesButton, COLORS.red)
end)

-- 아니오 버튼
noButton.MouseButton1Click:Connect(function()
	hideDialog()
end)

noButton.MouseEnter:Connect(function()
	tweenButton(noButton, Color3.fromRGB(30, 100, 50))
end)

noButton.MouseLeave:Connect(function()
	tweenButton(noButton, COLORS.green)
end)

-- 오버레이 클릭 시 닫기
overlay.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		-- 다이얼로그 외부 클릭 시 닫기
		local mousePos = input.Position
		local framePos = confirmFrame.AbsolutePosition
		local frameSize = confirmFrame.AbsoluteSize

		if mousePos.X < framePos.X or mousePos.X > framePos.X + frameSize.X or
		   mousePos.Y < framePos.Y or mousePos.Y > framePos.Y + frameSize.Y then
			hideDialog()
		end
	end
end)
