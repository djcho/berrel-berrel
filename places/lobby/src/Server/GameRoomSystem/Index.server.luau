local replicatedStorage = game:GetService("ReplicatedStorage")
local runService = game:GetService("RunService")
local MessagingService = game:GetService("MessagingService")
local HttpService = game:GetService("HttpService")
local ServerScriptService = game:GetService("ServerScriptService")
local isStudio = runService:IsStudio()
local gameRoomService = require(ServerScriptService:WaitForChild("GameRoomSystem"):WaitForChild("GameRoomService")).new()
local customTeleportService = require(ServerScriptService:WaitForChild("CustomTeleportService")).new()
local coinService = require(ServerScriptService:WaitForChild("Service"):WaitForChild("CoinService")).getInstance()
local trailShopService = require(ServerScriptService:WaitForChild("Service"):WaitForChild("TrailShopService")).getInstance()

-- CoinService 초기화
coinService:Initialize()

-- TrailShopService 초기화
trailShopService:Initialize()

-- 설정
local PIRATE_PLACE_ID = 18517272973
local MAX_PLAYERS_PER_ROOM = 16
local LOCK_KEY = "GameRoomCleanupLock"
local LOCK_TIMEOUT = 40
local MATCH_STATUS_TOPIC = "MatchStatus"
local COIN_REWARD_TOPIC = "CoinReward"

-- 실시간 게임 상태 캐시 (roomId -> status)
local liveMatchStatus = {}

-- 자동 스케일링 설정
local SCALE_UP_THRESHOLD = 0.75  -- 75% 차면 새 방 생성
local SCALE_DOWN_THRESHOLD = 0.25  -- 25% 이하면 병합 고려

-- RemoteEvent 생성 (클라이언트보다 먼저 생성되어야 함)
local function ensureRemoteEvents()
	local events = {"RequestGameList", "JoinGameRoom", "UpdateGameList", "ShowGameRoomGui", "QuickJoin", "MatchStatus", "LiveMatchUpdate"}
	for _, eventName in ipairs(events) do
		if not replicatedStorage:FindFirstChild(eventName) then
			local event = Instance.new("RemoteEvent")
			event.Name = eventName
			event.Parent = replicatedStorage
		end
	end
end

ensureRemoteEvents()

-- MessagingService 구독 (Pirate에서 보내는 실시간 게임 상태 수신)
if not isStudio then
	pcall(function()
		MessagingService:SubscribeAsync(MATCH_STATUS_TOPIC, function(message)
			local success, data = pcall(function()
				return HttpService:JSONDecode(message.Data)
			end)

			if success and data then
				-- 캐시에 저장
				liveMatchStatus[data.roomId] = data

				-- 모든 클라이언트에 브로드캐스트
				replicatedStorage.LiveMatchUpdate:FireAllClients(data)
			end
		end)
		print("[Lobby] MatchStatus 구독 완료")
	end)

	-- 코인 보상 수신 구독
	pcall(function()
		MessagingService:SubscribeAsync(COIN_REWARD_TOPIC, function(message)
			local success, data = pcall(function()
				return HttpService:JSONDecode(message.Data)
			end)

			if success and data and data.rewards then
				print("[Lobby] 코인 보상 수신:", data.roomId)
				for _, reward in ipairs(data.rewards) do
					local userId = reward.odIresU -- UserId
					local coins = reward.coins or 0
					if userId and coins > 0 then
						coinService:AddCoinsByUserId(userId, coins)
					end
				end
			end
		end)
		print("[Lobby] CoinReward 구독 완료")
	end)
end

-- 최적의 방 찾기 (가장 인원이 많은 방 우선)
local function findBestRoom()
	local rooms = gameRoomService:GetAllGameRooms()
	local bestRoom = nil
	local maxPlayers = -1

	for _, room in pairs(rooms) do
		local playerCount = #room.players
		if playerCount < room.maxPlayersCount and playerCount > maxPlayers then
			maxPlayers = playerCount
			bestRoom = room
		end
	end

	return bestRoom
end

-- 새 게임방 생성
local function createNewGameRoom()
	local newRoom = gameRoomService:CreateGameRoom(PIRATE_PLACE_ID, MAX_PLAYERS_PER_ROOM)
	if newRoom then
		print("[AutoMatch] 새로운 게임방 생성됨: " .. newRoom.id)
		return newRoom
	else
		warn("[AutoMatch] 게임방 생성 실패")
		return nil
	end
end

-- 자동 스케일링 체크 (방이 75% 이상 차면 새 방 생성)
local function checkAutoScaling()
	local rooms = gameRoomService:GetAllGameRooms()
	local allRoomsFull = true

	for _, room in pairs(rooms) do
		local fillRate = #room.players / room.maxPlayersCount
		if fillRate < SCALE_UP_THRESHOLD then
			allRoomsFull = false
			break
		end
	end

	-- 모든 방이 75% 이상 차면 새 방 생성
	if allRoomsFull then
		print("[AutoMatch] 모든 방이 " .. (SCALE_UP_THRESHOLD * 100) .. "% 이상 참, 새 방 생성")
		createNewGameRoom()
	end
end

-- 빈 방 정리 (25% 이하인 방 병합 및 삭제)
local function cleanupAndMergeRooms()
	if isStudio then
		return
	end

	local success, lock = pcall(function()
		return gameRoomService.dataStore:UpdateAsync(LOCK_KEY, function(currentValue)
			if currentValue == nil or currentValue < os.time() then
				return os.time() + LOCK_TIMEOUT
			else
				return nil
			end
		end)
	end)

	if success and lock then
		gameRoomService:FixInconsistencies()

		local rooms = gameRoomService:GetAllGameRooms()
		local lowPopRooms = {}
		local emptyRooms = {}
		local hasAvailableRoom = false
		local roomCount = 0

		-- 방 분류
		for roomId, room in pairs(rooms) do
			roomCount = roomCount + 1
			local playerCount = #room.players
			local fillRate = playerCount / room.maxPlayersCount

			if playerCount == 0 then
				table.insert(emptyRooms, roomId)
			elseif fillRate <= SCALE_DOWN_THRESHOLD then
				table.insert(lowPopRooms, {id = roomId, players = playerCount})
			else
				hasAvailableRoom = true
			end
		end

		-- 빈 방 정리 (최소 1개는 유지)
		for i, roomId in ipairs(emptyRooms) do
			if roomCount > 1 and (i > 1 or hasAvailableRoom) then
				gameRoomService:DeleteGameRoom(roomId)
				roomCount = roomCount - 1
				print("[AutoMatch] 빈 게임방 삭제됨: " .. roomId)
			end
		end

		-- 인원이 적은 방들 병합 고려 (추후 구현)
		-- TODO: lowPopRooms의 플레이어들을 다른 방으로 이동시키고 방 삭제
	end
end

-- 게임방 초기화
local function initializeGameRooms()
	local bestRoom = findBestRoom()
	if not bestRoom then
		createNewGameRoom()
	else
		print("[AutoMatch] 입장 가능한 게임방 존재: " .. bestRoom.id)
	end
end

-- 주기적 작업 실행
local function startPeriodicTasks()
	while true do
		task.wait(10)
		cleanupAndMergeRooms()
		checkAutoScaling()
	end
end

-- 빠른 참가 처리 (자동으로 최적의 방 배정)
local function handleQuickJoin(player)
	print("[AutoMatch] " .. player.Name .. " 빠른 참가 요청")

	-- 스튜디오 환경 체크
	if isStudio then
		print("[AutoMatch] 스튜디오 환경 - 매칭 시뮬레이션")
		replicatedStorage.MatchStatus:FireClient(player, {
			status = "matched",
			message = "매칭 완료! (스튜디오 모드)"
		})
		return
	end

	-- 최적의 방 찾기
	local targetRoom = findBestRoom()

	-- 입장 가능한 방이 없으면 새 방 생성
	if not targetRoom then
		targetRoom = createNewGameRoom()
		if not targetRoom then
			replicatedStorage.MatchStatus:FireClient(player, {
				status = "error",
				message = "방 생성에 실패했습니다."
			})
			return
		end
	end

	-- 매칭 상태 알림
	replicatedStorage.MatchStatus:FireClient(player, {
		status = "matching",
		message = "게임을 찾는 중...",
		playerCount = #targetRoom.players,
		maxPlayers = targetRoom.maxPlayersCount
	})

	-- 게임방 입장 처리
	local success, message = gameRoomService:JoinGameRoom(targetRoom.id, player.Name, customTeleportService, trailShopService)

	if success then
		-- 입장 성공
		replicatedStorage.MatchStatus:FireClient(player, {
			status = "matched",
			message = "게임에 참가합니다!"
		})

		-- 자동 스케일링 체크
		checkAutoScaling()

		-- 모든 클라이언트에 방 목록 업데이트
		replicatedStorage.UpdateGameList:FireAllClients(gameRoomService:GetAllGameRooms())
	else
		replicatedStorage.MatchStatus:FireClient(player, {
			status = "error",
			message = "입장 실패: " .. (message or "알 수 없는 오류")
		})
	end
end

-- 초기화
initializeGameRooms()
gameRoomService:PrintAllGameRooms()

-- 주기적 작업 시작
if not isStudio then
	task.spawn(startPeriodicTasks)
end

-- 빠른 참가 요청 처리 (새로운 방식)
replicatedStorage.QuickJoin.OnServerEvent:Connect(handleQuickJoin)

-- 방 목록과 실시간 상태를 합쳐서 전송
local function getRoomsWithLiveStatus()
	local rooms = gameRoomService:GetAllGameRooms()
	local roomsWithStatus = {}

	for roomId, roomData in pairs(rooms) do
		local liveData = liveMatchStatus[roomId]

		-- 스튜디오에서 테스트용 Mock 데이터 (실시간 데이터가 없을 때)
		if isStudio and not liveData then
			liveData = {
				roomId = roomId,
				gameState = "waiting",
				playerCount = #roomData.players,
				maxPlayers = roomData.maxPlayersCount,
				matchTimeRemaining = 0,
				countdownTime = 0,
				endCountdown = 0,
				canStart = false,
				reasons = {"플레이어 2명 필요 (현재 " .. #roomData.players .. "명)"},
				teamCounts = { TeamA = 0, TeamB = 0 },
				teamScores = { TeamA = 0, TeamB = 0 },
			}
		end

		roomsWithStatus[roomId] = {
			-- 기본 정보
			id = roomData.id,
			placeId = roomData.placeId,
			players = roomData.players,
			maxPlayersCount = roomData.maxPlayersCount,
			accessCode = roomData.accessCode,
			-- 실시간 정보 (있으면 추가)
			liveStatus = liveData or nil
		}
	end

	return roomsWithStatus
end

-- 기존 방식도 유지 (호환성)
replicatedStorage.RequestGameList.OnServerEvent:Connect(function(player)
	replicatedStorage.UpdateGameList:FireClient(player, getRoomsWithLiveStatus())
end)

replicatedStorage.JoinGameRoom.OnServerEvent:Connect(function(player, roomId)
	if isStudio then
		print("[AutoMatch] 스튜디오 환경에서는 텔레포트하지 않습니다.")
		return
	end

	local room = gameRoomService:GetGameRoom(roomId)
	if not room then
		-- 방이 없으면 빠른 참가로 전환
		handleQuickJoin(player)
		return
	end

	-- 방이 가득 찼으면 빠른 참가로 전환
	if #room.players >= room.maxPlayersCount then
		handleQuickJoin(player)
		return
	end

	-- 게임방 입장 처리
	local success, message = gameRoomService:JoinGameRoom(roomId, player.Name, customTeleportService, trailShopService)
	if success then
		checkAutoScaling()
		replicatedStorage.UpdateGameList:FireAllClients(gameRoomService:GetAllGameRooms())
	else
		warn("[AutoMatch] 게임방 입장 실패: " .. (message or "알 수 없는 오류"))
	end
end)
