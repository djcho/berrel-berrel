local ServerStorage = game:GetService("ServerStorage")
local SoundService = game:GetService("SoundService")
local getCoinSound = SoundService:WaitForChild("GetCoinSound")
local LoudSpeaker = require(ServerStorage.Scripts.LoudSpeaker)
local db = true
script.Parent.Touched:connect(function(hit)
	if hit.Parent:FindFirstChild("Humanoid") ~= nil then
		if db == true then
			db = false
			script.Parent.Transparency = 1
			local player = game.Players:GetPlayerFromCharacter(hit.Parent)
			player.leaderstats.Coins.Value += 1 * ServerStorage.Configuration.CoinUnit.Value
			
			local loudSpeaker = LoudSpeaker.new(player)
			loudSpeaker:PlayAlone(getCoinSound)
			
			script.Parent.Transparency = 1
			wait(1)
			db = true
			script.Parent:Destroy()
		end
	end	
end)