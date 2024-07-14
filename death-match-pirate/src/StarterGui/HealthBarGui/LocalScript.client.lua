-- Disable the healthBar
game.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)

-- Variables
local player = game.Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()

local healthBar = script.Parent:WaitForChild("HealthBar")

-- Update the Health Bar
game:GetService("RunService").RenderStepped:Connect(function()
	local humanoid = char:WaitForChild("Humanoid")
	healthBar.HealthStatus.Text = math.floor(humanoid.Health)
	
	local hp = math.clamp(humanoid.Health/humanoid.MaxHealth,0,1)
	game:GetService("TweenService"):Create(healthBar.GreenFrame, TweenInfo.new(0.1, Enum.EasingStyle.Quad),
	{
		Size =  UDim2.new(humanoid.Health/humanoid.MaxHealth,0,1,0),
		BackgroundColor3 = Color3.fromHSV(hp/3,1,1),
	}
	):Play()
end)


local function blinkHealthBar()
	local healthBar =  script.Parent:WaitForChild("HealthBar")
	local originBorderColor = healthBar.BorderColor3
	
	healthBar.BorderColor3 = Color3.new(1, 0, 0)
	wait(0.1)
	healthBar.BorderColor3 = originBorderColor
end

local humanoid = char:WaitForChild("Humanoid")
local OldHealth = humanoid.Health
humanoid:GetPropertyChangedSignal("Health"):Connect(function()
	if humanoid.Health < OldHealth then
		blinkHealthBar()
	end

	OldHealth = humanoid.Health
end)