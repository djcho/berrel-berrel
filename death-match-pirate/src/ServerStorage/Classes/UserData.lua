local UserData = {}
local PlayerData = {}

function UserData.AddPlayer(Player, Data) -- adds a player to the PlayerData Table (Do this when a player joins)
	PlayerData[Player] = Data
end

function UserData.ReturnData(Player) -- Retrieves a player's data from the PlayerData Table 
	return PlayerData[Player]
end

function UserData.RemovePlayer(Player) -- Removes a player from the PlayerData Table (Do this when a player leaves)
	PlayerData[Player] = nil
end

function UserData.UpdateData(Player, Data)
	PlayerData[Player] = Data
end

return UserData
