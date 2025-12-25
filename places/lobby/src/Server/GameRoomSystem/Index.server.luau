local replicatedStorage = game:GetService("ReplicatedStorage")
local runService = game:GetService("RunService")
local isStudio = runService:IsStudio()
local gameRoomService = require(game:GetService("ServerScriptService"):WaitForChild("GameRoomSystem"):WaitForChild("GameRoomService")).new()
local customTeleportService = require(game:GetService("ServerScriptService"):WaitForChild("CustomTeleportService")).new()

-- 뮤텍스 잠금 키
local LOCK_KEY = "GameRoomCleanupLock"
local LOCK_TIMEOUT = 40 -- 40초

-- 게임이 시작될 때, 게임방이 하나도 없으면 새 게임방 생성
local function initializeGameRooms()
	local rooms = gameRoomService:GetAllGameRooms()
	if next(rooms) == nil then -- 게임방 목록이 비어있다면
		local placeId = 18517272973 -- 적절한 placeId로 변경하세요
		local newRoom = gameRoomService:CreateGameRoom(placeId, 16)
		if newRoom then
			print("새로운 게임방이 생성되었습니다: " .. newRoom.id)
		else
			warn("새로운 게임방 생성에 실패했습니다.")
		end
	else
		print("기존 게임방이 존재합니다.")
	end
end

-- 게임방 정리 함수
local function cleanupEmptyGameRooms()
	-- 스튜디오 환경에서는 실제로 삭제하지 않음
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

		-- 불일치 수정 함수 호출
		gameRoomService:FixInconsistencies()

		local rooms = gameRoomService:GetAllGameRooms()
		local roomCount = 0

		for roomId, room in pairs(rooms) do
			if #room.players == 0 then
				if roomCount > 0 then
					gameRoomService:DeleteGameRoom(roomId)
					print("빈 게임방 삭제됨: " .. roomId)
				else
					roomCount = roomCount + 1
				end
			end
		end

		print("게임방 정리 완료")
	else
		print("이미 정리가 진행 중입니다.")
	end
end

-- 주기적으로 게임방 정리 작업 실행 (20초마다)
local function startPeriodicCleanup()
	while true do
		wait(10)
		cleanupEmptyGameRooms()
	end
end

-- 게임방 초기화 호출
initializeGameRooms()
gameRoomService:PrintAllGameRooms()

-- 주기적 게임방 정리 시작
if not isStudio then
	task.spawn(startPeriodicCleanup)
end

-- 서버로부터 게임방 목록 업데이트 신호 수신
replicatedStorage:WaitForChild("RequestGameList").OnServerEvent:Connect(function(player)
	gameRoomService:PrintAllGameRooms()
	replicatedStorage:WaitForChild("UpdateGameList"):FireClient(player, gameRoomService:GetAllGameRooms())
end)

-- 게임방 입장 요청 시 처리
replicatedStorage:WaitForChild("JoinGameRoom").OnServerEvent:Connect(function(player, roomId)
	local room = gameRoomService:GetGameRoom(roomId)
	if room then
		-- 스튜디오 환경에서는 실제로 텔레포트하지 않음
		if isStudio then
			print("스튜디오 환경에서는 플레이어를 텔레포트하지 않습니다.")
			return
		end

		-- 해당 게임방으로 플레이어를 텔레포트
		local success, message = gameRoomService:JoinGameRoom(roomId, player.Name, customTeleportService)
		if success then
			replicatedStorage:WaitForChild("UpdateGameList"):FireAllClients(gameRoomService:GetAllGameRooms())
		else
			warn("플레이어를 게임방으로 텔레포트하는 데 실패했습니다: " .. message)
		end
	else
		warn("게임방을 찾을 수 없습니다: " .. roomId)
	end
end)

-- 코드 주석 추가
-- initializeGameRooms: 서버 시작 시 게임방 초기화 함수. 게임방이 없을 경우 새 게임방을 생성합니다.
-- gameRoomService:PrintAllGameRooms: 현재 존재하는 모든 게임방 정보를 출력합니다.
-- cleanupEmptyGameRooms: 빈 게임방을 정리하는 함수입니다. 뮤텍스를 사용하여 여러 서버에서 동시에 실행되지 않도록 합니다.
-- startPeriodicCleanup: 주기적으로 cleanupEmptyGameRooms 함수를 호출하여 빈 게임방을 정리합니다.
-- OnServerEvent 연결: RequestGameList 이벤트 수신 시, 모든 게임방 목록을 요청한 클라이언트에게 전송합니다.
-- OnServerEvent 연결: JoinGameRoom 이벤트 수신 시, 해당 게임방으로 플레이어를 텔레포트합니다. 스튜디오 환경에서는 실제로 텔레포트하지 않습니다.
