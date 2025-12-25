-- GameRoomInitializer ModuleScript in ServerScriptService/Controller
local RunService = game:GetService("RunService")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SingletonBase = require(game:GetService("ServerScriptService"):WaitForChild("Common"):WaitForChild("SingletonBase"))
local GameRoomService = require(game:GetService("ServerScriptService"):WaitForChild("Service"):WaitForChild("GameRoomService"))

local GameRoomInitializer = setmetatable({}, { __index = SingletonBase })
GameRoomInitializer.__index = GameRoomInitializer

-- 초기화 함수
function GameRoomInitializer:Initialize()
	self.serverId = nil
	self.roomId = nil
	self.placeId = game.PlaceId
	self.isInitialized = false

	-- 클라이언트에서 서버 ID를 받을 이벤트 설정
	self.serverIdEvent = Instance.new("RemoteEvent")
	self.serverIdEvent.Name = "ServerIdEvent"
	self.serverIdEvent.Parent = ReplicatedStorage

	self.serverIdEvent.OnServerEvent:Connect(function(player, receivedServerId, receivedRoomId, receivedPlaceId)
		self:onServerEvent(player, receivedServerId, receivedRoomId, receivedPlaceId)
	end)
end

-- 플레이어 목록을 업데이트하는 함수
function GameRoomInitializer:updatePlayerCount()
	local players = game.Players:GetPlayers()
	local playerNames = {}

	for _, player in ipairs(players) do
		table.insert(playerNames, player.Name)
	end

	local gameRoomService = GameRoomService:getInstance()

	-- 게임방 데이터를 업데이트합니다.
	local success, message = gameRoomService:UpdateGameRoomData(self.roomId, {
		players = playerNames
	})

	if success then
		print("게임방 데이터가 성공적으로 업데이트되었습니다.")
	else
		warn("게임방 데이터 업데이트 실패: " .. message)
	end
end

-- 서버 ID를 받아 초기화하는 함수
function GameRoomInitializer:onServerEvent(player, receivedServerId, receivedRoomId, receivedPlaceId)
	if not self.isInitialized then
		self.serverId = receivedServerId
		self.roomId = receivedRoomId
		self.placeId = receivedPlaceId
		self.isInitialized = true

		print("서버 ID:", self.serverId)
		print("게임방 ID:", self.roomId)
		print("장소 ID:", self.placeId)

		-- 플레이어 추가 및 제거 이벤트에 대한 핸들러 설정
		game.Players.PlayerAdded:Connect(function()
			self:updatePlayerCount()
		end)

		game.Players.PlayerRemoving:Connect(function()
			self:updatePlayerCount()
		end)

		-- 서버 시작 시 초기화
		self:updatePlayerCount()
	end
end

return GameRoomInitializer:getInstance()
