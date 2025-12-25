local replicatedStorage = game:GetService("ReplicatedStorage")
local player = game.Players.LocalPlayer
local mainFrame = script.Parent
local gameList = mainFrame:WaitForChild("GameList")
local gameTemplate = replicatedStorage:WaitForChild("Gui"):WaitForChild("GameTemplate")
local closeButton = mainFrame:WaitForChild("CloseButton")

-- UIListLayout 추가
local uiListLayout = Instance.new("UIListLayout")
uiListLayout.Parent = gameList
uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder
uiListLayout.Padding = UDim.new(0, 10) -- 요소 간격 설정

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
		local newGame = gameTemplate:Clone()
		newGame.Visible = true
		newGame.Name = "GameTemplate" -- 클론된 게임 템플릿의 이름을 설정하여 이후 삭제 시 구분 가능
		newGame.LayoutOrder = i -- UIListLayout에서의 정렬 순서 설정

		-- 자식 요소 참조
		local modeType = newGame:WaitForChild("ModeType")
		local serverName = newGame:WaitForChild("ServerName")
		local currentPlayersCount = newGame:WaitForChild("CurrentPlayersCount")
		local maxPlayersCount = newGame:WaitForChild("MaxPlayersCount")
		local joinButton = newGame:WaitForChild("JoinButton")
		local imageLabel = newGame:WaitForChild("ImageLabel")

		modeType.Text = "팀 데스매치 게임모드"
		serverName.Text = room.serverId

		-- 현재 플레이어 수 표시
		if room.players then
			currentPlayersCount.Text = tostring(#room.players)
		else
			currentPlayersCount.Text = "0" -- 플레이어가 없을 경우 기본값 설정
		end

		-- 최대 인원 수 표시
		maxPlayersCount.Text = tostring(room.maxPlayersCount)

		-- 이미지 설정
		imageLabel.Image = "http://www.roblox.com/asset/?id=18548796224"

		-- 입장 버튼 클릭 시 처리
		joinButton.MouseButton1Click:Connect(function()
			replicatedStorage:WaitForChild("JoinGameRoom"):FireServer(room.id)
		end)

		-- 게임방 프레임을 스크롤 프레임에 추가
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
