local soundService = game:GetService("SoundService")
local backgroundMusic = soundService:FindFirstChild("BackgroundMusic")

local function OnChacterAdded(character)
	print(character.Name.." has spawned in the game world")
	backgroundMusic:Play()
end
game.Players.LocalPlayer.CharacterAdded:Connect(OnChacterAdded)