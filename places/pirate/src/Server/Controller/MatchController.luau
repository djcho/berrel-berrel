-- MatchController: 팀 데스매치 게임 진행을 관리하는 컨트롤러
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MessagingService = game:GetService("MessagingService")
local HttpService = game:GetService("HttpService")
local SingletonBase = require(game:GetService("ServerScriptService"):WaitForChild("Common"):WaitForChild("SingletonBase"))
local TeamService = require(game:GetService("ServerScriptService"):WaitForChild("Service"):WaitForChild("TeamService"))

local MatchController = setmetatable({}, { __index = SingletonBase })
MatchController.__index = MatchController

-- 게임 상태
local GameState = {
	WAITING = "waiting",      -- 플레이어 대기 중
	STARTING = "starting",    -- 게임 시작 카운트다운
	PLAYING = "playing",      -- 게임 진행 중
	ENDED = "ended"           -- 게임 종료
}

-- 설정
local CONFIG = {
	MIN_PLAYERS = 2,           -- 최소 시작 인원
	MIN_PER_TEAM = 1,          -- 각 팀 최소 인원
	COUNTDOWN_TIME = 10,       -- 시작 카운트다운 (초)
	MATCH_TIME = 300,          -- 매치 시간 (5분)
	RESPAWN_TIME = 5,          -- 리스폰 시간 (초)
	END_DELAY = 10,            -- 게임 종료 후 로비 이동까지 시간
	BROADCAST_INTERVAL = 1,    -- 로비로 상태 전송 간격 (초) - 1초로 변경하여 실시간 카운트다운 표시
	RESTART_DELAY = 5,         -- 게임 종료 후 다음 게임까지 대기 시간
}

local LOBBY_PLACE_ID = 18517272972
local MATCH_STATUS_TOPIC = "MatchStatus"
local isStudio = RunService:IsStudio()

function MatchController:Initialize()
	self.gameState = GameState.WAITING
	self.matchStartTime = 0
	self.kills = {}   -- { playerName = killCount }
	self.deaths = {}  -- { playerName = deathCount }
	self.assists = {} -- { playerName = assistCount }
	self.damageLog = {} -- { victimName = { {attackerName, timestamp}, ... } }
	self.roomId = game.JobId ~= "" and game.JobId or "studio_room"

	-- RemoteEvent 생성
	self:createRemoteEvents()

	-- 플레이어 이벤트 연결
	Players.PlayerAdded:Connect(function(player)
		self:onPlayerAdded(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		self:onPlayerRemoving(player)
	end)

	-- 이미 접속한 플레이어 처리
	for _, player in ipairs(Players:GetPlayers()) do
		self:onPlayerAdded(player)
	end

	-- 게임 루프 시작
	task.spawn(function()
		self:gameLoop()
	end)

	-- 로비로 상태 브로드캐스트 시작
	task.spawn(function()
		self:broadcastLoop()
	end)

	print("[MatchController] 초기화 완료")
end

function MatchController:createRemoteEvents()
	local events = {"MatchUpdate", "KillFeed", "GameEnd", "GameStateUpdate", "GameStart"}
	for _, eventName in ipairs(events) do
		if not ReplicatedStorage:FindFirstChild(eventName) then
			local event = Instance.new("RemoteEvent")
			event.Name = eventName
			event.Parent = ReplicatedStorage
		end
	end
end

-- 시작 조건 체크 및 이유 반환
function MatchController:getStartConditionStatus()
	local playerCount = #Players:GetPlayers()
	local teamCounts = TeamService:GetTeamCounts()

	local canStart = true
	local reasons = {}

	-- 최소 인원 체크
	if playerCount < CONFIG.MIN_PLAYERS then
		canStart = false
		table.insert(reasons, string.format("플레이어 %d명 필요 (현재 %d명)", CONFIG.MIN_PLAYERS, playerCount))
	end

	-- 각 팀 최소 인원 체크
	if teamCounts.TeamA < CONFIG.MIN_PER_TEAM then
		canStart = false
		table.insert(reasons, string.format("RED 팀 %d명 필요 (현재 %d명)", CONFIG.MIN_PER_TEAM, teamCounts.TeamA))
	end

	if teamCounts.TeamB < CONFIG.MIN_PER_TEAM then
		canStart = false
		table.insert(reasons, string.format("BLUE 팀 %d명 필요 (현재 %d명)", CONFIG.MIN_PER_TEAM, teamCounts.TeamB))
	end

	return canStart, reasons, teamCounts
end

-- 게임 상태 브로드캐스트 (클라이언트 GUI용)
function MatchController:broadcastGameState()
	local canStart, reasons, teamCounts = self:getStartConditionStatus()

	local stateData = {
		gameState = self.gameState,
		canStart = canStart,
		reasons = reasons,
		teamCounts = teamCounts,
		playerCount = #Players:GetPlayers(),
		countdownTime = self.countdownTime or 0,
		matchTimeRemaining = 0,
		endCountdown = self.endCountdown or 0,
	}

	if self.gameState == GameState.PLAYING then
		stateData.matchTimeRemaining = math.max(0, CONFIG.MATCH_TIME - (tick() - self.matchStartTime))
	end

	ReplicatedStorage.GameStateUpdate:FireAllClients(stateData)
end

function MatchController:onPlayerAdded(player)
	self.kills[player.Name] = 0
	self.deaths[player.Name] = 0
	self.assists[player.Name] = 0

	-- 대기 중이면 팀 배정
	if self.gameState == GameState.WAITING or self.gameState == GameState.STARTING then
		TeamService:AssignTeam(player)
	end

	-- 플레이어 사망 이벤트 연결
	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid")

		-- 데미지 추적
		humanoid.HealthChanged:Connect(function(newHealth)
			if newHealth < humanoid.MaxHealth then
				self:logDamage(player.Name)
			end
		end)

		humanoid.Died:Connect(function()
			self:onPlayerDied(player)
		end)
	end)

	-- 대기 상태면 게임 시작 체크
	if self.gameState == GameState.WAITING then
		self:checkStartCondition()
	end

	-- 새로 접속한 플레이어에게 즉시 현재 상태 전송
	task.defer(function()
		self:sendStateToPlayer(player)
	end)

	-- 전체 상태 브로드캐스트
	self:broadcastGameState()
end

-- 특정 플레이어에게 현재 상태 전송
function MatchController:sendStateToPlayer(player)
	local canStart, reasons, teamCounts = self:getStartConditionStatus()

	local stateData = {
		gameState = self.gameState,
		canStart = canStart,
		reasons = reasons,
		teamCounts = teamCounts,
		playerCount = #Players:GetPlayers(),
		countdownTime = self.countdownTime or 0,
		matchTimeRemaining = 0,
		endCountdown = self.endCountdown or 0,
	}

	if self.gameState == GameState.PLAYING then
		stateData.matchTimeRemaining = math.max(0, CONFIG.MATCH_TIME - (tick() - self.matchStartTime))
	end

	ReplicatedStorage.GameStateUpdate:FireClient(player, stateData)
end

function MatchController:onPlayerRemoving(player)
	self.kills[player.Name] = nil
	self.deaths[player.Name] = nil
	self.assists[player.Name] = nil

	-- 상태 브로드캐스트
	task.defer(function()
		self:broadcastGameState()
	end)
end

-- 데미지 로그 기록 (어시스트 계산용)
function MatchController:logDamage(victimName)
	-- 마지막으로 데미지를 준 플레이어 찾기 (creator 태그에서)
	local victim = Players:FindFirstChild(victimName)
	if not victim or not victim.Character then return end

	local humanoid = victim.Character:FindFirstChild("Humanoid")
	if not humanoid then return end

	local creator = humanoid:FindFirstChild("creator")
	if creator and creator.Value then
		local attackerName = creator.Value.Name
		if attackerName ~= victimName then
			if not self.damageLog[victimName] then
				self.damageLog[victimName] = {}
			end
			table.insert(self.damageLog[victimName], {
				attacker = attackerName,
				time = tick()
			})
			-- 10초가 지난 데미지 기록 제거
			local cutoff = tick() - 10
			local newLog = {}
			for _, entry in ipairs(self.damageLog[victimName]) do
				if entry.time >= cutoff then
					table.insert(newLog, entry)
				end
			end
			self.damageLog[victimName] = newLog
		end
	end
end

function MatchController:onPlayerDied(player)
	if self.gameState ~= GameState.PLAYING then
		return
	end

	self.deaths[player.Name] = (self.deaths[player.Name] or 0) + 1

	-- leaderstats 실시간 업데이트 (Death)
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats and leaderstats:FindFirstChild("Death") then
		leaderstats.Death.Value = self.deaths[player.Name]
	end

	local killerName = nil

	-- 킬러 찾기 (Creator 태그 사용)
	local character = player.Character
	if character then
		local humanoid = character:FindFirstChild("Humanoid")
		if humanoid then
			local creator = humanoid:FindFirstChild("creator")
			if creator and creator.Value then
				killerName = creator.Value.Name
				self.kills[killerName] = (self.kills[killerName] or 0) + 1

				-- leaderstats 실시간 업데이트 (Kill)
				local killer = Players:FindFirstChild(killerName)
				if killer then
					local killerLeaderstats = killer:FindFirstChild("leaderstats")
					if killerLeaderstats and killerLeaderstats:FindFirstChild("Kill") then
						killerLeaderstats.Kill.Value = self.kills[killerName]
					end
				end

				-- 킬 피드 알림
				ReplicatedStorage.KillFeed:FireAllClients({
					killer = killerName,
					victim = player.Name
				})
			end
		end
	end

	-- 어시스트 계산 (10초 내에 데미지를 준 다른 플레이어들)
	if self.damageLog[player.Name] then
		local assisters = {}
		for _, entry in ipairs(self.damageLog[player.Name]) do
			if entry.attacker ~= killerName and entry.attacker ~= player.Name then
				assisters[entry.attacker] = true
			end
		end
		for assisterName, _ in pairs(assisters) do
			self.assists[assisterName] = (self.assists[assisterName] or 0) + 1
		end
		self.damageLog[player.Name] = {}
	end

	-- 리스폰
	task.delay(CONFIG.RESPAWN_TIME, function()
		if player and player.Parent then
			player:LoadCharacter()
		end
	end)

	-- 팀 전멸 체크
	self:checkTeamWipeout()
end

function MatchController:checkStartCondition()
	local canStart = self:getStartConditionStatus()
	if canStart and self.gameState == GameState.WAITING then
		self:startCountdown()
	end
end

function MatchController:startCountdown()
	self.gameState = GameState.STARTING
	self.countdownTime = CONFIG.COUNTDOWN_TIME

	-- 카운트다운
	for i = CONFIG.COUNTDOWN_TIME, 1, -1 do
		self.countdownTime = i

		-- 시작 조건 재확인
		local canStart, reasons = self:getStartConditionStatus()
		if not canStart then
			self.gameState = GameState.WAITING
			self.countdownTime = 0
			ReplicatedStorage.MatchUpdate:FireAllClients({
				state = "cancelled",
				message = reasons[1] or "조건 미충족"
			})
			self:broadcastGameState()
			return
		end

		ReplicatedStorage.MatchUpdate:FireAllClients({
			state = "countdown",
			time = i
		})
		self:broadcastGameState()
		task.wait(1)
	end

	self:startMatch()
end

function MatchController:startMatch()
	self.gameState = GameState.PLAYING
	self.matchStartTime = tick()
	self.countdownTime = 0

	-- 킬/데스/어시스트 초기화
	for _, player in ipairs(Players:GetPlayers()) do
		self.kills[player.Name] = 0
		self.deaths[player.Name] = 0
		self.assists[player.Name] = 0
	end
	self.damageLog = {}

	-- 모든 플레이어 리스폰
	for _, player in ipairs(Players:GetPlayers()) do
		player:LoadCharacter()
	end

	ReplicatedStorage.MatchUpdate:FireAllClients({
		state = "started",
		matchTime = CONFIG.MATCH_TIME
	})

	-- 게임 시작 알림 이벤트 발생
	ReplicatedStorage.GameStart:FireAllClients()

	self:broadcastGameState()

	print("[MatchController] 매치 시작!")
end

function MatchController:checkTeamWipeout()
	local teamCounts = TeamService:GetTeamCounts()

	-- 한 팀이 전멸했는지 체크
	if teamCounts.TeamA == 0 and teamCounts.TeamB > 0 then
		self:endMatch("TeamB")
	elseif teamCounts.TeamB == 0 and teamCounts.TeamA > 0 then
		self:endMatch("TeamA")
	end
end

function MatchController:endMatch(winningTeam)
	if self.gameState == GameState.ENDED then
		return
	end

	self.gameState = GameState.ENDED

	-- 결과 계산
	local results = {
		winner = winningTeam,
		kills = self.kills,
		deaths = self.deaths,
		assists = self.assists,
		matchTime = tick() - self.matchStartTime
	}

	ReplicatedStorage.GameEnd:FireAllClients(results)
	print("[MatchController] 매치 종료! 승리: " .. (winningTeam or "무승부"))

	-- 종료 카운트다운 시작
	self.endCountdown = CONFIG.RESTART_DELAY
	self:broadcastGameState()

	-- 다음 게임 준비
	task.spawn(function()
		for i = CONFIG.RESTART_DELAY, 1, -1 do
			self.endCountdown = i
			self:broadcastGameState()
			task.wait(1)
		end

		-- 새 게임 시작 준비
		self:resetForNewMatch()
	end)
end

function MatchController:resetForNewMatch()
	self.gameState = GameState.WAITING
	self.matchStartTime = 0
	self.countdownTime = 0
	self.endCountdown = 0

	-- 통계 초기화
	for _, player in ipairs(Players:GetPlayers()) do
		self.kills[player.Name] = 0
		self.deaths[player.Name] = 0
		self.assists[player.Name] = 0
		-- 팀 재배정
		TeamService:AssignTeam(player)
	end
	self.damageLog = {}

	self:broadcastGameState()

	-- 시작 조건 체크
	self:checkStartCondition()

	print("[MatchController] 새 매치 준비 완료")
end

function MatchController:returnToLobby()
	local TeleportService = game:GetService("TeleportService")

	for _, player in ipairs(Players:GetPlayers()) do
		pcall(function()
			TeleportService:Teleport(LOBBY_PLACE_ID, player)
		end)
	end
end

function MatchController:gameLoop()
	while true do
		task.wait(1)

		if self.gameState == GameState.WAITING then
			-- 대기 중 상태 브로드캐스트
			self:broadcastGameState()
			-- 시작 조건 체크
			self:checkStartCondition()
		elseif self.gameState == GameState.PLAYING then
			local elapsed = tick() - self.matchStartTime
			local remaining = CONFIG.MATCH_TIME - elapsed

			-- 시간 업데이트 브로드캐스트
			ReplicatedStorage.MatchUpdate:FireAllClients({
				state = "playing",
				timeRemaining = math.max(0, remaining),
				kills = self.kills,
				deaths = self.deaths,
				assists = self.assists
			})
			self:broadcastGameState()

			-- 시간 종료
			if remaining <= 0 then
				-- 킬 수로 승자 결정
				local teamAKills = 0
				local teamBKills = 0
				local TeamsService = game:GetService("Teams")
				local teamA = TeamsService:FindFirstChild("TeamA")
				local teamB = TeamsService:FindFirstChild("TeamB")

				if teamA then
					for _, player in ipairs(teamA:GetPlayers()) do
						teamAKills = teamAKills + (self.kills[player.Name] or 0)
					end
				end

				if teamB then
					for _, player in ipairs(teamB:GetPlayers()) do
						teamBKills = teamBKills + (self.kills[player.Name] or 0)
					end
				end

				if teamAKills > teamBKills then
					self:endMatch("TeamA")
				elseif teamBKills > teamAKills then
					self:endMatch("TeamB")
				else
					self:endMatch(nil) -- 무승부
				end
			end
		end
	end
end

-- 게임 상태를 수집하는 함수 (로비로 전송용)
function MatchController:getMatchStatus()
	local canStart, reasons, teamCounts = self:getStartConditionStatus()

	-- 팀별 킬 수 계산
	local teamAKills = 0
	local teamBKills = 0
	local playerStats = {}

	for _, player in ipairs(Players:GetPlayers()) do
		local teamName = player.Team and player.Team.Name or "None"
		local kills = self.kills[player.Name] or 0
		local deaths = self.deaths[player.Name] or 0
		local assists = self.assists[player.Name] or 0

		if teamName == "TeamA" then
			teamAKills = teamAKills + kills
		elseif teamName == "TeamB" then
			teamBKills = teamBKills + kills
		end

		table.insert(playerStats, {
			name = player.Name,
			team = teamName,
			kills = kills,
			deaths = deaths,
			assists = assists
		})
	end

	local matchTimeRemaining = 0
	if self.gameState == GameState.PLAYING then
		matchTimeRemaining = CONFIG.MATCH_TIME - (tick() - self.matchStartTime)
	end

	return {
		roomId = self.roomId,
		gameState = self.gameState,
		playerCount = #Players:GetPlayers(),
		maxPlayers = 16,
		-- 시간 정보
		matchTimeRemaining = math.max(0, matchTimeRemaining),
		countdownTime = self.countdownTime or 0,
		endCountdown = self.endCountdown or 0,
		-- 시작 조건 정보
		canStart = canStart,
		reasons = reasons,
		teamCounts = teamCounts,
		-- 팀 스코어
		teamScores = {
			TeamA = teamAKills,
			TeamB = teamBKills
		},
		players = playerStats
	}
end

-- 로비로 상태 브로드캐스트
function MatchController:broadcastLoop()
	while true do
		task.wait(CONFIG.BROADCAST_INTERVAL)

		if isStudio then
			-- 스튜디오에서는 브로드캐스트 스킵
			continue
		end

		local status = self:getMatchStatus()
		local jsonData = HttpService:JSONEncode(status)

		pcall(function()
			MessagingService:PublishAsync(MATCH_STATUS_TOPIC, jsonData)
		end)
	end
end

return MatchController:getInstance()
