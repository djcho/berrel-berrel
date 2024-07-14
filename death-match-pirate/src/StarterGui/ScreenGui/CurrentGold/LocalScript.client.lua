local player = game.Players.LocalPlayer

function updateGold()
	script.Parent.Text = "골드 : "..player.leaderstats.Coins.Value
end

player.leaderstats.Coins.Changed:Connect(updateGold)