-- ShopNpcService: ShopNpc 배치 및 클릭 이벤트 처리
local SingletonBase = require(game:GetService("ServerScriptService"):WaitForChild("Common"):WaitForChild("SingletonBase"))

local ShopNpcService = setmetatable({}, { __index = SingletonBase })
ShopNpcService.__index = ShopNpcService

local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- NPC 배치 설정 (팀 스폰 위치 기준 오프셋)
local NPC_SPAWN_OFFSET = Vector3.new(0, 3, -8)  -- 스폰 위치 뒤쪽으로 8 스터드, 위로 3 스터드

function ShopNpcService:Initialize()
	-- ShopSystem 폴더가 생성될 때까지 대기
	local shopSystem = ReplicatedStorage:WaitForChild("ShopSystem", 10)
	if not shopSystem then
		warn("[ShopNpcService] ShopSystem 폴더를 찾을 수 없습니다. ShopService가 먼저 초기화되어야 합니다.")
		return
	end

	-- 상점 열기 이벤트 생성
	local openShopEvent = Instance.new("RemoteEvent")
	openShopEvent.Name = "OpenShopEvent"
	openShopEvent.Parent = shopSystem

	self.openShopEvent = openShopEvent

	-- NPC 배치
	task.defer(function()
		self:SpawnShopNpcs()
	end)

	print("[ShopNpcService] 초기화 완료")
end

-- 각 팀 스폰 위치 옆에 ShopNpc 배치
function ShopNpcService:SpawnShopNpcs()
	local npcModel = ServerStorage:FindFirstChild("Npc") and ServerStorage.Npc:FindFirstChild("ShopNpc")
	if not npcModel then
		warn("[ShopNpcService] ServerStorage/Npc/ShopNpc 모델을 찾을 수 없습니다.")
		return
	end

	-- 팀 스폰 위치 찾기
	local spawnLocations = {
		{ name = "TeamA", spawn = workspace:FindFirstChild("SpawnLocationTeamA") },
		{ name = "TeamB", spawn = workspace:FindFirstChild("SpawnLocationTeamB") },
	}

	for _, teamData in ipairs(spawnLocations) do
		if teamData.spawn then
			local npc = self:CreateShopNpc(npcModel, teamData.spawn, teamData.name)
			if npc then
				print("[ShopNpcService] " .. teamData.name .. " ShopNpc 배치 완료")
			end
		else
			warn("[ShopNpcService] " .. teamData.name .. " 스폰 위치를 찾을 수 없습니다.")
		end
	end
end

-- ShopNpc 생성
function ShopNpcService:CreateShopNpc(npcModel, spawnLocation, teamName)
	local npc = npcModel:Clone()
	npc.Name = "ShopNpc_" .. teamName

	-- 스폰 위치 옆에 배치
	local spawnPos = spawnLocation.Position
	local npcPos = spawnPos + NPC_SPAWN_OFFSET

	-- NPC가 스폰 위치를 바라보도록 방향 설정
	local lookAtCFrame = CFrame.lookAt(npcPos, spawnPos)

	-- NPC 위치 설정
	if npc.PrimaryPart then
		npc:PivotTo(lookAtCFrame)
	else
		-- PrimaryPart가 없으면 HumanoidRootPart 또는 첫 번째 파트 찾기
		local rootPart = npc:FindFirstChild("HumanoidRootPart") or npc:FindFirstChildWhichIsA("BasePart")
		if rootPart then
			npc.PrimaryPart = rootPart
			npc:PivotTo(lookAtCFrame)
		end
	end

	-- Humanoid 설정
	local humanoid = npc:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.DisplayName = "상점"
		humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	end

	-- NPC의 모든 파트를 Anchored로 설정 (물리 효과 비활성화)
	for _, part in npc:GetDescendants() do
		if part:IsA("BasePart") then
			part.Anchored = true
			part.CanCollide = true
		end
	end

	-- 기존 ProximityPrompt/ClickDetector 모두 제거
	for _, child in npc:GetDescendants() do
		if child:IsA("ProximityPrompt") or child:IsA("ClickDetector") then
			child:Destroy()
		end
	end

	-- ProximityPrompt는 BasePart에 추가해야 작동함
	-- Head > HumanoidRootPart > 첫 번째 BasePart 순서로 찾기
	local promptPart = npc:FindFirstChild("Head")
		or npc:FindFirstChild("HumanoidRootPart")
		or npc:FindFirstChildWhichIsA("BasePart")

	if promptPart then
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "ShopPrompt"
		prompt.ActionText = "상점 열기"
		prompt.ObjectText = "상점"
		prompt.HoldDuration = 0
		prompt.MaxActivationDistance = 10
		prompt.RequiresLineOfSight = false
		prompt.Enabled = true
		prompt.Parent = promptPart

		prompt.Triggered:Connect(function(player)
			print("[ShopNpcService] ProximityPrompt 트리거됨 - Player: " .. player.Name)
			self:OnNpcClicked(player, teamName)
		end)

		print("[ShopNpcService] ProximityPrompt 생성됨 - " .. npc.Name .. " (파트: " .. promptPart.Name .. ")")
	else
		warn("[ShopNpcService] NPC에 ProximityPrompt를 추가할 파트가 없습니다: " .. npc.Name)
	end

	npc.Parent = workspace

	return npc
end

-- NPC 클릭 시 처리
function ShopNpcService:OnNpcClicked(player, teamName)
	print("[ShopNpcService] NPC 클릭됨 - Player: " .. player.Name .. ", Team: " .. teamName)

	-- 상점 열기 이벤트 발송
	if self.openShopEvent then
		print("[ShopNpcService] OpenShopEvent 발송")
		self.openShopEvent:FireClient(player)
	else
		warn("[ShopNpcService] openShopEvent가 nil입니다!")
	end
end

return ShopNpcService:getInstance()
