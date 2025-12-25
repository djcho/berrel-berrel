-- GameRoomInitializer ModuleScript in ServerScriptService/Controller
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local SingletonBase = require(game:GetService("ServerScriptService"):WaitForChild("Common"):WaitForChild("SingletonBase"))
local GameRoomService = require(game:GetService("ServerScriptService"):WaitForChild("Service"):WaitForChild("GameRoomService"))

local GameRoomInitializer = setmetatable({}, { __index = SingletonBase })
GameRoomInitializer.__index = GameRoomInitializer

local isStudio = RunService:IsStudio()

-- 초기화 함수
function GameRoomInitializer:Initialize()
	self.serverId = nil
	self.roomId = nil
	self.placeId = game.PlaceId
	self.isInitialized = false

	-- ServerIdEvent 생성 (클라이언트 호환성용)
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	if not ReplicatedStorage:FindFirstChild("ServerIdEvent") then
		local serverIdEvent = Instance.new("RemoteEvent")
		serverIdEvent.Name = "ServerIdEvent"
		serverIdEvent.Parent = ReplicatedStorage
	end

	-- 플레이어 추가 이벤트 - 텔레포트 데이터에서 roomId 가져오기
	Players.PlayerAdded:Connect(function(player)
		self:onPlayerAdded(player)
	end)

	-- 플레이어 제거 이벤트
	Players.PlayerRemoving:Connect(function(player)
		self:onPlayerRemoving(player)
	end)
end

-- 플레이어 목록을 업데이트하는 함수
function GameRoomInitializer:updatePlayerCount()
	if not self.roomId then
		return
	end

	local players = Players:GetPlayers()
	local playerNames = {}

	for _, player in ipairs(players) do
		table.insert(playerNames, player.Name)
	end

	-- 게임방 데이터를 업데이트합니다.
	local success, message = GameRoomService:UpdateGameRoomData(self.roomId, {
		players = playerNames
	})

	if success then
		print("게임방 플레이어 목록 업데이트됨:", #playerNames, "명")
	else
		warn("게임방 데이터 업데이트 실패: " .. message)
	end
end

-- 플레이어 추가 시 처리
function GameRoomInitializer:onPlayerAdded(player)
	-- 서버에서 직접 텔레포트 데이터 가져오기
	local joinData = player:GetJoinData()
	local teleportData = joinData and joinData.TeleportData

	if not self.isInitialized then
		if isStudio then
			-- 스튜디오 환경에서는 Mock 데이터 사용
			local jobId = game.JobId
			self.serverId = "mock_server_id_" .. (jobId ~= "" and jobId or "studio")
			self.roomId = "mock_room_id_studio"
			self.placeId = game.PlaceId
			print("[Studio Mode] Mock 데이터 사용")
		elseif teleportData and teleportData.roomId then
			self.serverId = teleportData.serverId
			self.roomId = teleportData.roomId
			self.placeId = teleportData.placeId or game.PlaceId
		end

		if self.roomId then
			self.isInitialized = true
			print("GameRoom 초기화됨 - Room ID:", self.roomId)
		end
	end

	-- 플레이어 카운트 업데이트
	self:updatePlayerCount()
end

-- 플레이어 제거 시 처리
function GameRoomInitializer:onPlayerRemoving(player)
	-- 약간의 지연 후 업데이트 (플레이어가 목록에서 제거된 후)
	task.delay(0.1, function()
		self:updatePlayerCount()
	end)
end

return GameRoomInitializer:getInstance()
