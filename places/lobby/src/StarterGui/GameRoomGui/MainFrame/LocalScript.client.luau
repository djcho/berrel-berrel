local replicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local mainFrame = script.Parent

-- 해적 컨셉 색상
local COLORS = {
	woodDark = Color3.fromRGB(62, 39, 22),
	woodLight = Color3.fromRGB(101, 67, 33),
	gold = Color3.fromRGB(255, 200, 50),
	goldDark = Color3.fromRGB(180, 140, 30),
	parchment = Color3.fromRGB(210, 180, 140),
	rope = Color3.fromRGB(139, 119, 83),
	red = Color3.fromRGB(200, 60, 60),
	black = Color3.fromRGB(20, 15, 10),
	green = Color3.fromRGB(50, 180, 50),
	blue = Color3.fromRGB(70, 130, 180),
	teamRed = Color3.fromRGB(255, 100, 100),
	teamBlue = Color3.fromRGB(100, 150, 255),
	white = Color3.fromRGB(255, 255, 255),
}

-- 방 데이터 캐시 (서버에서 liveStatus 포함해서 전송)
local roomDataCache = {}

-- 게임 모드 아이콘 (서버에서 받은 모드에 따라 다른 아이콘 사용)
local GAME_MODE_ICONS = {
	deathmatch = "rbxassetid://110698591776828",
	-- 추후 다른 모드 추가
	-- capture = "rbxassetid://...",
	-- survival = "rbxassetid://...",
}
local TITLE_ICON = "rbxassetid://131431773353571" -- 게임 참가 타이틀 아이콘

-- 메인 프레임 스타일 적용
mainFrame.BackgroundColor3 = COLORS.woodDark

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 16)
mainCorner.Parent = mainFrame

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = COLORS.goldDark
mainStroke.Thickness = 4
mainStroke.Parent = mainFrame

-- 시간 포맷 함수
local function formatTime(seconds)
	local mins = math.floor(seconds / 60)
	local secs = math.floor(seconds % 60)
	return string.format("%d:%02d", mins, secs)
end

-- GUI 요소 참조 저장
local guiElements = {}

-- GUI 요소 동적 생성
local function createGuiElements()
	-- 상단 바
	local topBar = Instance.new("Frame")
	topBar.Name = "TopBar"
	topBar.Size = UDim2.new(1, 0, 0, 60)
	topBar.Position = UDim2.new(0, 0, 0, 0)
	topBar.BackgroundColor3 = COLORS.woodLight
	topBar.BorderSizePixel = 0
	topBar.Parent = mainFrame

	local topBarCorner = Instance.new("UICorner")
	topBarCorner.CornerRadius = UDim.new(0, 16)
	topBarCorner.Parent = topBar

	-- 타이틀 아이콘 (게임 참가 아이콘)
	local titleIcon = Instance.new("ImageLabel")
	titleIcon.Size = UDim2.new(0, 40, 0, 40)
	titleIcon.Position = UDim2.new(0, 12, 0, 10)
	titleIcon.BackgroundTransparency = 1
	titleIcon.Image = TITLE_ICON
	titleIcon.Parent = topBar

	-- 타이틀
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "TitleLabel"
	titleLabel.Size = UDim2.new(0, 200, 0, 30)
	titleLabel.Position = UDim2.new(0, 50, 0, 8)
	titleLabel.BackgroundTransparency = 1
	titleLabel.TextColor3 = COLORS.gold
	titleLabel.Text = "게임 참가"
	titleLabel.TextSize = 24
	titleLabel.Font = Enum.Font.GothamBlack
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Parent = topBar

	-- 서브타이틀
	local subTitleLabel = Instance.new("TextLabel")
	subTitleLabel.Size = UDim2.new(0, 200, 0, 20)
	subTitleLabel.Position = UDim2.new(0, 50, 0, 36)
	subTitleLabel.BackgroundTransparency = 1
	subTitleLabel.TextColor3 = COLORS.parchment
	subTitleLabel.Text = "방을 선택하세요"
	subTitleLabel.TextSize = 13
	subTitleLabel.Font = Enum.Font.GothamBold
	subTitleLabel.TextXAlignment = Enum.TextXAlignment.Left
	subTitleLabel.Parent = topBar

	-- 닫기 버튼
	local closeButton = Instance.new("TextButton")
	closeButton.Name = "CloseButton"
	closeButton.Size = UDim2.new(0, 40, 0, 40)
	closeButton.Position = UDim2.new(1, -50, 0, 10)
	closeButton.BackgroundColor3 = COLORS.red
	closeButton.TextColor3 = COLORS.white
	closeButton.Text = "X"
	closeButton.TextSize = 22
	closeButton.Font = Enum.Font.GothamBlack
	closeButton.Parent = topBar

	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 10)
	closeCorner.Parent = closeButton

	-- 요약 정보 바
	local summaryBar = Instance.new("Frame")
	summaryBar.Name = "SummaryBar"
	summaryBar.Size = UDim2.new(1, -40, 0, 70)
	summaryBar.Position = UDim2.new(0, 20, 0, 70)
	summaryBar.BackgroundColor3 = COLORS.black
	summaryBar.BackgroundTransparency = 0.3
	summaryBar.Parent = mainFrame

	local summaryCorner = Instance.new("UICorner")
	summaryCorner.CornerRadius = UDim.new(0, 12)
	summaryCorner.Parent = summaryBar

	-- 총 방 수
	local roomCountFrame = Instance.new("Frame")
	roomCountFrame.Size = UDim2.new(0.33, 0, 1, 0)
	roomCountFrame.Position = UDim2.new(0, 0, 0, 0)
	roomCountFrame.BackgroundTransparency = 1
	roomCountFrame.Parent = summaryBar

	local roomCountLabel = Instance.new("TextLabel")
	roomCountLabel.Name = "RoomCountLabel"
	roomCountLabel.Size = UDim2.new(1, 0, 0, 35)
	roomCountLabel.Position = UDim2.new(0, 0, 0, 8)
	roomCountLabel.BackgroundTransparency = 1
	roomCountLabel.TextColor3 = COLORS.gold
	roomCountLabel.Text = "0"
	roomCountLabel.TextSize = 28
	roomCountLabel.Font = Enum.Font.GothamBlack
	roomCountLabel.Parent = roomCountFrame
	guiElements.roomCountLabel = roomCountLabel

	local roomCountText = Instance.new("TextLabel")
	roomCountText.Size = UDim2.new(1, 0, 0, 20)
	roomCountText.Position = UDim2.new(0, 0, 0, 42)
	roomCountText.BackgroundTransparency = 1
	roomCountText.TextColor3 = COLORS.parchment
	roomCountText.Text = "열린 방"
	roomCountText.TextSize = 12
	roomCountText.Font = Enum.Font.GothamBold
	roomCountText.Parent = roomCountFrame

	-- 총 플레이어 수
	local playerCountFrame = Instance.new("Frame")
	playerCountFrame.Size = UDim2.new(0.33, 0, 1, 0)
	playerCountFrame.Position = UDim2.new(0.33, 0, 0, 0)
	playerCountFrame.BackgroundTransparency = 1
	playerCountFrame.Parent = summaryBar

	local playerCountLabel = Instance.new("TextLabel")
	playerCountLabel.Name = "PlayerCountLabel"
	playerCountLabel.Size = UDim2.new(1, 0, 0, 35)
	playerCountLabel.Position = UDim2.new(0, 0, 0, 8)
	playerCountLabel.BackgroundTransparency = 1
	playerCountLabel.TextColor3 = COLORS.green
	playerCountLabel.Text = "0"
	playerCountLabel.TextSize = 28
	playerCountLabel.Font = Enum.Font.GothamBlack
	playerCountLabel.Parent = playerCountFrame
	guiElements.playerCountLabel = playerCountLabel

	local playerCountText = Instance.new("TextLabel")
	playerCountText.Size = UDim2.new(1, 0, 0, 20)
	playerCountText.Position = UDim2.new(0, 0, 0, 42)
	playerCountText.BackgroundTransparency = 1
	playerCountText.TextColor3 = COLORS.parchment
	playerCountText.Text = "플레이 중"
	playerCountText.TextSize = 12
	playerCountText.Font = Enum.Font.GothamBold
	playerCountText.Parent = playerCountFrame

	-- 게임 중인 방 수
	local activeCountFrame = Instance.new("Frame")
	activeCountFrame.Size = UDim2.new(0.33, 0, 1, 0)
	activeCountFrame.Position = UDim2.new(0.66, 0, 0, 0)
	activeCountFrame.BackgroundTransparency = 1
	activeCountFrame.Parent = summaryBar

	local activeCountLabel = Instance.new("TextLabel")
	activeCountLabel.Name = "ActiveCountLabel"
	activeCountLabel.Size = UDim2.new(1, 0, 0, 35)
	activeCountLabel.Position = UDim2.new(0, 0, 0, 8)
	activeCountLabel.BackgroundTransparency = 1
	activeCountLabel.TextColor3 = COLORS.teamRed
	activeCountLabel.Text = "0"
	activeCountLabel.TextSize = 28
	activeCountLabel.Font = Enum.Font.GothamBlack
	activeCountLabel.Parent = activeCountFrame
	guiElements.activeCountLabel = activeCountLabel

	local activeCountText = Instance.new("TextLabel")
	activeCountText.Size = UDim2.new(1, 0, 0, 20)
	activeCountText.Position = UDim2.new(0, 0, 0, 42)
	activeCountText.BackgroundTransparency = 1
	activeCountText.TextColor3 = COLORS.parchment
	activeCountText.Text = "게임 중"
	activeCountText.TextSize = 12
	activeCountText.Font = Enum.Font.GothamBold
	activeCountText.Parent = activeCountFrame

	-- 컨텐츠 영역
	local contentFrame = Instance.new("Frame")
	contentFrame.Name = "ContentFrame"
	contentFrame.Size = UDim2.new(1, -40, 1, -230)
	contentFrame.Position = UDim2.new(0, 20, 0, 150)
	contentFrame.BackgroundColor3 = COLORS.parchment
	contentFrame.BackgroundTransparency = 0.3
	contentFrame.BorderSizePixel = 0
	contentFrame.Parent = mainFrame

	local contentCorner = Instance.new("UICorner")
	contentCorner.CornerRadius = UDim.new(0, 12)
	contentCorner.Parent = contentFrame

	-- 방 목록 스크롤 프레임
	local roomListScroll = Instance.new("ScrollingFrame")
	roomListScroll.Name = "RoomListScroll"
	roomListScroll.Size = UDim2.new(1, -16, 1, -16)
	roomListScroll.Position = UDim2.new(0, 8, 0, 8)
	roomListScroll.BackgroundTransparency = 1
	roomListScroll.BorderSizePixel = 0
	roomListScroll.ScrollBarThickness = 6
	roomListScroll.ScrollBarImageColor3 = COLORS.gold
	roomListScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	roomListScroll.Parent = contentFrame

	local roomListLayout = Instance.new("UIGridLayout")
	roomListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	roomListLayout.CellSize = UDim2.new(0, 280, 0, 380) -- 카드 크기 대폭 확대
	roomListLayout.CellPadding = UDim2.new(0, 20, 0, 20)
	roomListLayout.FillDirection = Enum.FillDirection.Horizontal
	roomListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	roomListLayout.Parent = roomListScroll

	-- 하단 버튼 영역
	local bottomBar = Instance.new("Frame")
	bottomBar.Name = "BottomBar"
	bottomBar.Size = UDim2.new(1, -40, 0, 60)
	bottomBar.Position = UDim2.new(0, 20, 1, -70)
	bottomBar.BackgroundTransparency = 1
	bottomBar.Parent = mainFrame

	-- 빠른 참가 버튼 (크게)
	local quickJoinButton = Instance.new("TextButton")
	quickJoinButton.Name = "QuickJoinButton"
	quickJoinButton.Size = UDim2.new(0.65, -5, 1, 0)
	quickJoinButton.Position = UDim2.new(0, 0, 0, 0)
	quickJoinButton.BackgroundColor3 = COLORS.gold
	quickJoinButton.TextColor3 = COLORS.black
	quickJoinButton.Text = "빠른 참가"
	quickJoinButton.TextSize = 22
	quickJoinButton.Font = Enum.Font.GothamBlack
	quickJoinButton.Parent = bottomBar

	local quickCorner = Instance.new("UICorner")
	quickCorner.CornerRadius = UDim.new(0, 12)
	quickCorner.Parent = quickJoinButton

	local quickStroke = Instance.new("UIStroke")
	quickStroke.Color = COLORS.goldDark
	quickStroke.Thickness = 3
	quickStroke.Parent = quickJoinButton

	-- 새로고침 버튼
	local refreshButton = Instance.new("TextButton")
	refreshButton.Name = "RefreshButton"
	refreshButton.Size = UDim2.new(0.35, -5, 1, 0)
	refreshButton.Position = UDim2.new(0.65, 5, 0, 0)
	refreshButton.BackgroundColor3 = COLORS.woodLight
	refreshButton.TextColor3 = COLORS.gold
	refreshButton.Text = "새로고침"
	refreshButton.TextSize = 18
	refreshButton.Font = Enum.Font.GothamBold
	refreshButton.Parent = bottomBar

	local refreshCorner = Instance.new("UICorner")
	refreshCorner.CornerRadius = UDim.new(0, 12)
	refreshCorner.Parent = refreshButton

	local refreshStroke = Instance.new("UIStroke")
	refreshStroke.Color = COLORS.goldDark
	refreshStroke.Thickness = 2
	refreshStroke.Parent = refreshButton

	return closeButton, quickJoinButton, refreshButton, roomListScroll
end

-- GUI 요소 생성
local closeButton, quickJoinButton, refreshButton, roomListScroll = createGuiElements()

-- 입장 확인 다이얼로그 상태
local selectedRoomId = nil
local confirmDialog = nil

-- 입장 확인 다이얼로그 생성
local function createConfirmDialog()
	local dialog = Instance.new("Frame")
	dialog.Name = "ConfirmDialog"
	dialog.Size = UDim2.new(1, 0, 1, 0)
	dialog.Position = UDim2.new(0, 0, 0, 0)
	dialog.BackgroundColor3 = COLORS.black
	dialog.BackgroundTransparency = 0.5
	dialog.Visible = false
	dialog.ZIndex = 10
	dialog.Parent = mainFrame

	local dialogBox = Instance.new("Frame")
	dialogBox.Size = UDim2.new(0, 300, 0, 180)
	dialogBox.Position = UDim2.new(0.5, -150, 0.5, -90)
	dialogBox.BackgroundColor3 = COLORS.woodDark
	dialogBox.ZIndex = 11
	dialogBox.Parent = dialog

	local boxCorner = Instance.new("UICorner")
	boxCorner.CornerRadius = UDim.new(0, 16)
	boxCorner.Parent = dialogBox

	local boxStroke = Instance.new("UIStroke")
	boxStroke.Color = COLORS.goldDark
	boxStroke.Thickness = 3
	boxStroke.Parent = dialogBox

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.Size = UDim2.new(1, 0, 0, 40)
	titleLabel.Position = UDim2.new(0, 0, 0, 15)
	titleLabel.BackgroundTransparency = 1
	titleLabel.TextColor3 = COLORS.gold
	titleLabel.Text = "게임에 참가하시겠습니까?"
	titleLabel.TextSize = 18
	titleLabel.Font = Enum.Font.GothamBlack
	titleLabel.ZIndex = 12
	titleLabel.Parent = dialogBox

	local infoLabel = Instance.new("TextLabel")
	infoLabel.Name = "Info"
	infoLabel.Size = UDim2.new(1, -20, 0, 50)
	infoLabel.Position = UDim2.new(0, 10, 0, 55)
	infoLabel.BackgroundTransparency = 1
	infoLabel.TextColor3 = COLORS.parchment
	infoLabel.Text = ""
	infoLabel.TextSize = 14
	infoLabel.Font = Enum.Font.GothamBold
	infoLabel.TextWrapped = true
	infoLabel.ZIndex = 12
	infoLabel.Parent = dialogBox

	local confirmBtn = Instance.new("TextButton")
	confirmBtn.Name = "ConfirmBtn"
	confirmBtn.Size = UDim2.new(0, 120, 0, 40)
	confirmBtn.Position = UDim2.new(0, 25, 1, -55)
	confirmBtn.BackgroundColor3 = COLORS.green
	confirmBtn.TextColor3 = COLORS.white
	confirmBtn.Text = "확인"
	confirmBtn.TextSize = 16
	confirmBtn.Font = Enum.Font.GothamBlack
	confirmBtn.ZIndex = 12
	confirmBtn.Parent = dialogBox

	local confirmCorner = Instance.new("UICorner")
	confirmCorner.CornerRadius = UDim.new(0, 10)
	confirmCorner.Parent = confirmBtn

	local cancelBtn = Instance.new("TextButton")
	cancelBtn.Name = "CancelBtn"
	cancelBtn.Size = UDim2.new(0, 120, 0, 40)
	cancelBtn.Position = UDim2.new(1, -145, 1, -55)
	cancelBtn.BackgroundColor3 = COLORS.red
	cancelBtn.TextColor3 = COLORS.white
	cancelBtn.Text = "취소"
	cancelBtn.TextSize = 16
	cancelBtn.Font = Enum.Font.GothamBlack
	cancelBtn.ZIndex = 12
	cancelBtn.Parent = dialogBox

	local cancelCorner = Instance.new("UICorner")
	cancelCorner.CornerRadius = UDim.new(0, 10)
	cancelCorner.Parent = cancelBtn

	-- 버튼 이벤트
	confirmBtn.MouseButton1Click:Connect(function()
		if selectedRoomId then
			dialog.Visible = false
			replicatedStorage:WaitForChild("JoinGameRoom"):FireServer(selectedRoomId)
		end
	end)

	cancelBtn.MouseButton1Click:Connect(function()
		dialog.Visible = false
		selectedRoomId = nil
	end)

	return dialog
end

-- 다이얼로그 표시
local function showConfirmDialog(roomId, roomData, liveData)
	if not confirmDialog then
		confirmDialog = createConfirmDialog()
	end

	selectedRoomId = roomId
	local gameMode = liveData and liveData.gameMode or "deathmatch"
	local gameState = liveData and liveData.gameState or "waiting"
	local playerCount = liveData and liveData.playerCount or #roomData.players
	local maxPlayers = roomData.maxPlayersCount or 16

	local stateText = gameState == "playing" and "게임 중" or gameState == "starting" and "시작 대기 중" or "대기 중"
	local infoText = string.format("모드: 팀 데스매치\n상태: %s\n인원: %d / %d", stateText, playerCount, maxPlayers)

	confirmDialog:FindFirstChild("ConfirmDialog") -- unused
	local dialogBox = confirmDialog:FindFirstChildOfClass("Frame")
	if dialogBox then
		local infoLabel = dialogBox:FindFirstChild("Info")
		if infoLabel then
			infoLabel.Text = infoText
		end
	end

	confirmDialog.Visible = true
end

-- 방 카드 생성 함수 (새 디자인 - 카드 형태)
local function createRoomCard(roomId, roomData, liveData, index)
	local playerCount = liveData and liveData.playerCount or #roomData.players
	local maxPlayers = roomData.maxPlayersCount or 16
	local isFull = playerCount >= maxPlayers
	local gameState = liveData and liveData.gameState or "waiting"
	local gameMode = liveData and liveData.gameMode or "deathmatch"

	-- 카드 전체를 버튼으로 생성 (UIGridLayout이 크기 제어)
	local card = Instance.new("TextButton")
	card.Name = "Room_" .. roomId
	card.BackgroundColor3 = COLORS.woodDark
	card.BorderSizePixel = 0
	card.LayoutOrder = index
	card.Text = ""
	card.AutoButtonColor = false

	local cardCorner = Instance.new("UICorner")
	cardCorner.CornerRadius = UDim.new(0, 12)
	cardCorner.Parent = card

	local cardStroke = Instance.new("UIStroke")
	cardStroke.Color = COLORS.goldDark
	cardStroke.Thickness = 2
	cardStroke.Parent = card

	-- 상단: 게임 상태 배지
	local statusBadge = Instance.new("Frame")
	statusBadge.Size = UDim2.new(1, -24, 0, 36)
	statusBadge.Position = UDim2.new(0, 12, 0, 12)
	statusBadge.BackgroundColor3 = gameState == "playing" and COLORS.green or gameState == "starting" and COLORS.gold or gameState == "ended" and COLORS.red or COLORS.blue
	statusBadge.Parent = card

	local badgeCorner = Instance.new("UICorner")
	badgeCorner.CornerRadius = UDim.new(0, 10)
	badgeCorner.Parent = statusBadge

	local statusLabel = Instance.new("TextLabel")
	statusLabel.Size = UDim2.new(1, 0, 1, 0)
	statusLabel.BackgroundTransparency = 1
	statusLabel.TextColor3 = COLORS.white
	statusLabel.Font = Enum.Font.GothamBold
	statusLabel.TextSize = 18
	statusLabel.Parent = statusBadge

	-- 상태별 텍스트
	if gameState == "playing" then
		local remaining = liveData and liveData.matchTimeRemaining or 0
		statusLabel.Text = "게임 중 " .. formatTime(remaining)
	elseif gameState == "starting" then
		local countdown = liveData and liveData.countdownTime or 0
		statusLabel.Text = countdown .. "초 후 시작"
	elseif gameState == "ended" then
		local endCountdown = liveData and liveData.endCountdown or 0
		statusLabel.Text = endCountdown .. "초 후 재시작"
	else
		-- 대기 중
		if liveData and liveData.canStart then
			statusLabel.Text = "곧 시작!"
			statusBadge.BackgroundColor3 = COLORS.green
		else
			statusLabel.Text = "대기 중"
		end
	end

	-- 중앙: 큰 게임 모드 아이콘 (대폭 확대)
	local iconSize = 180
	local modeIcon = Instance.new("ImageLabel")
	modeIcon.Size = UDim2.new(0, iconSize, 0, iconSize)
	modeIcon.Position = UDim2.new(0.5, -iconSize/2, 0, 60)
	modeIcon.BackgroundTransparency = 1
	modeIcon.Image = GAME_MODE_ICONS[gameMode] or GAME_MODE_ICONS.deathmatch
	modeIcon.Parent = card

	-- 아이콘 아래: 게임 모드 이름
	local modeLabel = Instance.new("TextLabel")
	modeLabel.Size = UDim2.new(1, 0, 0, 30)
	modeLabel.Position = UDim2.new(0, 0, 0, 250)
	modeLabel.BackgroundTransparency = 1
	modeLabel.TextColor3 = COLORS.gold
	modeLabel.Text = "팀 데스매치"
	modeLabel.TextSize = 20
	modeLabel.Font = Enum.Font.GothamBlack
	modeLabel.Parent = card

	-- 하단: 정보 영역
	local infoFrame = Instance.new("Frame")
	infoFrame.Size = UDim2.new(1, -24, 0, 80)
	infoFrame.Position = UDim2.new(0, 12, 1, -92)
	infoFrame.BackgroundColor3 = COLORS.black
	infoFrame.BackgroundTransparency = 0.5
	infoFrame.Parent = card

	local infoCorner = Instance.new("UICorner")
	infoCorner.CornerRadius = UDim.new(0, 12)
	infoCorner.Parent = infoFrame

	-- 인원 수
	local playerLabel = Instance.new("TextLabel")
	playerLabel.Size = UDim2.new(1, 0, 0, 36)
	playerLabel.Position = UDim2.new(0, 0, 0, 8)
	playerLabel.BackgroundTransparency = 1
	playerLabel.TextColor3 = isFull and COLORS.red or COLORS.gold
	playerLabel.Text = string.format("👤 %d / %d", playerCount, maxPlayers)
	playerLabel.TextSize = 22
	playerLabel.Font = Enum.Font.GothamBlack
	playerLabel.Parent = infoFrame

	-- 추가 정보 (팀 인원, 스코어 등)
	local detailLabel = Instance.new("TextLabel")
	detailLabel.Size = UDim2.new(1, 0, 0, 28)
	detailLabel.Position = UDim2.new(0, 0, 0, 44)
	detailLabel.BackgroundTransparency = 1
	detailLabel.TextColor3 = COLORS.parchment
	detailLabel.TextSize = 16
	detailLabel.Font = Enum.Font.GothamBold
	detailLabel.Parent = infoFrame

	if gameState == "playing" and liveData then
		local teamAScore = liveData.teamScores and liveData.teamScores.TeamA or 0
		local teamBScore = liveData.teamScores and liveData.teamScores.TeamB or 0
		detailLabel.Text = string.format("🔴 %d vs %d 🔵", teamAScore, teamBScore)
	elseif liveData then
		local teamCounts = liveData.teamCounts or {}
		local teamA = teamCounts.TeamA or 0
		local teamB = teamCounts.TeamB or 0
		detailLabel.Text = string.format("🔴 %d명  🔵 %d명", teamA, teamB)
	else
		detailLabel.Text = isFull and "방이 가득 찼습니다" or "클릭하여 참가"
	end

	-- 카드 클릭 이벤트 (입장 확인 다이얼로그 표시)
	if not isFull then
		card.MouseButton1Click:Connect(function()
			showConfirmDialog(roomId, roomData, liveData)
		end)

		card.MouseEnter:Connect(function()
			card.BackgroundColor3 = COLORS.woodLight
			cardStroke.Color = COLORS.gold
			cardStroke.Thickness = 3
		end)
		card.MouseLeave:Connect(function()
			card.BackgroundColor3 = COLORS.woodDark
			cardStroke.Color = COLORS.goldDark
			cardStroke.Thickness = 2
		end)
	else
		-- 만석인 경우 어둡게 표시
		card.BackgroundColor3 = COLORS.rope
		modeIcon.ImageTransparency = 0.5
	end

	return card
end

-- 요약 정보 업데이트
local function updateSummary(rooms)
	local roomCount = 0
	local totalPlayers = 0
	local activeGames = 0

	for _, roomData in pairs(rooms) do
		roomCount = roomCount + 1
		local liveStatus = roomData.liveStatus
		local playerCount = liveStatus and liveStatus.playerCount or #roomData.players
		local gameState = liveStatus and liveStatus.gameState or "waiting"

		totalPlayers = totalPlayers + playerCount
		if gameState == "playing" then
			activeGames = activeGames + 1
		end
	end

	guiElements.roomCountLabel.Text = tostring(roomCount)
	guiElements.playerCountLabel.Text = tostring(totalPlayers)
	guiElements.activeCountLabel.Text = tostring(activeGames)
end

-- 방 목록 업데이트
local function updateRoomList(rooms)
	-- 방 데이터 캐시 업데이트
	roomDataCache = rooms

	-- 기존 방 카드 제거
	for _, child in ipairs(roomListScroll:GetChildren()) do
		if child:IsA("TextButton") or child:IsA("TextLabel") then
			child:Destroy()
		end
	end

	-- 요약 정보 업데이트
	updateSummary(rooms)

	local index = 1
	local hasRooms = false

	for roomId, roomData in pairs(rooms) do
		hasRooms = true
		-- roomData.liveStatus를 직접 사용 (서버에서 합쳐서 전송)
		local liveData = roomData.liveStatus
		local card = createRoomCard(roomId, roomData, liveData, index)
		card.Parent = roomListScroll
		index = index + 1
	end

	-- 방이 없을 때 메시지 표시
	if not hasRooms then
		local noRoomFrame = Instance.new("Frame")
		noRoomFrame.Size = UDim2.new(1, 0, 0, 100)
		noRoomFrame.BackgroundTransparency = 1
		noRoomFrame.Parent = roomListScroll

		local noRoomIcon = Instance.new("TextLabel")
		noRoomIcon.Size = UDim2.new(1, 0, 0, 40)
		noRoomIcon.Position = UDim2.new(0, 0, 0, 10)
		noRoomIcon.BackgroundTransparency = 1
		noRoomIcon.TextColor3 = COLORS.woodDark
		noRoomIcon.Text = "🚫"
		noRoomIcon.TextSize = 32
		noRoomIcon.Parent = noRoomFrame

		local noRoomLabel = Instance.new("TextLabel")
		noRoomLabel.Size = UDim2.new(1, 0, 0, 40)
		noRoomLabel.Position = UDim2.new(0, 0, 0, 50)
		noRoomLabel.BackgroundTransparency = 1
		noRoomLabel.TextColor3 = COLORS.woodDark
		noRoomLabel.Text = "현재 열린 방이 없습니다.\n빠른 참가를 눌러 새 게임을 시작하세요!"
		noRoomLabel.TextSize = 14
		noRoomLabel.Font = Enum.Font.GothamBold
		noRoomLabel.TextWrapped = true
		noRoomLabel.Parent = noRoomFrame
	end

	-- 스크롤 캔버스 크기 업데이트 (그리드 레이아웃)
	-- 카드 크기: 280x380, 패딩: 20
	-- 스크롤 영역 너비에 따라 한 행에 들어가는 카드 수 계산
	local scrollWidth = roomListScroll.AbsoluteSize.X
	local cardWidth = 280 + 20 -- 카드 너비 + 패딩
	local cardsPerRow = math.max(1, math.floor(scrollWidth / cardWidth))
	local rowCount = math.ceil((index - 1) / cardsPerRow)
	local cardHeight = 380 + 20 -- 카드 높이 + 패딩
	roomListScroll.CanvasSize = UDim2.new(0, 0, 0, rowCount * cardHeight)
end

-- 서버에서 방 목록 요청
local function requestRoomList()
	replicatedStorage:WaitForChild("RequestGameList"):FireServer()
end

-- 빠른 참가
local isJoining = false
quickJoinButton.MouseButton1Click:Connect(function()
	if isJoining then return end
	isJoining = true
	quickJoinButton.Text = "매칭 중..."
	quickJoinButton.BackgroundColor3 = COLORS.rope

	-- 펄스 애니메이션
	local tween = TweenService:Create(quickJoinButton, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
		BackgroundTransparency = 0.3
	})
	tween:Play()
	quickJoinButton:SetAttribute("PulseTween", true)

	local quickJoinEvent = replicatedStorage:FindFirstChild("QuickJoin")
	if quickJoinEvent then
		quickJoinEvent:FireServer()
	end
end)

quickJoinButton.MouseEnter:Connect(function()
	if not isJoining then
		quickJoinButton.BackgroundColor3 = COLORS.goldDark
	end
end)
quickJoinButton.MouseLeave:Connect(function()
	if not isJoining then
		quickJoinButton.BackgroundColor3 = COLORS.gold
	end
end)

-- 새로고침
refreshButton.MouseButton1Click:Connect(function()
	refreshButton.Text = "로딩..."
	refreshButton.BackgroundColor3 = COLORS.rope
	requestRoomList()
	task.delay(1, function()
		refreshButton.Text = "새로고침"
		refreshButton.BackgroundColor3 = COLORS.woodLight
	end)
end)

refreshButton.MouseEnter:Connect(function()
	refreshButton.BackgroundColor3 = COLORS.goldDark
end)
refreshButton.MouseLeave:Connect(function()
	refreshButton.BackgroundColor3 = COLORS.woodLight
end)

-- 닫기
closeButton.MouseButton1Click:Connect(function()
	mainFrame.Visible = false
	isJoining = false
	quickJoinButton.Text = "빠른 참가"
	quickJoinButton.BackgroundColor3 = COLORS.gold
	quickJoinButton.BackgroundTransparency = 0
end)

closeButton.MouseEnter:Connect(function()
	closeButton.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
end)
closeButton.MouseLeave:Connect(function()
	closeButton.BackgroundColor3 = COLORS.red
end)

-- 서버로부터 방 목록 수신
replicatedStorage:WaitForChild("UpdateGameList").OnClientEvent:Connect(function(rooms)
	updateRoomList(rooms)
end)

-- 서버로부터 매칭 상태 수신
local matchStatusEvent = replicatedStorage:WaitForChild("MatchStatus", 5)
if matchStatusEvent then
	matchStatusEvent.OnClientEvent:Connect(function(data)
		if data.status == "matched" then
			quickJoinButton.Text = "입장!"
			quickJoinButton.BackgroundColor3 = COLORS.green
			quickJoinButton.BackgroundTransparency = 0
		elseif data.status == "matching" then
			quickJoinButton.Text = string.format("매칭 중... (%d/%d)", data.playerCount or 0, data.maxPlayers or 16)
		elseif data.status == "error" then
			isJoining = false
			quickJoinButton.Text = "빠른 참가"
			quickJoinButton.BackgroundColor3 = COLORS.gold
			quickJoinButton.BackgroundTransparency = 0
		end
	end)
end

-- 실시간 게임 상태 수신 (Pirate에서 MessagingService로 전송)
local liveMatchEvent = replicatedStorage:WaitForChild("LiveMatchUpdate", 5)
if liveMatchEvent then
	liveMatchEvent.OnClientEvent:Connect(function(data)
		if data and data.roomId then
			-- 캐시된 방 데이터에 실시간 상태 업데이트
			if roomDataCache[data.roomId] then
				roomDataCache[data.roomId].liveStatus = data
				-- 캐시된 데이터로 UI 업데이트 (서버 요청 없이)
				updateRoomList(roomDataCache)
			else
				-- 캐시에 없으면 서버에서 전체 목록 다시 요청
				requestRoomList()
			end
		end
	end)
end

-- GUI 표시될 때 방 목록 요청
replicatedStorage:WaitForChild("ShowGameRoomGui").OnClientEvent:Connect(function()
	mainFrame.Visible = true
	isJoining = false
	quickJoinButton.Text = "빠른 참가"
	quickJoinButton.BackgroundColor3 = COLORS.gold
	quickJoinButton.BackgroundTransparency = 0
	requestRoomList()
end)

-- 초기 방 목록 요청
if mainFrame.Visible then
	requestRoomList()
end

print("[GameRoomGui] 초기화 완료")
