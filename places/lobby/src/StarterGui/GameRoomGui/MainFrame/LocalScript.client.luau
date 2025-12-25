local replicatedStorage = game:GetService("ReplicatedStorage")
local mainFrame = script.Parent

-- GUI 요소 동적 생성
local function createGuiElements()
	-- GameList (ScrollingFrame) 생성
	local gameList = Instance.new("ScrollingFrame")
	gameList.Name = "GameList"
	gameList.Size = UDim2.new(1, -20, 1, -60)
	gameList.Position = UDim2.new(0, 10, 0, 50)
	gameList.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	gameList.BorderSizePixel = 0
	gameList.ScrollBarThickness = 6
	gameList.CanvasSize = UDim2.new(0, 0, 0, 0)
	gameList.AutomaticCanvasSize = Enum.AutomaticSize.Y
	gameList.Parent = mainFrame

	-- UIListLayout 추가
	local uiListLayout = Instance.new("UIListLayout")
	uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	uiListLayout.Padding = UDim.new(0, 10)
	uiListLayout.Parent = gameList

	-- CloseButton 생성
	local closeButton = Instance.new("TextButton")
	closeButton.Name = "CloseButton"
	closeButton.Size = UDim2.new(0, 30, 0, 30)
	closeButton.Position = UDim2.new(1, -40, 0, 10)
	closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeButton.Text = "X"
	closeButton.TextSize = 18
	closeButton.Font = Enum.Font.GothamBold
	closeButton.Parent = mainFrame

	-- 타이틀 생성
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "TitleLabel"
	titleLabel.Size = UDim2.new(1, -60, 0, 40)
	titleLabel.Position = UDim2.new(0, 10, 0, 5)
	titleLabel.BackgroundTransparency = 1
	titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	titleLabel.Text = "게임방 목록"
	titleLabel.TextSize = 24
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Parent = mainFrame

	return gameList, closeButton
end

-- 게임방 템플릿 동적 생성
local function createGameTemplate(room, layoutOrder)
	local frame = Instance.new("Frame")
	frame.Name = "GameTemplate"
	frame.Size = UDim2.new(1, -10, 0, 80)
	frame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	frame.BorderSizePixel = 0
	frame.LayoutOrder = layoutOrder

	-- 이미지
	local imageLabel = Instance.new("ImageLabel")
	imageLabel.Name = "ImageLabel"
	imageLabel.Size = UDim2.new(0, 60, 0, 60)
	imageLabel.Position = UDim2.new(0, 10, 0, 10)
	imageLabel.BackgroundTransparency = 1
	imageLabel.Image = "http://www.roblox.com/asset/?id=18548796224"
	imageLabel.Parent = frame

	-- 모드 타입
	local modeType = Instance.new("TextLabel")
	modeType.Name = "ModeType"
	modeType.Size = UDim2.new(0, 200, 0, 20)
	modeType.Position = UDim2.new(0, 80, 0, 10)
	modeType.BackgroundTransparency = 1
	modeType.TextColor3 = Color3.fromRGB(255, 255, 255)
	modeType.Text = "팀 데스매치 게임모드"
	modeType.TextSize = 14
	modeType.Font = Enum.Font.GothamBold
	modeType.TextXAlignment = Enum.TextXAlignment.Left
	modeType.Parent = frame

	-- 서버 이름
	local serverName = Instance.new("TextLabel")
	serverName.Name = "ServerName"
	serverName.Size = UDim2.new(0, 200, 0, 16)
	serverName.Position = UDim2.new(0, 80, 0, 32)
	serverName.BackgroundTransparency = 1
	serverName.TextColor3 = Color3.fromRGB(180, 180, 180)
	serverName.Text = string.sub(room.serverId or "", 1, 20) .. "..."
	serverName.TextSize = 12
	serverName.Font = Enum.Font.Gotham
	serverName.TextXAlignment = Enum.TextXAlignment.Left
	serverName.Parent = frame

	-- 플레이어 수
	local playersLabel = Instance.new("TextLabel")
	playersLabel.Name = "PlayersLabel"
	playersLabel.Size = UDim2.new(0, 100, 0, 20)
	playersLabel.Position = UDim2.new(0, 80, 0, 50)
	playersLabel.BackgroundTransparency = 1
	playersLabel.TextColor3 = Color3.fromRGB(100, 200, 100)
	local playerCount = room.players and #room.players or 0
	playersLabel.Text = playerCount .. " / " .. (room.maxPlayersCount or 16) .. " 명"
	playersLabel.TextSize = 14
	playersLabel.Font = Enum.Font.Gotham
	playersLabel.TextXAlignment = Enum.TextXAlignment.Left
	playersLabel.Parent = frame

	-- 입장 버튼
	local joinButton = Instance.new("TextButton")
	joinButton.Name = "JoinButton"
	joinButton.Size = UDim2.new(0, 80, 0, 40)
	joinButton.Position = UDim2.new(1, -100, 0, 20)
	joinButton.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
	joinButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	joinButton.Text = "입장"
	joinButton.TextSize = 16
	joinButton.Font = Enum.Font.GothamBold
	joinButton.Parent = frame

	-- 입장 버튼 클릭 이벤트
	joinButton.MouseButton1Click:Connect(function()
		replicatedStorage:WaitForChild("JoinGameRoom"):FireServer(room.id)
	end)

	return frame
end

-- GUI 요소 생성
local gameList, closeButton = createGuiElements()

-- 게임방 목록 업데이트 함수
local function updateGameList(rooms)
	-- 기존 게임방 목록 삭제
	for _, child in pairs(gameList:GetChildren()) do
		if child:IsA("Frame") and child.Name == "GameTemplate" then
			child:Destroy()
		end
	end

	-- 새로운 게임방 목록 생성
	local i = 0
	for _, room in pairs(rooms) do
		local newGame = createGameTemplate(room, i)
		newGame.Parent = gameList
		i = i + 1
	end
end

-- 서버로부터 게임방 목록 업데이트 신호 수신
replicatedStorage:WaitForChild("UpdateGameList").OnClientEvent:Connect(updateGameList)

-- GUI 표시 신호 수신
replicatedStorage:WaitForChild("ShowGameRoomGui").OnClientEvent:Connect(function()
	mainFrame.Visible = true
	replicatedStorage:WaitForChild("RequestGameList"):FireServer()
end)

-- 닫기 버튼 클릭 시 GUI 숨기기
closeButton.MouseButton1Click:Connect(function()
	mainFrame.Visible = false
end)
