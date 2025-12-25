local SoundService = game:GetService("SoundService")
local backgroundMusic = SoundService:FindFirstChild("BackgroundMusic")

local function OnChacterAdded(character)
	print(character.Name.." has spawned in the game world")
	backgroundMusic:Play()
end
game.Players.LocalPlayer.CharacterAdded:Connect(OnChacterAdded)


local ReplicatedStorage = game:GetService("ReplicatedStorage")
local remoteEvent = ReplicatedStorage:WaitForChild("PlaySoundEvent")

remoteEvent.OnClientEvent:Connect(function(soundName, startTime, duration)
	local sound = SoundService:FindFirstChild(soundName)
	if sound then
		sound.TimePosition = startTime
		sound:Play()

		-- 특정 시간 후에 사운드를 중지
		task.delay(duration, function()
			sound:Stop()
		end)
	else
		warn("Sound not found: " .. soundName)
	end
end)