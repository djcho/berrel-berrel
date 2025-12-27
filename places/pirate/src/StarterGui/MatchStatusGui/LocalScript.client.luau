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

-- MatchUpdate 이벤트 처리
task.spawn(function()
	local matchUpdateEvent = ReplicatedStorage:WaitForChild("MatchUpdate", 30)
	if matchUpdateEvent then
		matchUpdateEvent.OnClientEvent:Connect(function(data)
			print("[MatchStatusGui] MatchUpdate 수신:", data.state)
			-- 필요한 경우 여기서 상태 처리
		end)
		print("[MatchStatusGui] MatchUpdate 이벤트 연결됨")
	else
		warn("[MatchStatusGui] MatchUpdate 이벤트를 찾을 수 없습니다")
	end
end)

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
