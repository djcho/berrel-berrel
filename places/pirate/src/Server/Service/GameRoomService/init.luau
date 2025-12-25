local DataStoreService = game:GetService("DataStoreService")
local isStudio = game:GetService("RunService"):IsStudio()
local HttpService = game:GetService("HttpService")
local GameRoom = require(script:WaitForChild("GameRoom"))
local SingletonBase = require(game:GetService("ServerScriptService"):WaitForChild("Common"):WaitForChild("SingletonBase"))

local GameRoomService = setmetatable({}, { __index = SingletonBase })
GameRoomService.__index = GameRoomService

local GAME_ROOMS_DATASTORE_PREFIX = "GameRoom_"
local GAME_ROOMS_LIST_KEY = "GameRoomList"

local function getDataStore()
	if isStudio then
		return require(script:WaitForChild("MockDataStore")).new()
	else
		return DataStoreService:GetDataStore("GameRoomsDataStore")
	end
end

-- 초기화 함수 (싱글톤 패턴)
function GameRoomService:Initialize()
	self.dataStore = getDataStore()
end

-- 고유한 게임방 ID 생성
function GameRoomService:GenerateUniqueRoomId()
	return HttpService:GenerateGUID(false)
end

-- 게임방 ID 목록 업데이트
function GameRoomService:UpdateGameRoomList(roomId, add)
	local success, errorMessage = pcall(function()
		local roomList = self.dataStore:GetAsync(GAME_ROOMS_LIST_KEY) or {}
		if add then
			if not table.find(roomList, roomId) then
				table.insert(roomList, roomId)
			end
		else
			for i, id in ipairs(roomList) do
				if id == roomId then
					table.remove(roomList, i)
					break
				end
			end
		end
		self.dataStore:SetAsync(GAME_ROOMS_LIST_KEY, roomList)
	end)

	if not success then
		warn("Failed to update game room list: " .. errorMessage)
	end
end

-- 데이터스토어에 게임방 저장
function GameRoomService:SaveGameRoomToDataStore(room)
	local roomData = {
		serverId = room.serverId,
		placeId = room.placeId,
		players = room.players,
		maxPlayersCount = room.maxPlayersCount,
		createdTime = room.createdTime,
		metadata = room.metadata,
	}
	local success, errorMessage = pcall(function()
		local jsonData = HttpService:JSONEncode(roomData)
		self.dataStore:SetAsync(GAME_ROOMS_DATASTORE_PREFIX .. room.id, jsonData)
	end)

	if not success then
		warn("Failed to save game room: " .. errorMessage)
	else
		self:UpdateGameRoomList(room.id, true)
	end
end

-- 데이터스토어에서 게임방 로드
function GameRoomService:GetGameRoomFromDataStore(roomId)
	local success, jsonData = pcall(function()
		return self.dataStore:GetAsync(GAME_ROOMS_DATASTORE_PREFIX .. roomId)
	end)

	if success and jsonData then
		local roomData = HttpService:JSONDecode(jsonData)
		-- 기존 데이터 호환성을 위해 새로운 필드에 기본값 설정
		roomData.createdTime = roomData.createdTime or os.time()
		roomData.metadata = roomData.metadata or {}

		local room = GameRoom.new(
			roomId,
			roomData.serverId,
			roomData.placeId,
			roomData.players,
			roomData.maxPlayersCount,
			roomData.createdTime,
			roomData.metadata
		)

		return room
	else
		warn("Failed to load game room: " .. (jsonData or "Unknown error"))
		return nil
	end
end

-- 데이터스토어에서 게임방 삭제
function GameRoomService:DeleteGameRoomFromDataStore(roomId)
	local success, errorMessage = pcall(function()
		self.dataStore:RemoveAsync(GAME_ROOMS_DATASTORE_PREFIX .. roomId)
	end)

	if not success then
		warn("Failed to delete game room: " .. errorMessage)
	else
		self:UpdateGameRoomList(roomId, false)
	end
end

-- 불일치 확인 및 수정 함수
function GameRoomService:FixInconsistencies()
	local success, roomList = pcall(function()
		return self.dataStore:GetAsync(GAME_ROOMS_LIST_KEY) or {}
	end)

	if not success then
		warn("Failed to get game room list: " .. roomList)
		return
	end

	local fixedRoomList = {}

	for _, roomId in ipairs(roomList) do
		local room = self:GetGameRoomFromDataStore(roomId)
		if room then
			table.insert(fixedRoomList, roomId)
		else
			warn("Game room ID in list but no data found: " .. roomId)
		end
	end

	-- 업데이트된 게임방 목록을 데이터스토어에 저장
	local success, errorMessage = pcall(function()
		self.dataStore:SetAsync(GAME_ROOMS_LIST_KEY, fixedRoomList)
	end)

	if not success then
		warn("Failed to update game room list after fixing inconsistencies: " .. errorMessage)
	end
end

-- 게임방 생성 메서드
-- @param placeId 플레이스 ID
-- @param maxPlayers 최대 플레이어 수
-- @param metadata 추가 메타 데이터
-- @return 생성된 게임방 객체
function GameRoomService:CreateGameRoom(placeId, maxPlayers, metadata)
	assert(placeId, "Place ID는 필수입니다.")
	assert(maxPlayers, "최대 플레이어 수는 필수입니다.")

	local roomId = self:GenerateUniqueRoomId()

	-- 인스턴스 서버 생성 및 서버 ID 확보
	local serverId
	if isStudio then
		-- 스튜디오 환경에서는 서버 예약을 시뮬레이션
		serverId = "mock_server_id_" .. roomId
	else
		local success, result = pcall(function()
			return game:GetService("TeleportService"):ReserveServer(placeId)
		end)

		if success then
			serverId = result
		else
			warn("Failed to reserve server: " .. result)
			return nil
		end
	end

	-- 게임방 객체 생성
	local newRoom = GameRoom.new(roomId, serverId, placeId, {}, maxPlayers)
	newRoom.createdTime = os.time()  -- 생성 시간 추가
	newRoom.metadata = metadata or {}  -- 메타 데이터 추가

	-- 게임방 데이터스토어에 저장
	self:SaveGameRoomToDataStore(newRoom)

	return newRoom
end

-- 게임방 삭제 메서드
-- @param id 게임방 ID
function GameRoomService:DeleteGameRoom(id)
	assert(id, "ID는 필수입니다.")
	-- 데이터스토어에서 게임방 삭제
	self:DeleteGameRoomFromDataStore(id)
end

-- 게임방 조회 메서드
-- @param id 게임방 ID
-- @return 조회된 게임방 객체
function GameRoomService:GetGameRoom(id)
	assert(id, "ID는 필수입니다.")
	return self:GetGameRoomFromDataStore(id)
end

-- 모든 게임방 조회 메서드
-- @return 모든 게임방 객체 리스트
function GameRoomService:GetAllGameRooms()
	local gameRooms = {}

	local success, roomList = pcall(function()
		return self.dataStore:GetAsync(GAME_ROOMS_LIST_KEY) or {}
	end)

	if success then
		for _, roomId in ipairs(roomList) do
			local room = self:GetGameRoomFromDataStore(roomId)
			if room then
				gameRooms[roomId] = room
			end
		end
	else
		warn("Failed to get all game rooms:", roomList)
	end

	return gameRooms
end

-- 모든 게임 방 정보 출력 메서드
function GameRoomService:PrintAllGameRooms()
	local gameRooms = self:GetAllGameRooms()
	local i = 0
	for key, room in pairs(gameRooms) do
		print("Room ID:", key)
		print("\tServer ID:", room.serverId)
		print("\tPlace ID:", room.placeId)
		print("\tPlayers:", table.concat(room.players, ", "))
		print("\tMax Players Count:", room.maxPlayersCount)
		print("\tCreated Time:", os.date('%Y-%m-%d %H:%M:%S', room.createdTime))
		print("\tMetadata:", HttpService:JSONEncode(room.metadata))
		print("-----")
		i = i + 1
	end

	print("Total Game Rooms:", i)
end

-- 게임방 참가 메서드
-- @param roomId 게임방 ID
-- @param playerName 플레이어 이름
-- @param customTeleportService 커스텀 텔레포트 서비스 인스턴스
-- @return 성공 여부와 메시지
function GameRoomService:JoinGameRoom(roomId, playerName, customTeleportService)
	assert(roomId, "Room ID는 필수입니다.")
	assert(playerName, "Player는 필수입니다.")
	assert(customTeleportService, "CustomTeleportService 인스턴스는 필수입니다.")

	local room = self:GetGameRoomFromDataStore(roomId)
	if not room then
		return false, "게임방을 찾을 수 없습니다."
	end

	if #room.players >= room.maxPlayersCount then
		return false, "게임방이 가득 찼습니다."
	end

	room:AddPlayer(playerName)
	self:SaveGameRoomToDataStore(room)
	
	room:JoinPlayer(customTeleportService, playerName);

	return true, "게임방에 성공적으로 참가했습니다."
end


-- 게임방 데이터 업데이트 메서드 (원자적 업데이트)
-- @param roomId 게임방 ID
-- @param updatedData 갱신할 데이터 테이블 (키-값 쌍)
-- @return 성공 여부와 메시지
function GameRoomService:UpdateGameRoomData(roomId, updatedData)
	assert(roomId, "Room ID는 필수입니다.")
	assert(type(updatedData) == "table", "updatedData는 테이블이어야 합니다.")

	local success, result = pcall(function()
		return self.dataStore:UpdateAsync(GAME_ROOMS_DATASTORE_PREFIX .. roomId, function(currentData)
			if not currentData then
				return nil
			end

			local roomData = HttpService:JSONDecode(currentData)

			-- 기존 데이터 갱신
			for key, value in pairs(updatedData) do
				if roomData[key] ~= nil then
					roomData[key] = value
				else
					warn("Invalid key in updatedData: " .. key)
				end
			end

			return HttpService:JSONEncode(roomData)
		end)
	end)

	if success and result then
		return true, "게임방 데이터가 성공적으로 업데이트되었습니다."
	else
		return false, "게임방 데이터 업데이트 실패: " .. tostring(result)
	end
end


return GameRoomService:getInstance()
