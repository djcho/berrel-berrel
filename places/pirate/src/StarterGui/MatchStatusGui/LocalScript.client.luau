local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local screenGui = script.Parent

-- 해적 테마 색상
local COLORS = {
	woodDark = Color3.fromRGB(62, 39, 22),
	woodLight = Color3.fromRGB(101, 67, 33),
	gold = Color3.fromRGB(255, 200, 50),
	goldDark = Color3.fromRGB(180, 140, 30),
	parchment = Color3.fromRGB(210, 180, 140),
	red = Color3.fromRGB(200, 60, 60),
	blue = Color3.fromRGB(60, 120, 200),
	green = Color3.fromRGB(50, 180, 50),
	black = Color3.fromRGB(20, 15, 10),
	white = Color3.fromRGB(255, 255, 255),
}

-- 데스매치 아이콘
local DEATHMATCH_ICON = "rbxassetid://110698591776828"

-- 메인 상태 프레임 (상단 중앙)
local statusFrame = Instance.new("Frame")
statusFrame.Name = "StatusFrame"
statusFrame.Size = UDim2.new(0, 400, 0, 120)
statusFrame.Position = UDim2.new(0.5, -200, 0, 20)
statusFrame.BackgroundColor3 = COLORS.woodDark
statusFrame.BackgroundTransparency = 0.1
statusFrame.Parent = screenGui

local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0, 16)
frameCorner.Parent = statusFrame

local frameStroke = Instance.new("UIStroke")
frameStroke.Color = COLORS.goldDark
frameStroke.Thickness = 3
frameStroke.Parent = statusFrame

-- 상태 아이콘 (데스매치 이미지)
local stateIcon = Instance.new("ImageLabel")
stateIcon.Name = "StateIcon"
stateIcon.Size = UDim2.new(0, 35, 0, 35)
stateIcon.Position = UDim2.new(0, 10, 0, 10)
stateIcon.BackgroundTransparency = 1
stateIcon.Image = DEATHMATCH_ICON
stateIcon.Parent = statusFrame

-- 상태 텍스트 (대기 중, 게임 중 등)
local stateLabel = Instance.new("TextLabel")
stateLabel.Name = "StateLabel"
stateLabel.Size = UDim2.new(1, -60, 0, 35)
stateLabel.Position = UDim2.new(0, 50, 0, 10)
stateLabel.BackgroundTransparency = 1
stateLabel.TextColor3 = COLORS.gold
stateLabel.Text = "팀 데스매치"
stateLabel.TextSize = 22
stateLabel.Font = Enum.Font.GothamBlack
stateLabel.TextXAlignment = Enum.TextXAlignment.Left
stateLabel.Parent = statusFrame

-- 카운트다운/시간 표시
local timeLabel = Instance.new("TextLabel")
timeLabel.Name = "TimeLabel"
timeLabel.Size = UDim2.new(1, -20, 0, 30)
timeLabel.Position = UDim2.new(0, 10, 0, 45)
timeLabel.BackgroundTransparency = 1
timeLabel.TextColor3 = COLORS.white
timeLabel.Text = ""
timeLabel.TextSize = 28
timeLabel.Font = Enum.Font.GothamBlack
timeLabel.Parent = statusFrame

-- 메시지/이유 표시
local messageLabel = Instance.new("TextLabel")
messageLabel.Name = "MessageLabel"
messageLabel.Size = UDim2.new(1, -20, 0, 25)
messageLabel.Position = UDim2.new(0, 10, 0, 80)
messageLabel.BackgroundTransparency = 1
messageLabel.TextColor3 = COLORS.parchment
messageLabel.Text = ""
messageLabel.TextSize = 14
messageLabel.Font = Enum.Font.GothamBold
messageLabel.TextWrapped = true
messageLabel.Parent = statusFrame

-- 팀 정보 프레임 (상태 프레임 아래)
local teamFrame = Instance.new("Frame")
teamFrame.Name = "TeamFrame"
teamFrame.Size = UDim2.new(0, 400, 0, 50)
teamFrame.Position = UDim2.new(0.5, -200, 0, 150)
teamFrame.BackgroundColor3 = COLORS.woodDark
teamFrame.BackgroundTransparency = 0.2
teamFrame.Parent = screenGui

local teamCorner = Instance.new("UICorner")
teamCorner.CornerRadius = UDim.new(0, 12)
teamCorner.Parent = teamFrame

local teamStroke = Instance.new("UIStroke")
teamStroke.Color = COLORS.goldDark
teamStroke.Thickness = 2
teamStroke.Parent = teamFrame

-- RED 팀 라벨
local redTeamFrame = Instance.new("Frame")
redTeamFrame.Size = UDim2.new(0.5, -5, 1, -10)
redTeamFrame.Position = UDim2.new(0, 5, 0, 5)
redTeamFrame.BackgroundColor3 = COLORS.red
redTeamFrame.BackgroundTransparency = 0.3
redTeamFrame.Parent = teamFrame

local redCorner = Instance.new("UICorner")
redCorner.CornerRadius = UDim.new(0, 8)
redCorner.Parent = redTeamFrame

local redLabel = Instance.new("TextLabel")
redLabel.Name = "RedLabel"
redLabel.Size = UDim2.new(1, 0, 1, 0)
redLabel.BackgroundTransparency = 1
redLabel.TextColor3 = COLORS.white
redLabel.Text = "RED: 0명"
redLabel.TextSize = 18
redLabel.Font = Enum.Font.GothamBold
redLabel.Parent = redTeamFrame

-- BLUE 팀 라벨
local blueTeamFrame = Instance.new("Frame")
blueTeamFrame.Size = UDim2.new(0.5, -5, 1, -10)
blueTeamFrame.Position = UDim2.new(0.5, 0, 0, 5)
blueTeamFrame.BackgroundColor3 = COLORS.blue
blueTeamFrame.BackgroundTransparency = 0.3
blueTeamFrame.Parent = teamFrame

local blueCorner = Instance.new("UICorner")
blueCorner.CornerRadius = UDim.new(0, 8)
blueCorner.Parent = blueTeamFrame

local blueLabel = Instance.new("TextLabel")
blueLabel.Name = "BlueLabel"
blueLabel.Size = UDim2.new(1, 0, 1, 0)
blueLabel.BackgroundTransparency = 1
blueLabel.TextColor3 = COLORS.white
blueLabel.Text = "BLUE: 0명"
blueLabel.TextSize = 18
blueLabel.Font = Enum.Font.GothamBold
blueLabel.Parent = blueTeamFrame

-- 상태 프레임 표시/숨김 함수
local function showStatusFrames()
	statusFrame.Visible = true
	teamFrame.Visible = true
end

local function hideStatusFrames()
	statusFrame.Visible = false
	teamFrame.Visible = false
end

-- 게임 중 타이머 (우측 상단)
local timerFrame = Instance.new("Frame")
timerFrame.Name = "TimerFrame"
timerFrame.Size = UDim2.new(0, 120, 0, 50)
timerFrame.Position = UDim2.new(1, -130, 0, 10)
timerFrame.BackgroundColor3 = COLORS.woodDark
timerFrame.BackgroundTransparency = 0.3
timerFrame.Visible = false
timerFrame.Parent = screenGui

local timerCorner2 = Instance.new("UICorner")
timerCorner2.CornerRadius = UDim.new(0, 10)
timerCorner2.Parent = timerFrame

local timerStroke2 = Instance.new("UIStroke")
timerStroke2.Color = COLORS.goldDark
timerStroke2.Thickness = 2
timerStroke2.Parent = timerFrame

local timerIcon = Instance.new("TextLabel")
timerIcon.Size = UDim2.new(0, 30, 1, 0)
timerIcon.Position = UDim2.new(0, 5, 0, 0)
timerIcon.BackgroundTransparency = 1
timerIcon.Text = "⏱️"
timerIcon.TextSize = 20
timerIcon.Parent = timerFrame

local timerText = Instance.new("TextLabel")
timerText.Name = "TimerText"
timerText.Size = UDim2.new(1, -40, 1, 0)
timerText.Position = UDim2.new(0, 35, 0, 0)
timerText.BackgroundTransparency = 1
timerText.TextColor3 = COLORS.white
timerText.Text = "5:00"
timerText.TextSize = 28
timerText.Font = Enum.Font.GothamBlack
timerText.TextXAlignment = Enum.TextXAlignment.Left
timerText.Parent = timerFrame

-- 상태 업데이트 함수
local function updateStatus(data)
	local teamCounts = data.teamCounts or { TeamA = 0, TeamB = 0 }
	redLabel.Text = string.format("RED: %d명", teamCounts.TeamA or 0)
	blueLabel.Text = string.format("BLUE: %d명", teamCounts.TeamB or 0)

	if data.gameState == "waiting" then
		showStatusFrames()
		timerFrame.Visible = false
		stateLabel.Text = "대기 중"
		stateLabel.TextColor3 = COLORS.gold

		if data.canStart then
			messageLabel.Text = "곧 게임이 시작됩니다..."
			messageLabel.TextColor3 = COLORS.green
			timeLabel.Text = ""
		else
			local reasons = data.reasons or {}
			messageLabel.Text = table.concat(reasons, " / ")
			messageLabel.TextColor3 = COLORS.parchment
			timeLabel.Text = "대기 중..."
			timeLabel.TextColor3 = COLORS.gold
		end

	elseif data.gameState == "starting" then
		showStatusFrames()
		timerFrame.Visible = false
		stateLabel.Text = "게임 시작!"
		stateLabel.TextColor3 = COLORS.green

		local countdown = data.countdownTime or 0
		timeLabel.Text = tostring(countdown)
		timeLabel.TextColor3 = COLORS.white
		timeLabel.TextSize = 48

		messageLabel.Text = "준비하세요!"
		messageLabel.TextColor3 = COLORS.gold

		-- 카운트다운 펄스 효과
		local tween = TweenService:Create(timeLabel, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
			TextSize = 48
		})
		timeLabel.TextSize = 60
		tween:Play()

	elseif data.gameState == "playing" then
		-- 게임 중에는 상태 프레임 숨기고 타이머만 표시
		hideStatusFrames()
		timerFrame.Visible = true

		-- 남은 시간 표시
		local remaining = data.matchTimeRemaining or 0
		local mins = math.floor(remaining / 60)
		local secs = math.floor(remaining % 60)
		timerText.Text = string.format("%d:%02d", mins, secs)

		-- 30초 이하면 빨간색
		if remaining <= 30 then
			timerText.TextColor3 = COLORS.red
		elseif remaining <= 60 then
			timerText.TextColor3 = COLORS.gold
		else
			timerText.TextColor3 = COLORS.white
		end

	elseif data.gameState == "ended" then
		showStatusFrames()
		timerFrame.Visible = false
		stateLabel.Text = "게임 종료!"
		stateLabel.TextColor3 = COLORS.gold

		local endCountdown = data.endCountdown or 0
		timeLabel.Text = tostring(endCountdown)
		timeLabel.TextSize = 36
		timeLabel.TextColor3 = COLORS.white

		messageLabel.Text = "다음 게임 준비 중..."
		messageLabel.TextColor3 = COLORS.parchment
	end
end

-- 게임 종료 결과 표시
local resultFrame = Instance.new("Frame")
resultFrame.Name = "ResultFrame"
resultFrame.Size = UDim2.new(0, 500, 0, 300)
resultFrame.Position = UDim2.new(0.5, -250, 0.5, -150)
resultFrame.BackgroundColor3 = COLORS.woodDark
resultFrame.BackgroundTransparency = 0.1
resultFrame.Visible = false
resultFrame.Parent = screenGui

local resultCorner = Instance.new("UICorner")
resultCorner.CornerRadius = UDim.new(0, 20)
resultCorner.Parent = resultFrame

local resultStroke = Instance.new("UIStroke")
resultStroke.Color = COLORS.goldDark
resultStroke.Thickness = 4
resultStroke.Parent = resultFrame

local resultTitle = Instance.new("TextLabel")
resultTitle.Size = UDim2.new(1, 0, 0, 60)
resultTitle.BackgroundTransparency = 1
resultTitle.TextColor3 = COLORS.gold
resultTitle.Text = "게임 종료!"
resultTitle.TextSize = 36
resultTitle.Font = Enum.Font.GothamBlack
resultTitle.Parent = resultFrame

local winnerLabel = Instance.new("TextLabel")
winnerLabel.Size = UDim2.new(1, 0, 0, 50)
winnerLabel.Position = UDim2.new(0, 0, 0, 60)
winnerLabel.BackgroundTransparency = 1
winnerLabel.TextColor3 = COLORS.white
winnerLabel.Text = ""
winnerLabel.TextSize = 28
winnerLabel.Font = Enum.Font.GothamBold
winnerLabel.Parent = resultFrame

local statsLabel = Instance.new("TextLabel")
statsLabel.Size = UDim2.new(1, -40, 0, 150)
statsLabel.Position = UDim2.new(0, 20, 0, 120)
statsLabel.BackgroundTransparency = 1
statsLabel.TextColor3 = COLORS.parchment
statsLabel.Text = ""
statsLabel.TextSize = 16
statsLabel.Font = Enum.Font.Gotham
statsLabel.TextWrapped = true
statsLabel.TextYAlignment = Enum.TextYAlignment.Top
statsLabel.Parent = resultFrame

-- 게임 종료 결과 처리
local function showGameResult(results)
	resultFrame.Visible = true

	local winnerText = "무승부!"
	local winnerColor = COLORS.gold

	if results.winner == "TeamA" then
		winnerText = "RED 팀 승리!"
		winnerColor = COLORS.red
	elseif results.winner == "TeamB" then
		winnerText = "BLUE 팀 승리!"
		winnerColor = COLORS.blue
	end

	winnerLabel.Text = winnerText
	winnerLabel.TextColor3 = winnerColor

	-- 내 스탯 표시
	local myKills = results.kills and results.kills[player.Name] or 0
	local myDeaths = results.deaths and results.deaths[player.Name] or 0
	local myAssists = results.assists and results.assists[player.Name] or 0
	local kda = string.format("%.2f", myDeaths > 0 and (myKills + myAssists) / myDeaths or (myKills + myAssists))

	local matchMins = math.floor((results.matchTime or 0) / 60)
	local matchSecs = math.floor((results.matchTime or 0) % 60)

	statsLabel.Text = string.format(
		"내 전적:\n킬: %d / 데스: %d / 어시스트: %d\nKDA: %s\n\n매치 시간: %d분 %d초",
		myKills, myDeaths, myAssists, kda, matchMins, matchSecs
	)

	-- 5초 후 결과창 숨기기
	task.delay(5, function()
		resultFrame.Visible = false
	end)
end

-- 이벤트 연결
local gameStateEvent = ReplicatedStorage:WaitForChild("GameStateUpdate", 10)
if gameStateEvent then
	gameStateEvent.OnClientEvent:Connect(updateStatus)
end

local gameEndEvent = ReplicatedStorage:WaitForChild("GameEnd", 10)
if gameEndEvent then
	gameEndEvent.OnClientEvent:Connect(showGameResult)
end

-- 킬 피드 표시
local killFeedFrame = Instance.new("Frame")
killFeedFrame.Name = "KillFeedFrame"
killFeedFrame.Size = UDim2.new(0, 300, 0, 200)
killFeedFrame.Position = UDim2.new(1, -310, 0, 100)
killFeedFrame.BackgroundTransparency = 1
killFeedFrame.Parent = screenGui

local killFeedLayout = Instance.new("UIListLayout")
killFeedLayout.SortOrder = Enum.SortOrder.LayoutOrder
killFeedLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
killFeedLayout.Padding = UDim.new(0, 5)
killFeedLayout.Parent = killFeedFrame

local killFeedOrder = 0

local function addKillFeed(data)
	killFeedOrder = killFeedOrder + 1

	local feedLabel = Instance.new("TextLabel")
	feedLabel.Size = UDim2.new(1, 0, 0, 25)
	feedLabel.BackgroundColor3 = COLORS.black
	feedLabel.BackgroundTransparency = 0.5
	feedLabel.TextColor3 = COLORS.white
	feedLabel.Text = string.format("%s killed %s", data.killer or "?", data.victim or "?")
	feedLabel.TextSize = 14
	feedLabel.Font = Enum.Font.GothamBold
	feedLabel.TextXAlignment = Enum.TextXAlignment.Right
	feedLabel.LayoutOrder = killFeedOrder
	feedLabel.Parent = killFeedFrame

	local feedCorner = Instance.new("UICorner")
	feedCorner.CornerRadius = UDim.new(0, 4)
	feedCorner.Parent = feedLabel

	local padding = Instance.new("UIPadding")
	padding.PaddingRight = UDim.new(0, 10)
	padding.Parent = feedLabel

	-- 5초 후 제거
	task.delay(5, function()
		feedLabel:Destroy()
	end)
end

local killFeedEvent = ReplicatedStorage:WaitForChild("KillFeed", 10)
if killFeedEvent then
	killFeedEvent.OnClientEvent:Connect(addKillFeed)
end

-- 게임 시작 알림 (화면 중앙 대형 텍스트)
local gameStartFrame = Instance.new("Frame")
gameStartFrame.Name = "GameStartFrame"
gameStartFrame.Size = UDim2.new(1, 0, 1, 0)
gameStartFrame.Position = UDim2.new(0, 0, 0, 0)
gameStartFrame.BackgroundTransparency = 1
gameStartFrame.Visible = false
gameStartFrame.ZIndex = 100
gameStartFrame.Parent = screenGui

local gameStartLabel = Instance.new("TextLabel")
gameStartLabel.Name = "GameStartLabel"
gameStartLabel.Size = UDim2.new(1, 0, 0, 150)
gameStartLabel.Position = UDim2.new(0, 0, 0.35, 0)
gameStartLabel.BackgroundTransparency = 1
gameStartLabel.TextColor3 = COLORS.gold
gameStartLabel.Text = "전투 시작!"
gameStartLabel.TextSize = 80
gameStartLabel.Font = Enum.Font.GothamBlack
gameStartLabel.TextStrokeColor3 = COLORS.black
gameStartLabel.TextStrokeTransparency = 0.3
gameStartLabel.ZIndex = 100
gameStartLabel.Parent = gameStartFrame

local gameStartSubLabel = Instance.new("TextLabel")
gameStartSubLabel.Name = "GameStartSubLabel"
gameStartSubLabel.Size = UDim2.new(1, 0, 0, 50)
gameStartSubLabel.Position = UDim2.new(0, 0, 0.5, 0)
gameStartSubLabel.BackgroundTransparency = 1
gameStartSubLabel.TextColor3 = COLORS.white
gameStartSubLabel.Text = "제한시간 내에 최대한 많은 적을 처치하세요!"
gameStartSubLabel.TextSize = 28
gameStartSubLabel.Font = Enum.Font.GothamBold
gameStartSubLabel.TextStrokeColor3 = COLORS.black
gameStartSubLabel.TextStrokeTransparency = 0.5
gameStartSubLabel.ZIndex = 100
gameStartSubLabel.Parent = gameStartFrame

-- 게임 시작 애니메이션 함수
local function showGameStartAnimation()
	print("[MatchStatusGui] 게임 시작 애니메이션 실행!")

	gameStartFrame.Visible = true
	gameStartLabel.TextTransparency = 0
	gameStartLabel.TextSize = 60
	gameStartSubLabel.TextTransparency = 0

	-- 페이드 인 (크기 확대)
	local fadeIn = TweenService:Create(gameStartLabel, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		TextSize = 100
	})
	fadeIn:Play()

	-- 2.5초 후 페이드 아웃
	task.delay(2.5, function()
		local fadeOut = TweenService:Create(gameStartLabel, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {
			TextTransparency = 1
		})
		local subFadeOut = TweenService:Create(gameStartSubLabel, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {
			TextTransparency = 1
		})
		fadeOut:Play()
		subFadeOut:Play()

		task.delay(0.5, function()
			gameStartFrame.Visible = false
			gameStartLabel.TextTransparency = 0
			gameStartSubLabel.TextTransparency = 0
		end)
	end)
end

-- 게임 시작 이벤트 연결
task.spawn(function()
	local gameStartEvent = ReplicatedStorage:WaitForChild("GameStart", 30)
	if gameStartEvent then
		gameStartEvent.OnClientEvent:Connect(showGameStartAnimation)
		print("[MatchStatusGui] GameStart 이벤트 연결됨")
	else
		warn("[MatchStatusGui] GameStart 이벤트를 찾을 수 없습니다")
	end
end)

print("[MatchStatusGui] 초기화 완료")
