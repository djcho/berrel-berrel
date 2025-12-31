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

function GameRoom:JoinPlayer(customTeleportService, playerName, trailShopService)
	local player = game.Players:FindFirstChild(playerName)
	if player then
		-- Trail 데이터 가져오기
		local trailData = nil
		if trailShopService then
			trailData = trailShopService:GetTeleportTrailData(player)
		end

		local teleportData = {
			roomId = self.id,
			serverId = self.serverId,
			placeId = self.placeId,
			trailData = trailData, -- Trail 장착 정보 포함
		}
		customTeleportService:TeleportPlayer(player, self.placeId, teleportData)
	else
		warn("플레이어를 찾을 수 없습니다: " .. playerName)
	end
end


return GameRoom
