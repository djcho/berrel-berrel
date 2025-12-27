-- SwimmingBreath: 잠수 시 호흡 게이지 및 익사 시스템
-- 수면 위에서는 호흡 회복, 수면 아래(잠수)에서는 호흡 감소 후 익사

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

-- 설정
local CONFIG = {
	MAX_BREATH = 100,           -- 최대 호흡 게이지
	BREATH_DECREASE_RATE = 20,  -- 초당 호흡 감소량 (잠수 시) - 5초면 바닥
	BREATH_INCREASE_RATE = 25,  -- 초당 호흡 회복량 (수면 위)
	DROWN_DAMAGE = 10,          -- 익사 시 초당 데미지
}

-- 상태 변수
local currentBreath = CONFIG.MAX_BREATH
local isUnderwater = false
local isSwimming = false
local breathGui = nil
local breathBar = nil
local drowningEvent = nil

-- 익사 데미지 RemoteEvent 가져오기 또는 생성
local function getDrowningEvent()
	if drowningEvent then return drowningEvent end

	drowningEvent = ReplicatedStorage:FindFirstChild("DrowningDamageEvent")
	return drowningEvent
end

-- 플레이어가 수영 중인지 확인 (Humanoid 상태)
local function checkIfSwimming()
	local character = player.Character
	if not character then return false end

	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid then return false end

	return humanoid:GetState() == Enum.HumanoidStateType.Swimming
end

-- 플레이어가 수면 아래(잠수)에 있는지 확인
-- 머리 위에 물이 있으면 잠수 상태
local function checkIfUnderwater()
	local character = player.Character
	if not character then return false end

	local head = character:FindFirstChild("Head")
	if not head then return false end

	-- 수영 상태가 아니면 잠수 아님
	if not isSwimming then
		return false
	end

	-- 머리 바로 위(0.5 스터드)에 물이 있는지 확인
	local checkPosition = head.Position + Vector3.new(0, 0.5, 0)

	local terrain = workspace:FindFirstChildOfClass("Terrain")
	if terrain then
		local region = Region3.new(
			checkPosition - Vector3.new(0.5, 0.5, 0.5),
			checkPosition + Vector3.new(0.5, 0.5, 0.5)
		):ExpandToGrid(4)

		local materials, occupancies = terrain:ReadVoxels(region, 4)

		-- 머리 위에 물이 있으면 잠수 상태
		for x = 1, materials.Size.X do
			for y = 1, materials.Size.Y do
				for z = 1, materials.Size.Z do
					if materials[x][y][z] == Enum.Material.Water and occupancies[x][y][z] > 0.1 then
						return true
					end
				end
			end
		end
	end

	-- 머리 위에 물이 없으면 수면 위
	return false
end

-- 호흡 게이지 UI 생성
local function createBreathGui()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "BreathGui"
	screenGui.ResetOnSpawn = true
	screenGui.Parent = player.PlayerGui

	-- 호흡 게이지 배경 프레임 (헬스바 위에 배치, 간격 있게)
	-- 헬스바: Position(0.5, 0, 0.844, 0), Size(0.331, 0, 0.027, 0)
	local breathFrame = Instance.new("Frame")
	breathFrame.Name = "BreathFrame"
	breathFrame.Size = UDim2.new(0, 200, 0, 12)  -- 원래 크기
	breathFrame.Position = UDim2.new(0.5, 0, 0.8, 0)  -- 헬스바 위에 간격 두고
	breathFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	breathFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	breathFrame.BorderSizePixel = 0
	breathFrame.Visible = false
	breathFrame.Parent = screenGui

	local frameCorner = Instance.new("UICorner")
	frameCorner.CornerRadius = UDim.new(0, 6)
	frameCorner.Parent = breathFrame

	local frameStroke = Instance.new("UIStroke")
	frameStroke.Color = Color3.fromRGB(80, 80, 80)
	frameStroke.Thickness = 2
	frameStroke.Parent = breathFrame

	-- 호흡 게이지 바
	local bar = Instance.new("Frame")
	bar.Name = "BreathBar"
	bar.Size = UDim2.new(1, -4, 1, -4)
	bar.Position = UDim2.new(0, 2, 0, 2)
	bar.BackgroundColor3 = Color3.fromRGB(100, 180, 255)
	bar.BorderSizePixel = 0
	bar.Parent = breathFrame

	local barCorner = Instance.new("UICorner")
	barCorner.CornerRadius = UDim.new(0, 4)
	barCorner.Parent = bar

	-- 아이콘 (물방울)
	local icon = Instance.new("TextLabel")
	icon.Name = "Icon"
	icon.Size = UDim2.new(0, 20, 0, 20)
	icon.Position = UDim2.new(0, -24, 0.5, -10)
	icon.BackgroundTransparency = 1
	icon.Text = "💧"
	icon.TextSize = 14
	icon.Parent = breathFrame

	breathGui = screenGui
	breathBar = bar

	return screenGui, bar
end

-- 호흡 게이지 업데이트
local function updateBreathGui()
	if not breathGui then
		createBreathGui()
	end

	local breathFrame = breathGui:FindFirstChild("BreathFrame")
	if not breathFrame then return end

	-- 수영 중이거나, 잠수 중이거나, 호흡이 가득 차지 않은 경우 표시
	local shouldShow = isSwimming or isUnderwater or currentBreath < CONFIG.MAX_BREATH
	breathFrame.Visible = shouldShow

	if shouldShow then
		local breathPercent = currentBreath / CONFIG.MAX_BREATH
		breathBar.Size = UDim2.new(breathPercent, -4, 1, -4)

		-- 호흡에 따라 색상 변경
		if breathPercent > 0.5 then
			breathBar.BackgroundColor3 = Color3.fromRGB(100, 180, 255)  -- 파란색
		elseif breathPercent > 0.25 then
			breathBar.BackgroundColor3 = Color3.fromRGB(255, 200, 50)   -- 노란색
		else
			breathBar.BackgroundColor3 = Color3.fromRGB(255, 80, 80)    -- 빨간색
		end
	end
end

-- 익사 데미지 처리 (서버에 요청)
local function requestDrowningDamage()
	local event = getDrowningEvent()
	if event then
		event:FireServer(CONFIG.DROWN_DAMAGE)
	end
end

-- 메인 루프
local lastUpdate = tick()
RunService.Heartbeat:Connect(function()
	local character = player.Character
	if not character then return end

	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		-- 죽으면 호흡 리셋
		currentBreath = CONFIG.MAX_BREATH
		isUnderwater = false
		isSwimming = false
		updateBreathGui()
		return
	end

	local now = tick()
	local deltaTime = now - lastUpdate
	lastUpdate = now

	-- 수영 상태 및 잠수 상태 체크
	isSwimming = checkIfSwimming()
	isUnderwater = checkIfUnderwater()

	-- 잠수 중 (머리가 물속)일 때만 호흡 감소
	if isUnderwater then
		-- 잠수 중: 호흡 감소
		currentBreath = math.max(0, currentBreath - CONFIG.BREATH_DECREASE_RATE * deltaTime)

		-- 호흡이 0이면 익사 데미지
		if currentBreath <= 0 then
			requestDrowningDamage()
		end
	elseif isSwimming then
		-- 수영 중이지만 수면 위: 호흡 서서히 회복
		currentBreath = math.min(CONFIG.MAX_BREATH, currentBreath + CONFIG.BREATH_INCREASE_RATE * deltaTime)
	else
		-- 물 밖: 빠르게 회복
		currentBreath = math.min(CONFIG.MAX_BREATH, currentBreath + CONFIG.BREATH_INCREASE_RATE * 2 * deltaTime)
	end

	updateBreathGui()
end)

-- 캐릭터 리스폰 시 호흡 리셋
player.CharacterAdded:Connect(function()
	currentBreath = CONFIG.MAX_BREATH
	isUnderwater = false

	-- 기존 GUI 제거 (새로 생성됨)
	if breathGui then
		breathGui:Destroy()
		breathGui = nil
		breathBar = nil
	end
end)
