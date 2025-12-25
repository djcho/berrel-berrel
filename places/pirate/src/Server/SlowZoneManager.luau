-- ZoneManager ModuleScript
local SlowZoneManager = {}

SlowZoneManager.playersInZone = {}

function SlowZoneManager:setPlayerSpeed(player, speed)
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = speed
	end
end

function SlowZoneManager:playerEnteredZone(player)
	print("zone enter")
	if not self.playersInZone[player] then
		self.playersInZone[player] = 0
	end
	self.playersInZone[player] = self.playersInZone[player] + 1
	if self.playersInZone[player] == 1 then
		self:setPlayerSpeed(player, 5)
		print(player.Name .. " entered a zone. Slowing down.")
	end
end

function SlowZoneManager:playerExitedZone(player)
	if self.playersInZone[player] then
		self.playersInZone[player] = self.playersInZone[player] - 1
		if self.playersInZone[player] == 0 then
			self:setPlayerSpeed(player, 16)
			print(player.Name .. " exited all zones. Speed restored.")
		end
	end
end

return SlowZoneManager
