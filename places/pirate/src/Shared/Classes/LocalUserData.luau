local LocalUserData = {}
local PlayerData = {}

function LocalUserData.AddPlayer(Player, Data) -- adds a player to the PlayerData Table (Do this when a player joins)
	PlayerData[Player] = Data
end

function LocalUserData.ReturnData(Player) -- Retrieves a player's data from the PlayerData Table 
	return PlayerData[Player]
end

function LocalUserData.RemovePlayer(Player) -- Removes a player from the PlayerData Table (Do this when a player leaves)
	PlayerData[Player] = nil
end

function LocalUserData.UpdateData(Player, Data)
	PlayerData[Player] = Data
end

return LocalUserData
