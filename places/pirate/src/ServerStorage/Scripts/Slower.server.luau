local SimpleZone = require(game:GetService("ReplicatedStorage"):WaitForChild("SimpleZone"))
local SlowZoneManager = require(game:GetService("ServerScriptService"):WaitForChild("SlowZoneManager"))

local model = script.Parent
local bindableEvent = model:WaitForChild("OnPartRemoving")

local minBounds = Vector3.new(math.huge, math.huge, math.huge)
local maxBounds = Vector3.new(-math.huge, -math.huge, -math.huge)

local playersInZone = {}

for _, part in ipairs(model:GetDescendants()) do
	if part:IsA("BasePart") then
		local partPosition = part.Position
		local partSize = part.Size / 2

		local partMin = partPosition - partSize
		local partMax = partPosition + partSize

		minBounds = Vector3.new(
			math.min(minBounds.X, partMin.X),
			math.min(minBounds.Y, partMin.Y),
			math.min(minBounds.Z, partMin.Z)
		)

		maxBounds = Vector3.new(
			math.max(maxBounds.X, partMax.X),
			math.max(maxBounds.Y, partMax.Y),
			math.max(maxBounds.Z, partMax.Z)
		)
	end
end

minBounds = minBounds
maxBounds = maxBounds + Vector3.new(0, 50, 0)

local region = Region3.new(minBounds, maxBounds)
local zone = SimpleZone.fromRegion(region.CFrame, region.Size)

-- 시각화용 Part 생성
--local visualizationPart = Instance.new("Part")
--visualizationPart.Size = region.Size
--visualizationPart.CFrame = region.CFrame
--visualizationPart.Anchored = true
--visualizationPart.CanCollide = false
--visualizationPart.CanTouch = false
--visualizationPart.Transparency = 0.7
--visualizationPart.Color = Color3.fromRGB(255, 0, 0) -- 빨간색으로 시각화
--visualizationPart.Parent = model
--visualizationPart.Visiblity = false

local function onPlayerEnter(player)
	SlowZoneManager:playerEnteredZone(player)
	playersInZone[player] = true

	-- 플레이어가 들어오면 색상을 변경해 시각화
--	visualizationPart.Color = Color3.fromRGB(0, 255, 0) -- 녹색으로 변경
end

local function onPlayerExit(player)
	SlowZoneManager:playerExitedZone(player)
	playersInZone[player] = nil

	-- 플레이어가 나가면 색상을 원래대로 돌림
--	if next(playersInZone) == nil then
--		visualizationPart.Color = Color3.fromRGB(255, 0, 0) -- 빨간색으로 변경
--	end
end

local enterConnection = zone.playerEntered:Connect(onPlayerEnter)
local exitConnection = zone.playerExited:Connect(onPlayerExit)

local function onModelRemoving()
	enterConnection:Disconnect()
	exitConnection:Disconnect()
	zone:destroy()
end

model.AncestryChanged:Connect(function()
	if not model:IsDescendantOf(game) then
		onModelRemoving()
	end
end)

-- 바인드 이벤트 처리
local function onPartRemoving()
	enterConnection:Disconnect()
	exitConnection:Disconnect()
	zone:destroy()

	-- SlowZoneManager에서 밟은 플레이어의 속도를 초기화
	for player in pairs(playersInZone) do
		SlowZoneManager:playerExitedZone(player)
	end
end

bindableEvent.Event:Connect(onPartRemoving)
