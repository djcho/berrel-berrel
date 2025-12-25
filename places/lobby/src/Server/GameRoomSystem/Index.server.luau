local replicatedStorage = game:GetService("ReplicatedStorage")
local runService = game:GetService("RunService")
local isStudio = runService:IsStudio()
local gameRoomService = require(game:GetService("ServerScriptService"):WaitForChild("GameRoomSystem"):WaitForChild("GameRoomService")).new()
local customTeleportService = require(game:GetService("ServerScriptService"):WaitForChild("CustomTeleportService")).new()

-- 설정
local PIRATE_PLACE_ID = 18517272973
local MAX_PLAYERS_PER_ROOM = 16
local LOCK_KEY = "GameRoomCleanupLock"
local LOCK_TIMEOUT = 40

-- 입장 가능한 방 찾기 (자리 있는 방)
local function findAvailableRoom()
	local rooms = gameRoomService:GetAllGameRooms()
	for roomId, room in pairs(rooms) do
		if #room.players < room.maxPlayersCount then
			return room
		end
	end
	return nil
end

-- 새 게임방 생성
local function createNewGameRoom()
	local newRoom = gameRoomService:CreateGameRoom(PIRATE_PLACE_ID, MAX_PLAYERS_PER_ROOM)
	if newRoom then
		print("새로운 게임방 생성됨: " .. newRoom.id)
		return newRoom
	else
		warn("게임방 생성 실패")
		return nil
	end
end

-- 게임이 시작될 때, 입장 가능한 방이 없으면 새 게임방 생성
local function initializeGameRooms()
	local availableRoom = findAvailableRoom()
	if not availableRoom then
		createNewGameRoom()
	else
		print("입장 가능한 게임방 존재: " .. availableRoom.id)
	end
end

-- 게임방 정리 함수 (빈 방 삭제, 최소 1개 유지)
local function cleanupEmptyGameRooms()
	if isStudio then
		print("스튜디오 환경에서는 게임방 정리 작업을 실행하지 않습니다.")
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
		print("게임방 정리 시작")
		gameRoomService:FixInconsistencies()

		local rooms = gameRoomService:GetAllGameRooms()
		local emptyRooms = {}
		local hasAvailableRoom = false

		-- 빈 방과 입장 가능한 방 분류
		for roomId, room in pairs(rooms) do
			if #room.players == 0 then
				table.insert(emptyRooms, roomId)
			elseif #room.players < room.maxPlayersCount then
				hasAvailableRoom = true
			end
		end

		-- 빈 방 정리 (최소 1개는 유지)
		for i, roomId in ipairs(emptyRooms) do
			if i > 1 or hasAvailableRoom then
				gameRoomService:DeleteGameRoom(roomId)
				print("빈 게임방 삭제됨: " .. roomId)
			end
		end

		print("게임방 정리 완료")
	else
		print("이미 정리가 진행 중입니다.")
	end
end

-- 주기적으로 게임방 정리 작업 실행
local function startPeriodicCleanup()
	while true do
		task.wait(10)
		cleanupEmptyGameRooms()
	end
end

-- 게임방 초기화
initializeGameRooms()
gameRoomService:PrintAllGameRooms()

-- 주기적 게임방 정리 시작
if not isStudio then
	task.spawn(startPeriodicCleanup)
end

-- 게임방 목록 요청 처리
replicatedStorage:WaitForChild("RequestGameList").OnServerEvent:Connect(function(player)
	gameRoomService:PrintAllGameRooms()
	replicatedStorage:WaitForChild("UpdateGameList"):FireClient(player, gameRoomService:GetAllGameRooms())
end)

-- 게임방 입장 요청 처리
replicatedStorage:WaitForChild("JoinGameRoom").OnServerEvent:Connect(function(player, roomId)
	if isStudio then
		print("스튜디오 환경에서는 플레이어를 텔레포트하지 않습니다.")
		return
	end

	local room = gameRoomService:GetGameRoom(roomId)
	if not room then
		warn("게임방을 찾을 수 없습니다: " .. roomId)
		return
	end

	-- 방이 가득 찼는지 확인
	if #room.players >= room.maxPlayersCount then
		-- 다른 입장 가능한 방 찾기
		local availableRoom = findAvailableRoom()
		if availableRoom then
			roomId = availableRoom.id
			print("선택한 방이 가득 참, 다른 방으로 이동: " .. roomId)
		else
			-- 입장 가능한 방 없으면 새 방 생성
			local newRoom = createNewGameRoom()
			if newRoom then
				roomId = newRoom.id
				print("모든 방이 가득 참, 새 방 생성: " .. roomId)
			else
				warn("새 게임방 생성 실패")
				return
			end
		end
	end

	-- 게임방 입장 처리
	local success, message = gameRoomService:JoinGameRoom(roomId, player.Name, customTeleportService)
	if success then
		-- 입장 후 모든 방이 가득 찼는지 확인하고 새 방 생성
		local availableRoom = findAvailableRoom()
		if not availableRoom then
			createNewGameRoom()
		end
		replicatedStorage:WaitForChild("UpdateGameList"):FireAllClients(gameRoomService:GetAllGameRooms())
	else
		warn("게임방 입장 실패: " .. message)
	end
end)
