local contextActionService = game:GetService("ContextActionService")
local replicatedStorage = game:GetService("ReplicatedStorage")
local players = game:GetService("Players")

local player = players.LocalPlayer
local mouse = player:GetMouse()
local camera = workspace.CurrentCamera
local throwingBarrelEvent = replicatedStorage:WaitForChild("ThrowingBarrelEvent")
local function onThrowBarrel(actionName, inputState)
	if not player.Character then
		return
	end
	if inputState == Enum.UserInputState.End then
		throwingBarrelEvent:FireServer(mouse.Hit.p)
	end
end

local swapBarrelEvent = replicatedStorage:WaitForChild("SwapBarrelEvent")
local function onSwitchBarrel(actionName, inputState)
	if not player.Character then
		return
	end
	if inputState == Enum.UserInputState.End then			
		swapBarrelEvent:FireServer()
	end
end


--contextActionService:BindAction("ThrowBarrel", onThrowBarrel, false, Enum.UserInputType.MouseButton1)
contextActionService:BindAction("SwitchBarrel", onSwitchBarrel, false, Enum.KeyCode.Q)