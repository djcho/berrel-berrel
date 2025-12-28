-- ShopGui: 상점 UI 클라이언트 스크립트
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local screenGui = script.Parent

print("[ShopGui] 스크립트 시작")

-- RemoteFunction/Event 참조
print("[ShopGui] ShopSystem 대기 중...")
local ShopSystem = ReplicatedStorage:WaitForChild("ShopSystem", 30)
if not ShopSystem then
	warn("[ShopGui] ShopSystem을 찾을 수 없습니다!")
	return
end
print("[ShopGui] ShopSystem 찾음")

local UnlockBarrel = ShopSystem:WaitForChild("UnlockBarrel", 10)
local UpgradeBarrel = ShopSystem:WaitForChild("UpgradeBarrel", 10)
local GetPlayerShopData = ShopSystem:WaitForChild("GetPlayerShopData", 10)
print("[ShopGui] Remote Functions 찾음, OpenShopEvent 대기 중...")

-- OpenShopEvent는 ShopNpcService에서 생성되므로 더 긴 타임아웃 사용
local OpenShopEvent = ShopSystem:WaitForChild("OpenShopEvent", 30)

if not OpenShopEvent then
	warn("[ShopGui] OpenShopEvent를 찾을 수 없습니다!")
	return
end
print("[ShopGui] 모든 RemoteEvent/Function 찾음")

-- 색상 설정 (해적 테마)
local COLORS = {
	woodDark = Color3.fromRGB(62, 39, 22),
	woodLight = Color3.fromRGB(90, 60, 35),
	gold = Color3.fromRGB(255, 200, 50),
	goldDark = Color3.fromRGB(180, 140, 30),
	red = Color3.fromRGB(180, 50, 50),
	green = Color3.fromRGB(50, 150, 80),
	blue = Color3.fromRGB(50, 100, 180),
	black = Color3.fromRGB(20, 15, 10),
	white = Color3.fromRGB(255, 255, 255),
	parchment = Color3.fromRGB(240, 220, 180),
	locked = Color3.fromRGB(100, 100, 100),
}

-- 업그레이드 타입 한글명
local UPGRADE_NAMES = {
	Damage = "데미지",
	Range = "사거리",
	Cooldown = "재장전",
	MaxShots = "보유량",
}

local shopData = nil
local currentGold = 0
local selectedBarrel = nil
local isOpen = false

-- 메인 오버레이 (반투명 배경)
local overlay = Instance.new("Frame")
overlay.Name = "Overlay"
overlay.Size = UDim2.new(1, 0, 1, 0)
overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
overlay.BackgroundTransparency = 0.5
overlay.Visible = false
overlay.ZIndex = 10
overlay.Parent = screenGui

-- 메인 프레임
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 700, 0, 500)
mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mainFrame.BackgroundColor3 = COLORS.woodDark
mainFrame.ZIndex = 11
mainFrame.Parent = overlay

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 16)
mainCorner.Parent = mainFrame

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = COLORS.gold
mainStroke.Thickness = 3
mainStroke.Parent = mainFrame

-- 상단 바 (타이틀)
local topBar = Instance.new("Frame")
topBar.Name = "TopBar"
topBar.Size = UDim2.new(1, 0, 0, 50)
topBar.BackgroundColor3 = COLORS.woodLight
topBar.ZIndex = 12
topBar.Parent = mainFrame

local topBarCorner = Instance.new("UICorner")
topBarCorner.CornerRadius = UDim.new(0, 16)
topBarCorner.Parent = topBar

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
titleLabel.Size = UDim2.new(0.6, 0, 1, 0)
titleLabel.Position = UDim2.new(0, 20, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "⚓ 통 상점"
titleLabel.TextColor3 = COLORS.gold
titleLabel.TextSize = 24
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.ZIndex = 13
titleLabel.Parent = topBar

-- 골드 표시
local goldLabel = Instance.new("TextLabel")
goldLabel.Name = "GoldLabel"
goldLabel.Size = UDim2.new(0, 150, 0, 30)
goldLabel.Position = UDim2.new(1, -170, 0.5, -15)
goldLabel.BackgroundColor3 = COLORS.goldDark
goldLabel.TextColor3 = COLORS.white
goldLabel.Text = "🪙 0"
goldLabel.TextSize = 18
goldLabel.Font = Enum.Font.GothamBold
goldLabel.ZIndex = 13
goldLabel.Parent = topBar

local goldCorner = Instance.new("UICorner")
goldCorner.CornerRadius = UDim.new(0, 8)
goldCorner.Parent = goldLabel

-- 닫기 버튼
local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.Size = UDim2.new(0, 40, 0, 40)
closeButton.Position = UDim2.new(1, -45, 0.5, -20)
closeButton.BackgroundColor3 = COLORS.red
closeButton.Text = "X"
closeButton.TextColor3 = COLORS.white
closeButton.TextSize = 20
closeButton.Font = Enum.Font.GothamBold
closeButton.AutoButtonColor = false
closeButton.ZIndex = 13
closeButton.Parent = topBar

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 8)
closeCorner.Parent = closeButton

-- 왼쪽 패널 (통 목록)
local leftPanel = Instance.new("Frame")
leftPanel.Name = "LeftPanel"
leftPanel.Size = UDim2.new(0, 200, 1, -60)
leftPanel.Position = UDim2.new(0, 10, 0, 55)
leftPanel.BackgroundColor3 = COLORS.woodLight
leftPanel.BackgroundTransparency = 0.3
leftPanel.ZIndex = 12
leftPanel.Parent = mainFrame

local leftCorner = Instance.new("UICorner")
leftCorner.CornerRadius = UDim.new(0, 10)
leftCorner.Parent = leftPanel

-- 통 목록 스크롤 프레임
local barrelList = Instance.new("ScrollingFrame")
barrelList.Name = "BarrelList"
barrelList.Size = UDim2.new(1, -10, 1, -10)
barrelList.Position = UDim2.new(0, 5, 0, 5)
barrelList.BackgroundTransparency = 1
barrelList.ScrollBarThickness = 6
barrelList.CanvasSize = UDim2.new(0, 0, 0, 0)
barrelList.ZIndex = 13
barrelList.Parent = leftPanel

local barrelListLayout = Instance.new("UIListLayout")
barrelListLayout.Padding = UDim.new(0, 5)
barrelListLayout.Parent = barrelList

-- 오른쪽 패널 (상세 정보)
local rightPanel = Instance.new("Frame")
rightPanel.Name = "RightPanel"
rightPanel.Size = UDim2.new(1, -230, 1, -60)
rightPanel.Position = UDim2.new(0, 220, 0, 55)
rightPanel.BackgroundColor3 = COLORS.woodLight
rightPanel.BackgroundTransparency = 0.3
rightPanel.ZIndex = 12
rightPanel.Parent = mainFrame

local rightCorner = Instance.new("UICorner")
rightCorner.CornerRadius = UDim.new(0, 10)
rightCorner.Parent = rightPanel

-- 상세 정보 컨테이너
local detailContainer = Instance.new("Frame")
detailContainer.Name = "DetailContainer"
detailContainer.Size = UDim2.new(1, -20, 1, -20)
detailContainer.Position = UDim2.new(0, 10, 0, 10)
detailContainer.BackgroundTransparency = 1
detailContainer.ZIndex = 13
detailContainer.Parent = rightPanel

-- 선택된 통 이름
local selectedBarrelLabel = Instance.new("TextLabel")
selectedBarrelLabel.Name = "SelectedBarrelLabel"
selectedBarrelLabel.Size = UDim2.new(1, 0, 0, 40)
selectedBarrelLabel.BackgroundTransparency = 1
selectedBarrelLabel.Text = "통을 선택하세요"
selectedBarrelLabel.TextColor3 = COLORS.gold
selectedBarrelLabel.TextSize = 22
selectedBarrelLabel.Font = Enum.Font.GothamBold
selectedBarrelLabel.ZIndex = 14
selectedBarrelLabel.Parent = detailContainer

-- 해금 버튼
local unlockButton = Instance.new("TextButton")
unlockButton.Name = "UnlockButton"
unlockButton.Size = UDim2.new(1, 0, 0, 45)
unlockButton.Position = UDim2.new(0, 0, 0, 45)
unlockButton.BackgroundColor3 = COLORS.green
unlockButton.Text = "해금하기 (0G)"
unlockButton.TextColor3 = COLORS.white
unlockButton.TextSize = 18
unlockButton.Font = Enum.Font.GothamBold
unlockButton.AutoButtonColor = false
unlockButton.Visible = false
unlockButton.ZIndex = 14
unlockButton.Parent = detailContainer

local unlockCorner = Instance.new("UICorner")
unlockCorner.CornerRadius = UDim.new(0, 10)
unlockCorner.Parent = unlockButton

-- 스탯 표시 영역
local statsFrame = Instance.new("Frame")
statsFrame.Name = "StatsFrame"
statsFrame.Size = UDim2.new(1, 0, 0, 80)
statsFrame.Position = UDim2.new(0, 0, 0, 50)
statsFrame.BackgroundTransparency = 1
statsFrame.Visible = false
statsFrame.ZIndex = 14
statsFrame.Parent = detailContainer

-- 업그레이드 영역
local upgradeFrame = Instance.new("Frame")
upgradeFrame.Name = "UpgradeFrame"
upgradeFrame.Size = UDim2.new(1, 0, 0, 250)
upgradeFrame.Position = UDim2.new(0, 0, 0, 135)
upgradeFrame.BackgroundTransparency = 1
upgradeFrame.Visible = false
upgradeFrame.ZIndex = 14
upgradeFrame.Parent = detailContainer

local upgradeLayout = Instance.new("UIListLayout")
upgradeLayout.Padding = UDim.new(0, 8)
upgradeLayout.Parent = upgradeFrame

-- 메시지 라벨 (구매 결과 등)
local messageLabel = Instance.new("TextLabel")
messageLabel.Name = "MessageLabel"
messageLabel.Size = UDim2.new(1, 0, 0, 30)
messageLabel.Position = UDim2.new(0, 0, 1, -35)
messageLabel.BackgroundTransparency = 1
messageLabel.Text = ""
messageLabel.TextColor3 = COLORS.gold
messageLabel.TextSize = 16
messageLabel.Font = Enum.Font.Gotham
messageLabel.ZIndex = 14
messageLabel.Parent = detailContainer

-- 통 아이템 버튼 생성 함수
local function createBarrelButton(barrelName, data)
	local button = Instance.new("TextButton")
	button.Name = barrelName
	button.Size = UDim2.new(1, -10, 0, 60)
	button.BackgroundColor3 = data.isUnlocked and COLORS.woodDark or COLORS.locked
	button.AutoButtonColor = false
	button.Text = ""
	button.ZIndex = 14
	button.Parent = barrelList

	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(0, 8)
	buttonCorner.Parent = button

	local buttonStroke = Instance.new("UIStroke")
	buttonStroke.Color = data.isUnlocked and COLORS.gold or COLORS.locked
	buttonStroke.Thickness = 2
	buttonStroke.Parent = button

	-- 아이콘
	local icon = Instance.new("ImageLabel")
	icon.Size = UDim2.new(0, 50, 0, 50)
	icon.Position = UDim2.new(0, 5, 0.5, -25)
	icon.BackgroundTransparency = 1
	icon.Image = data.iconId
	icon.ZIndex = 15
	icon.Parent = button

	-- 이름
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.new(1, -60, 0, 25)
	nameLabel.Position = UDim2.new(0, 60, 0, 5)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = data.displayName
	nameLabel.TextColor3 = data.isUnlocked and COLORS.white or COLORS.locked
	nameLabel.TextSize = 14
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.ZIndex = 15
	nameLabel.Parent = button

	-- 상태
	local statusLabel = Instance.new("TextLabel")
	statusLabel.Name = "StatusLabel"
	statusLabel.Size = UDim2.new(1, -60, 0, 20)
	statusLabel.Position = UDim2.new(0, 60, 0, 30)
	statusLabel.BackgroundTransparency = 1
	statusLabel.Text = data.isUnlocked and "해금됨" or (data.unlockPrice .. "G")
	statusLabel.TextColor3 = data.isUnlocked and COLORS.green or COLORS.goldDark
	statusLabel.TextSize = 12
	statusLabel.Font = Enum.Font.Gotham
	statusLabel.TextXAlignment = Enum.TextXAlignment.Left
	statusLabel.ZIndex = 15
	statusLabel.Parent = button

	-- 클릭 이벤트
	button.MouseButton1Click:Connect(function()
		selectBarrel(barrelName)
	end)

	-- 호버 효과 (선택된 상태가 아닐 때만)
	button.MouseEnter:Connect(function()
		if selectedBarrel ~= barrelName then
			TweenService:Create(button, TweenInfo.new(0.15), {
				BackgroundColor3 = COLORS.woodLight
			}):Play()
		end
	end)

	button.MouseLeave:Connect(function()
		if selectedBarrel ~= barrelName then
			TweenService:Create(button, TweenInfo.new(0.15), {
				BackgroundColor3 = data.isUnlocked and COLORS.woodDark or COLORS.locked
			}):Play()
		end
	end)

	return button
end

-- 업그레이드 행 생성 함수
local function createUpgradeRow(upgradeType, currentLevel, maxLevel, nextPrice, barrelName)
	local row = Instance.new("Frame")
	row.Name = upgradeType
	row.Size = UDim2.new(1, 0, 0, 50)
	row.BackgroundColor3 = COLORS.woodDark
	row.ZIndex = 15
	row.Parent = upgradeFrame

	local rowCorner = Instance.new("UICorner")
	rowCorner.CornerRadius = UDim.new(0, 8)
	rowCorner.Parent = row

	-- 업그레이드 이름
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(0, 100, 1, 0)
	nameLabel.Position = UDim2.new(0, 10, 0, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = UPGRADE_NAMES[upgradeType] or upgradeType
	nameLabel.TextColor3 = COLORS.white
	nameLabel.TextSize = 14
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.ZIndex = 16
	nameLabel.Parent = row

	-- 레벨 표시
	local levelLabel = Instance.new("TextLabel")
	levelLabel.Size = UDim2.new(0, 80, 1, 0)
	levelLabel.Position = UDim2.new(0, 110, 0, 0)
	levelLabel.BackgroundTransparency = 1
	levelLabel.Text = "Lv." .. currentLevel .. "/" .. maxLevel
	levelLabel.TextColor3 = currentLevel >= maxLevel and COLORS.gold or COLORS.parchment
	levelLabel.TextSize = 14
	levelLabel.Font = Enum.Font.Gotham
	levelLabel.ZIndex = 16
	levelLabel.Parent = row

	-- 업그레이드 버튼
	local upgradeBtn = Instance.new("TextButton")
	upgradeBtn.Size = UDim2.new(0, 100, 0, 35)
	upgradeBtn.Position = UDim2.new(1, -110, 0.5, -17.5)
	upgradeBtn.BackgroundColor3 = currentLevel >= maxLevel and COLORS.locked or COLORS.green
	upgradeBtn.Text = currentLevel >= maxLevel and "MAX" or (nextPrice .. "G")
	upgradeBtn.TextColor3 = COLORS.white
	upgradeBtn.TextSize = 14
	upgradeBtn.Font = Enum.Font.GothamBold
	upgradeBtn.AutoButtonColor = false
	upgradeBtn.ZIndex = 16
	upgradeBtn.Parent = row

	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 6)
	btnCorner.Parent = upgradeBtn

	if currentLevel < maxLevel then
		upgradeBtn.MouseButton1Click:Connect(function()
			local result = UpgradeBarrel:InvokeServer(barrelName, upgradeType)
			showMessage(result.message, result.success)
			if result.success then
				refreshShopData()
			end
		end)

		upgradeBtn.MouseEnter:Connect(function()
			TweenService:Create(upgradeBtn, TweenInfo.new(0.15), {
				BackgroundColor3 = Color3.fromRGB(40, 120, 60)
			}):Play()
		end)

		upgradeBtn.MouseLeave:Connect(function()
			TweenService:Create(upgradeBtn, TweenInfo.new(0.15), {
				BackgroundColor3 = COLORS.green
			}):Play()
		end)
	end

	return row
end

-- 스탯 표시 업데이트
local function updateStatsDisplay(barrelName)
	-- 기존 스탯 라벨 제거
	for _, child in ipairs(statsFrame:GetChildren()) do
		child:Destroy()
	end

	local data = shopData.barrels[barrelName]
	if not data or not data.currentStats then return end

	local stats = data.currentStats
	local statsText = string.format(
		"데미지: %d  |  사거리: %d  |  재장전: %.1f초  |  보유량: %d",
		stats.Damage, stats.MaxRange, stats.ReloadTime, stats.MaxShots
	)

	local statsLabel = Instance.new("TextLabel")
	statsLabel.Size = UDim2.new(1, 0, 1, 0)
	statsLabel.BackgroundColor3 = COLORS.woodDark
	statsLabel.Text = statsText
	statsLabel.TextColor3 = COLORS.parchment
	statsLabel.TextSize = 14
	statsLabel.Font = Enum.Font.Gotham
	statsLabel.TextWrapped = true
	statsLabel.ZIndex = 15
	statsLabel.Parent = statsFrame

	local statsCorner = Instance.new("UICorner")
	statsCorner.CornerRadius = UDim.new(0, 8)
	statsCorner.Parent = statsLabel
end

-- 업그레이드 영역 업데이트
local function updateUpgradeDisplay(barrelName)
	-- 기존 업그레이드 행 제거
	for _, child in ipairs(upgradeFrame:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	local data = shopData.barrels[barrelName]
	if not data then return end

	local upgradeConfig = shopData.upgradeConfig

	for upgradeType, config in pairs(upgradeConfig) do
		local currentLevel = data.upgrades[upgradeType] or 0
		local maxLevel, prices

		-- MaxShots는 배럴별 설정 사용
		if upgradeType == "MaxShots" and config.perBarrel then
			local perBarrelConfig = config.perBarrel[barrelName]
			if perBarrelConfig then
				maxLevel = perBarrelConfig.maxLevel
				prices = perBarrelConfig.prices
			else
				maxLevel = 0
				prices = {}
			end
		else
			maxLevel = config.maxLevel
			prices = config.prices
		end

		local nextPrice = currentLevel < maxLevel and prices[currentLevel + 1] or 0
		createUpgradeRow(upgradeType, currentLevel, maxLevel, nextPrice, barrelName)
	end
end

-- 선택된 통 버튼 강조 업데이트
local function updateBarrelButtonSelection()
	for _, child in ipairs(barrelList:GetChildren()) do
		if child:IsA("TextButton") then
			local isSelected = child.Name == selectedBarrel
			local data = shopData and shopData.barrels[child.Name]
			local stroke = child:FindFirstChildOfClass("UIStroke")

			if isSelected then
				-- 선택된 통: 밝은 배경 + 두꺼운 골드 테두리
				child.BackgroundColor3 = COLORS.gold
				if stroke then
					stroke.Color = COLORS.white
					stroke.Thickness = 3
				end
				-- 텍스트 색상도 변경
				for _, label in ipairs(child:GetChildren()) do
					if label:IsA("TextLabel") and label.Name ~= "StatusLabel" then
						label.TextColor3 = COLORS.black
					end
				end
			else
				-- 선택되지 않은 통: 원래 색상으로 복원
				local isUnlocked = data and data.isUnlocked
				child.BackgroundColor3 = isUnlocked and COLORS.woodDark or COLORS.locked
				if stroke then
					stroke.Color = isUnlocked and COLORS.gold or COLORS.locked
					stroke.Thickness = 2
				end
				-- 텍스트 색상 복원
				for _, label in ipairs(child:GetChildren()) do
					if label:IsA("TextLabel") then
						if label.Name == "NameLabel" then
							label.TextColor3 = isUnlocked and COLORS.white or COLORS.locked
						end
					end
				end
			end
		end
	end
end

-- 통 선택
function selectBarrel(barrelName)
	selectedBarrel = barrelName
	local data = shopData.barrels[barrelName]

	if not data then return end

	-- 선택 상태 시각적 업데이트
	updateBarrelButtonSelection()

	selectedBarrelLabel.Text = data.displayName

	if data.isUnlocked then
		unlockButton.Visible = false
		statsFrame.Visible = true
		statsFrame.Position = UDim2.new(0, 0, 0, 45)
		upgradeFrame.Visible = true
		upgradeFrame.Position = UDim2.new(0, 0, 0, 130)

		updateStatsDisplay(barrelName)
		updateUpgradeDisplay(barrelName)
	else
		unlockButton.Visible = true
		unlockButton.Text = "해금하기 (" .. data.unlockPrice .. "G)"
		statsFrame.Visible = false
		upgradeFrame.Visible = false
	end
end

-- 메시지 표시
function showMessage(msg, success)
	messageLabel.Text = msg
	messageLabel.TextColor3 = success and COLORS.green or COLORS.red

	-- 3초 후 메시지 사라짐
	task.delay(3, function()
		if messageLabel.Text == msg then
			messageLabel.Text = ""
		end
	end)
end

-- 상점 데이터 새로고침
function refreshShopData()
	local result = GetPlayerShopData:InvokeServer()
	if result then
		currentGold = result.gold
		shopData = result.shopData
		goldLabel.Text = "🪙 " .. currentGold

		-- 통 목록 새로고침
		for _, child in ipairs(barrelList:GetChildren()) do
			if child:IsA("TextButton") then
				child:Destroy()
			end
		end

		for barrelName, data in pairs(shopData.barrels) do
			createBarrelButton(barrelName, data)
		end

		-- 캔버스 크기 업데이트
		barrelList.CanvasSize = UDim2.new(0, 0, 0, barrelListLayout.AbsoluteContentSize.Y + 10)

		-- 선택된 통 다시 표시
		if selectedBarrel then
			selectBarrel(selectedBarrel)
		end
	end
end

-- 상점 열기
local function openShop()
	if isOpen then return end
	isOpen = true

	refreshShopData()

	-- 기본 통 선택 (selectedBarrel이 없으면 NormalBarrel 선택)
	if not selectedBarrel and shopData and shopData.barrels then
		if shopData.barrels["NormalBarrel"] then
			selectBarrel("NormalBarrel")
		else
			-- NormalBarrel이 없으면 첫 번째 통 선택
			for barrelName, _ in pairs(shopData.barrels) do
				selectBarrel(barrelName)
				break
			end
		end
	end

	overlay.Visible = true
	mainFrame.Size = UDim2.new(0, 0, 0, 0)

	TweenService:Create(mainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Back), {
		Size = UDim2.new(0, 700, 0, 500)
	}):Play()
end

-- 상점 닫기
local function closeShop()
	if not isOpen then return end

	local tween = TweenService:Create(mainFrame, TweenInfo.new(0.15), {
		Size = UDim2.new(0, 0, 0, 0)
	})
	tween:Play()
	tween.Completed:Wait()

	overlay.Visible = false
	isOpen = false
	selectedBarrel = nil
end

-- 이벤트 연결
closeButton.MouseButton1Click:Connect(closeShop)

closeButton.MouseEnter:Connect(function()
	TweenService:Create(closeButton, TweenInfo.new(0.15), {
		BackgroundColor3 = Color3.fromRGB(120, 30, 30)
	}):Play()
end)

closeButton.MouseLeave:Connect(function()
	TweenService:Create(closeButton, TweenInfo.new(0.15), {
		BackgroundColor3 = COLORS.red
	}):Play()
end)

-- 해금 버튼 클릭
unlockButton.MouseButton1Click:Connect(function()
	if not selectedBarrel then return end

	local result = UnlockBarrel:InvokeServer(selectedBarrel)
	showMessage(result.message, result.success)
	if result.success then
		refreshShopData()
	end
end)

unlockButton.MouseEnter:Connect(function()
	TweenService:Create(unlockButton, TweenInfo.new(0.15), {
		BackgroundColor3 = Color3.fromRGB(40, 120, 60)
	}):Play()
end)

unlockButton.MouseLeave:Connect(function()
	TweenService:Create(unlockButton, TweenInfo.new(0.15), {
		BackgroundColor3 = COLORS.green
	}):Play()
end)

-- 오버레이 클릭 시 닫기
overlay.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		local mousePos = input.Position
		local framePos = mainFrame.AbsolutePosition
		local frameSize = mainFrame.AbsoluteSize

		if mousePos.X < framePos.X or mousePos.X > framePos.X + frameSize.X or
		   mousePos.Y < framePos.Y or mousePos.Y > framePos.Y + frameSize.Y then
			closeShop()
		end
	end
end)

-- 서버 이벤트 수신
OpenShopEvent.OnClientEvent:Connect(function()
	print("[ShopGui] OpenShopEvent 수신됨!")
	openShop()
end)

-- 골드 변경 감지 (실시간 업데이트)
local leaderstats = player:WaitForChild("leaderstats")
local coins = leaderstats:WaitForChild("Coins")
coins.Changed:Connect(function(newValue)
	currentGold = newValue
	goldLabel.Text = "🪙 " .. currentGold
end)

print("[ShopGui] 초기화 완료")
