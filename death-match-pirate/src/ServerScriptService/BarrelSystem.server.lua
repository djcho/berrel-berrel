local OIL_BARREL_GOLD = 10 
local barrelLevel = 1

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local LoudSpeaker = require(ServerStorage.Classes.LoudSpeaker)
local OilBarrel = require(ServerStorage.Classes.OilBarrel)
local FireBarrel = require(ServerStorage.Classes.FireBarrel)
local NormalBarrel = require(ServerStorage.Classes.NormalBarrel)
local UserData = require(game.ServerStorage.Classes.UserData)

--initalize currentBarrel
local throwingBarrelEvent = game.ReplicatedStorage.ThrowingBarrelEvent
throwingBarrelEvent.OnServerEvent:Connect(function(player, toolName, mouseHitPosition)
	local userData = UserData.ReturnData(player)
	local barrel = nil
	if toolName == "OilBarrel" then
		--if player.leaderstats.Coins.Value < 10 then
		--	local loudSpeaker = LoudSpeaker.new(player)
		--	loudSpeaker:DoTalk("던지기에 필요한 골드가 부족합니다.")
		--	return
		--end
		
		barrel = OilBarrel.new(player, ServerStorage.Parts.OilBarrel, barrelLevel)
		player.leaderstats.Coins.Value -= OIL_BARREL_GOLD
				
	elseif toolName =="FireBarrel" then
		barrel = FireBarrel.new(player, ServerStorage.Parts.FireBarrel, barrelLevel)
	else
		barrel = NormalBarrel.new(player, ServerStorage.Parts.NormalBarrel, barrelLevel)
	end
	
	barrelLevel = 1
	userData.BarrelLevel = barrel.Level
	barrel:Throw(mouseHitPosition)
end)

local requestCurrentBarrel = ReplicatedStorage:WaitForChild("RequestCurrentBarrel")
requestCurrentBarrel.OnServerInvoke = function(player)
	return UserData.ReturnData(player)
end


local requestUpgradeBarrel = ReplicatedStorage.RequestUpgradeBarrel
requestUpgradeBarrel.OnServerInvoke = function(player)
	local loudSpeaker = LoudSpeaker.new(player)
	local userData = UserData.ReturnData(player)
	if userData.BarrelLevel == 4 then
		loudSpeaker:DoTalk("최고 레벨입니다.")
		return false
	end
	
	if player.leaderstats.Coins.Value < 50 then
		loudSpeaker:DoTalk("업그레이드에 필요한 골드가 부족합니다.")
		return false
	end

	player.leaderstats.Coins.Value -= 50
	userData.BarrelLevel += 1
	return true	
end

