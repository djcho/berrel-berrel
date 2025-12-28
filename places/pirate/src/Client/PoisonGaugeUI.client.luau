-- PoisonGaugeUI: 중독 게이지 UI 클라이언트 스크립트
-- 독구름에 들어가면 중독 게이지가 표시되고, 게이지가 0이 되면 기절

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer

-- UI 변수
local poisonGui = nil
local poisonBar = nil
local stunOverlay = nil

-- 중독 게이지 UI 생성
local function createPoisonGui()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "PoisonGaugeGui"
	screenGui.ResetOnSpawn = true
	screenGui.Parent = player.PlayerGui

	-- 중독 게이지 배경 프레임 (호흡 게이지 아래에 배치)
	local poisonFrame = Instance.new("Frame")
	poisonFrame.Name = "PoisonFrame"
	poisonFrame.Size = UDim2.new(0, 200, 0, 12)
	poisonFrame.Position = UDim2.new(0.5, 0, 0.76, 0)  -- 호흡 게이지보다 위에
	poisonFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	poisonFrame.BackgroundColor3 = Color3.fromRGB(30, 20, 30)
	poisonFrame.BorderSizePixel = 0
	poisonFrame.Visible = false
	poisonFrame.Parent = screenGui

	local frameCorner = Instance.new("UICorner")
	frameCorner.CornerRadius = UDim.new(0, 6)
	frameCorner.Parent = poisonFrame

	local frameStroke = Instance.new("UIStroke")
	frameStroke.Color = Color3.fromRGB(80, 40, 80)
	frameStroke.Thickness = 2
	frameStroke.Parent = poisonFrame

	-- 중독 게이지 바
	local bar = Instance.new("Frame")
	bar.Name = "PoisonBar"
	bar.Size = UDim2.new(1, -4, 1, -4)
	bar.Position = UDim2.new(0, 2, 0, 2)
	bar.BackgroundColor3 = Color3.fromRGB(128, 50, 180)  -- 보라색
	bar.BorderSizePixel = 0
	bar.Parent = poisonFrame

	local barCorner = Instance.new("UICorner")
	barCorner.CornerRadius = UDim.new(0, 4)
	barCorner.Parent = bar

	-- 아이콘 (해골)
	local icon = Instance.new("TextLabel")
	icon.Name = "Icon"
	icon.Size = UDim2.new(0, 20, 0, 20)
	icon.Position = UDim2.new(0, -24, 0.5, -10)
	icon.BackgroundTransparency = 1
	icon.Text = "☠"
	icon.TextColor3 = Color3.fromRGB(180, 100, 200)
	icon.TextSize = 16
	icon.Parent = poisonFrame

	-- 기절 시 화면 오버레이
	local overlay = Instance.new("Frame")
	overlay.Name = "StunOverlay"
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.Position = UDim2.new(0, 0, 0, 0)
	overlay.BackgroundColor3 = Color3.fromRGB(60, 0, 90)
	overlay.BackgroundTransparency = 1
	overlay.BorderSizePixel = 0
	overlay.Parent = screenGui

	-- 기절 텍스트
	local stunText = Instance.new("TextLabel")
	stunText.Name = "StunText"
	stunText.Size = UDim2.new(1, 0, 0, 50)
	stunText.Position = UDim2.new(0, 0, 0.5, -25)
	stunText.BackgroundTransparency = 1
	stunText.Text = "중독됨!"
	stunText.TextColor3 = Color3.fromRGB(200, 100, 255)
	stunText.TextSize = 36
	stunText.Font = Enum.Font.GothamBold
	stunText.TextTransparency = 1
	stunText.Parent = overlay

	poisonGui = screenGui
	poisonBar = bar
	stunOverlay = overlay

	return screenGui
end

-- 게이지 업데이트
local function updatePoisonGauge(currentGauge, maxGauge)
	if not poisonGui then
		createPoisonGui()
	end

	local poisonFrame = poisonGui:FindFirstChild("PoisonFrame")
	if not poisonFrame then return end

	poisonFrame.Visible = true

	local gaugePercent = math.clamp(currentGauge / maxGauge, 0, 1)

	-- 부드러운 크기 변화
	TweenService:Create(poisonBar, TweenInfo.new(0.1), {
		Size = UDim2.new(gaugePercent, -4, 1, -4)
	}):Play()

	-- 게이지에 따라 색상 변경
	local targetColor
	if gaugePercent > 0.5 then
		targetColor = Color3.fromRGB(128, 50, 180)  -- 보라색
	elseif gaugePercent > 0.25 then
		targetColor = Color3.fromRGB(180, 80, 120)  -- 분홍-보라
	else
		targetColor = Color3.fromRGB(200, 50, 80)   -- 빨간색
	end

	TweenService:Create(poisonBar, TweenInfo.new(0.2), {
		BackgroundColor3 = targetColor
	}):Play()
end

-- 게이지 숨기기
local function hidePoisonGauge()
	if not poisonGui then return end

	local poisonFrame = poisonGui:FindFirstChild("PoisonFrame")
	if poisonFrame then
		poisonFrame.Visible = false
	end
end

-- 기절 효과
local function showStunEffect(duration)
	if not poisonGui then
		createPoisonGui()
	end

	if not stunOverlay then return end

	local stunText = stunOverlay:FindFirstChild("StunText")

	-- 화면 어둡게 + 텍스트 표시
	TweenService:Create(stunOverlay, TweenInfo.new(0.3), {
		BackgroundTransparency = 0.6
	}):Play()

	if stunText then
		TweenService:Create(stunText, TweenInfo.new(0.3), {
			TextTransparency = 0
		}):Play()
	end

	-- 기절 시간 후 복구
	task.delay(duration, function()
		TweenService:Create(stunOverlay, TweenInfo.new(0.5), {
			BackgroundTransparency = 1
		}):Play()

		if stunText then
			TweenService:Create(stunText, TweenInfo.new(0.5), {
				TextTransparency = 1
			}):Play()
		end
	end)
end

-- PoisonSystem RemoteEvent 연결
local function connectPoisonEvent()
	local poisonSystem = ReplicatedStorage:WaitForChild("PoisonSystem", 10)
	if not poisonSystem then return end

	local poisonGaugeEvent = poisonSystem:WaitForChild("PoisonGaugeEvent", 10)
	if not poisonGaugeEvent then return end

	poisonGaugeEvent.OnClientEvent:Connect(function(action, arg1, arg2)
		if action == "update" then
			-- arg1 = currentGauge, arg2 = maxGauge
			updatePoisonGauge(arg1, arg2)
		elseif action == "hide" then
			hidePoisonGauge()
		elseif action == "stun" then
			-- arg1 = duration
			showStunEffect(arg1)
		end
	end)
end

-- 캐릭터 리스폰 시 UI 정리
player.CharacterAdded:Connect(function()
	if poisonGui then
		poisonGui:Destroy()
		poisonGui = nil
		poisonBar = nil
		stunOverlay = nil
	end
end)

-- 초기화
connectPoisonEvent()
