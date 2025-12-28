-- 스튜디오 전용 디버그 메뉴
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- 스튜디오에서만 실행
if not RunService:IsStudio() then
	return
end

local player = Players.LocalPlayer
local screenGui = script.Parent

-- 색상 테마
local COLORS = {
	bg = Color3.fromRGB(30, 30, 35),
	bgLight = Color3.fromRGB(45, 45, 50),
	accent = Color3.fromRGB(100, 180, 255),
	danger = Color3.fromRGB(255, 100, 100),
	success = Color3.fromRGB(100, 255, 130),
	warning = Color3.fromRGB(255, 200, 100),
	text = Color3.fromRGB(255, 255, 255),
	textDim = Color3.fromRGB(180, 180, 180),
}

-- 메인 프레임
local mainFrame = Instance.new("Frame")
mainFrame.Name = "DebugFrame"
mainFrame.Size = UDim2.new(0, 250, 0, 400)
mainFrame.Position = UDim2.new(0, 10, 0.5, -200)
mainFrame.BackgroundColor3 = COLORS.bg
mainFrame.BackgroundTransparency = 0.1
mainFrame.Visible = false
mainFrame.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 8)
mainCorner.Parent = mainFrame

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = COLORS.accent
mainStroke.Thickness = 2
mainStroke.Parent = mainFrame

-- 토글 버튼
local toggleButton = Instance.new("TextButton")
toggleButton.Name = "DebugToggle"
toggleButton.Size = UDim2.new(0, 40, 0, 40)
toggleButton.Position = UDim2.new(0, 10, 0.5, -20)
toggleButton.BackgroundColor3 = COLORS.bg
toggleButton.Text = "D"
toggleButton.TextColor3 = COLORS.accent
toggleButton.TextSize = 20
toggleButton.Font = Enum.Font.GothamBlack
toggleButton.Parent = screenGui

local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0, 8)
toggleCorner.Parent = toggleButton

local toggleStroke = Instance.new("UIStroke")
toggleStroke.Color = COLORS.accent
toggleStroke.Thickness = 2
toggleStroke.Parent = toggleButton

-- 헤더
local header = Instance.new("TextLabel")
header.Size = UDim2.new(1, 0, 0, 40)
header.BackgroundColor3 = COLORS.bgLight
header.BackgroundTransparency = 0.5
header.TextColor3 = COLORS.accent
header.Text = "디버그 메뉴"
header.TextSize = 20
header.Font = Enum.Font.GothamBlack
header.Parent = mainFrame

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 8)
headerCorner.Parent = header

-- 스크롤 프레임
local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(1, -20, 1, -50)
scrollFrame.Position = UDim2.new(0, 10, 0, 45)
scrollFrame.BackgroundTransparency = 1
scrollFrame.ScrollBarThickness = 4
scrollFrame.ScrollBarImageColor3 = COLORS.accent
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
scrollFrame.Parent = mainFrame

local listLayout = Instance.new("UIListLayout")
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 6)
listLayout.Parent = scrollFrame

-- 버튼 생성 함수
local function createButton(text, color, order)
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(1, 0, 0, 40)
	button.BackgroundColor3 = color
	button.BackgroundTransparency = 0.15
	button.Text = text
	button.TextColor3 = COLORS.text
	button.TextSize = 16
	button.Font = Enum.Font.GothamBold
	button.LayoutOrder = order
	button.Parent = scrollFrame

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = button

	button.MouseEnter:Connect(function()
		button.BackgroundTransparency = 0
	end)
	button.MouseLeave:Connect(function()
		button.BackgroundTransparency = 0.15
	end)

	return button
end

local function createSection(text, order)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0, 25)
	label.BackgroundTransparency = 1
	label.TextColor3 = COLORS.accent
	label.Text = "[ " .. text .. " ]"
	label.TextSize = 14
	label.Font = Enum.Font.GothamBold
	label.LayoutOrder = order
	label.Parent = scrollFrame
	return label
end

-- ===== 버튼 생성 =====
createSection("게임", 1)
local forceStartBtn = createButton("게임 강제 시작", COLORS.success, 2)
local showAnimBtn = createButton("시작 애니메이션", COLORS.accent, 3)
local endRedBtn = createButton("게임 종료 (RED 승리)", COLORS.danger, 4)
local endBlueBtn = createButton("게임 종료 (BLUE 승리)", COLORS.accent, 5)

createSection("플레이어", 10)
local healBtn = createButton("체력 회복", COLORS.success, 11)
local damageBtn = createButton("50 데미지", COLORS.danger, 12)
local killBtn = createButton("자살", COLORS.danger, 13)
local respawnBtn = createButton("리스폰", COLORS.accent, 14)
local godBtn = createButton("무적 모드", COLORS.warning, 15)

createSection("팀", 20)
local switchBtn = createButton("팀 변경", COLORS.accent, 21)

createSection("경제", 25)
local addGold100Btn = createButton("+100 골드", COLORS.warning, 26)
local addGold1000Btn = createButton("+1000 골드", COLORS.warning, 27)
local resetGoldBtn = createButton("골드 초기화", COLORS.danger, 28)

createSection("상태", 30)
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, 0, 0, 45)
statusLabel.BackgroundColor3 = COLORS.bgLight
statusLabel.BackgroundTransparency = 0.3
statusLabel.TextColor3 = COLORS.text
statusLabel.Text = "준비됨"
statusLabel.TextSize = 14
statusLabel.Font = Enum.Font.GothamBold
statusLabel.TextWrapped = true
statusLabel.LayoutOrder = 31
statusLabel.Parent = scrollFrame

local statusCorner = Instance.new("UICorner")
statusCorner.CornerRadius = UDim.new(0, 6)
statusCorner.Parent = statusLabel

local function updateStatus(msg)
	statusLabel.Text = os.date("%H:%M:%S") .. " " .. msg
end

local godModeEnabled = false

-- ===== 이벤트 =====
toggleButton.MouseButton1Click:Connect(function()
	mainFrame.Visible = not mainFrame.Visible
	toggleButton.Position = mainFrame.Visible and UDim2.new(0, 270, 0.5, -20) or UDim2.new(0, 10, 0.5, -20)
end)

forceStartBtn.MouseButton1Click:Connect(function()
	local e = ReplicatedStorage:FindFirstChild("DebugForceStart")
	if e then e:FireServer() updateStatus("게임 시작됨") else updateStatus("이벤트 없음") end
end)

showAnimBtn.MouseButton1Click:Connect(function()
	local e = ReplicatedStorage:FindFirstChild("DebugShowStartAnim")
	if e then e:FireServer() updateStatus("애니메이션 재생") else updateStatus("이벤트 없음") end
end)

endRedBtn.MouseButton1Click:Connect(function()
	local e = ReplicatedStorage:FindFirstChild("DebugEndGame")
	if e then e:FireServer("TeamA") updateStatus("RED 승리") else updateStatus("이벤트 없음") end
end)

endBlueBtn.MouseButton1Click:Connect(function()
	local e = ReplicatedStorage:FindFirstChild("DebugEndGame")
	if e then e:FireServer("TeamB") updateStatus("BLUE 승리") else updateStatus("이벤트 없음") end
end)

healBtn.MouseButton1Click:Connect(function()
	local h = player.Character and player.Character:FindFirstChild("Humanoid")
	if h then h.Health = h.MaxHealth updateStatus("체력 회복됨") end
end)

damageBtn.MouseButton1Click:Connect(function()
	local h = player.Character and player.Character:FindFirstChild("Humanoid")
	if h then h:TakeDamage(50) updateStatus("데미지 받음") end
end)

killBtn.MouseButton1Click:Connect(function()
	local h = player.Character and player.Character:FindFirstChild("Humanoid")
	if h then h.Health = 0 updateStatus("사망") end
end)

respawnBtn.MouseButton1Click:Connect(function()
	local e = ReplicatedStorage:FindFirstChild("DebugRespawn")
	if e then e:FireServer() updateStatus("리스폰됨") else updateStatus("이벤트 없음") end
end)

godBtn.MouseButton1Click:Connect(function()
	godModeEnabled = not godModeEnabled
	godBtn.Text = godModeEnabled and "무적 모드: ON" or "무적 모드"
	godBtn.BackgroundColor3 = godModeEnabled and COLORS.success or COLORS.warning
	updateStatus(godModeEnabled and "무적 ON" or "무적 OFF")
end)

task.spawn(function()
	while true do
		task.wait(0.1)
		if godModeEnabled then
			local h = player.Character and player.Character:FindFirstChild("Humanoid")
			if h then h.Health = h.MaxHealth end
		end
	end
end)

switchBtn.MouseButton1Click:Connect(function()
	local e = ReplicatedStorage:FindFirstChild("DebugSwitchTeam")
	if e then e:FireServer() updateStatus("팀 변경됨") else updateStatus("이벤트 없음") end
end)

addGold100Btn.MouseButton1Click:Connect(function()
	local e = ReplicatedStorage:FindFirstChild("DebugAddGold")
	if e then e:FireServer(100) updateStatus("+100 골드") else updateStatus("이벤트 없음") end
end)

addGold1000Btn.MouseButton1Click:Connect(function()
	local e = ReplicatedStorage:FindFirstChild("DebugAddGold")
	if e then e:FireServer(1000) updateStatus("+1000 골드") else updateStatus("이벤트 없음") end
end)

resetGoldBtn.MouseButton1Click:Connect(function()
	local e = ReplicatedStorage:FindFirstChild("DebugAddGold")
	if e then e:FireServer(-999999) updateStatus("골드 초기화") else updateStatus("이벤트 없음") end
end)

updateStatus("준비됨")
print("[StudioDebug] 로드 완료")
