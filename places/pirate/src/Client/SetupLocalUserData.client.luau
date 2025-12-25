local Player = game.Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalUserData = require(game.ReplicatedStorage.Classes.LocalUserData)

Player.CharacterAdded:Connect(function()
	local Data = 
		{
			Shopping = false, 
		}
	
	local localUserData = LocalUserData.AddPlayer(Player, Data)
end)

Player.CharacterRemoving:Connect(function()
	local localUserData = LocalUserData.RemovePlayer(Player)
end)