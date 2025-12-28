-- 스튜디오 전용 디버그 핸들러
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- 스튜디오에서만 실행
if not RunService:IsStudio() then
	return
end

print("[StudioDebugHandler] Initializing debug events...")

-- 디버그 이벤트 생성
local function createDebugEvent(name)
	local event = Instance.new("RemoteEvent")
	event.Name = name
	event.Parent = ReplicatedStorage
	return event
end

local debugForceStart = createDebugEvent("DebugForceStart")
local debugEndGame = createDebugEvent("DebugEndGame")
local debugRespawn = createDebugEvent("DebugRespawn")
local debugSwitchTeam = createDebugEvent("DebugSwitchTeam")
local debugShowStartAnim = createDebugEvent("DebugShowStartAnim")
local debugAddGold = createDebugEvent("DebugAddGold")

-- 게임 이벤트도 미리 생성 (MatchController보다 먼저 로드될 수 있음)
if not ReplicatedStorage:FindFirstChild("GameStart") then
	local gameStart = Instance.new("RemoteEvent")
	gameStart.Name = "GameStart"
	gameStart.Parent = ReplicatedStorage
end

if not ReplicatedStorage:FindFirstChild("GameEnd") then
	local gameEnd = Instance.new("RemoteEvent")
	gameEnd.Name = "GameEnd"
	gameEnd.Parent = ReplicatedStorage
end

-- MatchController 참조 (싱글톤)
local MatchController = nil

-- 지연 로드 (다른 스크립트가 초기화될 때까지 대기)
task.spawn(function()
	task.wait(1)

	-- MatchController 로드 시도
	pcall(function()
		MatchController = require(ServerScriptService:WaitForChild("Controller"):WaitForChild("MatchController"))
	end)

	print("[StudioDebugHandler] Controllers loaded")
end)

-- 게임 강제 시작
debugForceStart.OnServerEvent:Connect(function(player)
	print("[StudioDebug] Force start requested by " .. player.Name)

	if MatchController then
		-- 게임 상태를 직접 변경
		if MatchController.gameState == "waiting" or MatchController.gameState == "starting" then
			MatchController:startMatch()
			print("[StudioDebug] Match force started!")
		else
			print("[StudioDebug] Game already in progress: " .. tostring(MatchController.gameState))
		end
	else
		-- MatchController 없이 직접 GameStart 이벤트 발생
		local gameStartEvent = ReplicatedStorage:FindFirstChild("GameStart")
		if gameStartEvent then
			gameStartEvent:FireAllClients()
			print("[StudioDebug] GameStart event fired directly")
		end
	end
end)

-- 게임 시작 애니메이션만 표시
debugShowStartAnim.OnServerEvent:Connect(function(player)
	print("[StudioDebug] Show start animation requested by " .. player.Name)

	local gameStartEvent = ReplicatedStorage:FindFirstChild("GameStart")
	if gameStartEvent then
		gameStartEvent:FireAllClients()
		print("[StudioDebug] GameStart animation triggered")
	else
		-- GameStart 이벤트가 없으면 생성
		local newEvent = Instance.new("RemoteEvent")
		newEvent.Name = "GameStart"
		newEvent.Parent = ReplicatedStorage
		newEvent:FireAllClients()
		print("[StudioDebug] GameStart event created and triggered")
	end
end)

-- 게임 종료
debugEndGame.OnServerEvent:Connect(function(player, winningTeam)
	print("[StudioDebug] End game requested by " .. player.Name .. " - Winner: " .. tostring(winningTeam))

	if MatchController and MatchController.endMatch then
		MatchController:endMatch(winningTeam)
		print("[StudioDebug] Match ended!")
	else
		-- GameEnd 이벤트 직접 발생
		local gameEndEvent = ReplicatedStorage:FindFirstChild("GameEnd")
		if gameEndEvent then
			gameEndEvent:FireAllClients({
				winner = winningTeam,
				kills = {},
				deaths = {},
				assists = {},
				matchTime = 0
			})
			print("[StudioDebug] GameEnd event fired directly")
		end
	end
end)

-- 리스폰
debugRespawn.OnServerEvent:Connect(function(player)
	print("[StudioDebug] Respawn requested by " .. player.Name)
	player:LoadCharacter()
end)

-- 팀 전환
debugSwitchTeam.OnServerEvent:Connect(function(player)
	print("[StudioDebug] Team switch requested by " .. player.Name)

	local Teams = game:GetService("Teams")
	local teamA = Teams:FindFirstChild("TeamA")
	local teamB = Teams:FindFirstChild("TeamB")

	if player.Team == teamA then
		player.Team = teamB
		print("[StudioDebug] " .. player.Name .. " switched to TeamB")
	else
		player.Team = teamA
		print("[StudioDebug] " .. player.Name .. " switched to TeamA")
	end
end)

-- 골드 추가/차감
debugAddGold.OnServerEvent:Connect(function(player, amount)
	print("[StudioDebug] Add gold requested by " .. player.Name .. " - Amount: " .. tostring(amount))

	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local coins = leaderstats:FindFirstChild("Coins")
		if coins then
			if amount < 0 then
				-- 음수면 초기화 (0으로)
				coins.Value = 0
				print("[StudioDebug] " .. player.Name .. " gold reset to 0")
			else
				coins.Value = coins.Value + amount
				print("[StudioDebug] " .. player.Name .. " gold: " .. coins.Value)
			end
		else
			print("[StudioDebug] Coins not found in leaderstats")
		end
	else
		print("[StudioDebug] leaderstats not found for " .. player.Name)
	end
end)

print("[StudioDebugHandler] Debug events ready!")
