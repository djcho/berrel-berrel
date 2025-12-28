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
	local soundTemplate = SoundService:FindFirstChild(soundName)
	if soundTemplate then
		-- Clone하여 동시에 여러 번 재생 가능하게 함
		local sound = soundTemplate:Clone()
		sound.Parent = SoundService
		sound.TimePosition = startTime
		sound:Play()

		-- 재생 완료 후 또는 duration 후 삭제
		task.delay(duration, function()
			sound:Stop()
			sound:Destroy()
		end)
	else
		warn("Sound not found: " .. soundName)
	end
end)