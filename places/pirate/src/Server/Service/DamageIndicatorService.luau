-- DamageIndicatorService ModuleScript in ServerScriptService/Scripts/Service
local SingletonBase = require(game.ServerScriptService.Service.Core.SingletonBase)

local DamageIndicatorService = setmetatable({}, { __index = SingletonBase })
DamageIndicatorService.__index = DamageIndicatorService

local tweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut)

local damageForColours = 
	{
		[25] = Color3.fromRGB(255, 145, 66),
		[50] = Color3.fromRGB(255, 98, 67),
		[75] = Color3.fromRGB(255, 55, 48),
		[100] = Color3.fromRGB(255, 0, 0),
	}

function DamageIndicatorService:Initialize()
	Players.PlayerAdded:Connect(function(plr)
		plr.CharacterAdded:Connect(function(char)
			self:OnCharacterAdded(char)
		end)
	end)
end

function DamageIndicatorService:OnCharacterAdded(char)
	local humanoid = char:WaitForChild("Humanoid")
	local currentHealth = humanoid.Health

	humanoid.HealthChanged:Connect(function(health)
		self:OnHealthChanged(humanoid, health, currentHealth)
		currentHealth = health
	end)
end

function DamageIndicatorService:OnHealthChanged(humanoid, health, currentHealth)
	if health < currentHealth and humanoid:GetState() ~= Enum.HumanoidStateType.Dead then

		local healthLost = math.floor(currentHealth - health)
		local damageIndicatorGui = Instance.new("BillboardGui")
		damageIndicatorGui.AlwaysOnTop = true				
		damageIndicatorGui.Size = UDim2.new(2, 0, 2, 0)

		local offsetX = math.random(-10, 10)/10
		local offsetY = math.random(-10, 10)/10
		local offsetZ = math.random(-10, 10)/10
		damageIndicatorGui.StudsOffset = Vector3.new(offsetX, offsetY, offsetZ)

		local damageIndicatorLabel = Instance.new("TextLabel")

		damageIndicatorLabel.AnchorPoint = Vector2.new(0.5, 0.5)
		damageIndicatorLabel.Position = UDim2.new(0.5, 0, 0.5, 0)

		damageIndicatorLabel.TextScaled = true
		damageIndicatorLabel.BackgroundTransparency = 1
		damageIndicatorLabel.Font = Enum.Font.GothamBlack

		damageIndicatorLabel.Text = healthLost

		damageIndicatorLabel.Size = UDim2.new(0, 0, 0, 0)

		for damage, colour in pairs(damageForColours) do
			if healthLost <= damage then 
				damageIndicatorLabel.TextColor3 = colour
				break
			end
		end

		damageIndicatorLabel.Parent = damageIndicatorGui				
		damageIndicatorGui.Parent = humanoid.Parent:WaitForChild("HumanoidRootPart")
		damageIndicatorLabel:TweenSize(UDim2.new(2, 0, 2, 0), "InOut", "Quint", 0.3)

		wait(0.3)

		local guiUpTween = tweenService:Create(damageIndicatorGui, tweenInfo, {StudsOffset = damageIndicatorGui.StudsOffset + Vector3.new(0, 2, 0)})

		local textFadeTween = tweenService:Create(damageIndicatorLabel, tweenInfo, {TextTransparency = 1})

		guiUpTween:Play()
		textFadeTween:Play()

		Debris:AddItem(damageIndicatorGui, 0.3)
	end
end

return DamageIndicatorService
