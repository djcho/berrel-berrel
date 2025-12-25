local GameRoom = {}
GameRoom.__index = GameRoom

function GameRoom.new(id, serverId, placeId, players, maxPlayersCount, createdTime, metadata)
	local self = setmetatable({}, GameRoom)
	self.id = id
	self.serverId = serverId
	self.placeId = placeId
	self.players = players or {}
	self.maxPlayersCount = maxPlayersCount
	self.createdTime = createdTime or os.time()
	self.metadata = metadata or {}
	return self
end

function GameRoom:AddPlayer(playerName)
	table.insert(self.players, playerName)
end

function GameRoom:RemovePlayer(playerName)
	for i, p in ipairs(self.players) do
		if p == playerName then
			table.remove(self.players, i)
			break
		end
	end
end

function GameRoom:GetPlayerNames()
	return self.players
end

function GameRoom:JoinPlayer(customTeleportService, playerName)
	local player = game.Players:FindFirstChild(playerName)
	if player then
		local teleportData = {
			roomId = self.id,
			serverId = self.serverId,
			placeId = self.placeId
		}
		customTeleportService:TeleportPlayer(player, self.placeId, teleportData)
	else
		warn("플레이어를 찾을 수 없습니다: " .. playerName)
	end
end


return GameRoom
