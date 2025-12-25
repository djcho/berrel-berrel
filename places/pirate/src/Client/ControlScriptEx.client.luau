--local ContextActionService = game:GetService("ContextActionService")
--local ReplicatedStorage = game:GetService("ReplicatedStorage")
--local players = game:GetService("Players")
--local player = players.LocalPlayer

--local SoundService = game:GetService("SoundService")
--local barrelLevelUpSound = SoundService:WaitForChild("BarrelLevelUp")

--local throwingBarrelEvent = ReplicatedStorage:WaitForChild("ThrowingBarrelEvent")
--local function OnThrowBarrel(actionName, inputState)
--	if not player.Character then
--		return
--	end

--	local mouse = player:GetMouse()	
--	if inputState == Enum.UserInputState.End then
--		local OilBarrel = require(ReplicatedStorage.Classes.OilBarrel)
--		local barrel = OilBarrel.new(player, ReplicatedStorage.Parts.OilBarrel, 1)

--		barrel:Throw(mouse.Hit.Position)
--	end
--end


--local requestSwapBarrel = ReplicatedStorage:WaitForChild("RequestSwapBarrel")
--local updateBarrelGui = ReplicatedStorage:WaitForChild("UpdateBarrelGuiEvent")
--local function OnSwapBarrel(actionName, inputState)
--	if not player.Character then
--		return
--	end
--	if inputState == Enum.UserInputState.End then		
--		if requestSwapBarrel:InvokeServer() then
--			updateBarrelGui:Fire()
--		else
--			print("RequestSwapBarrel Failed.")
--		end		
--	end
--end


--local requestUpgradeBarrel = ReplicatedStorage:WaitForChild("RequestUpgradeBarrel")
--local function OnUpgradeBarrel(actionName, inputState)
--	if not player.Character then
--		return
--	end
--	if inputState == Enum.UserInputState.End then	
--		if requestUpgradeBarrel:InvokeServer(player) then
--			barrelLevelUpSound:Play()
--			updateBarrelGui:Fire()
--		end	
--	end
--end

----ContextActionService:BindAction("ThrowBarrel", OnThrowBarrel, false, Enum.UserInputType.MouseButton1)
----ContextActionService:BindAction("SwapBarrel", OnSwapBarrel, false, Enum.KeyCode.Q)
----ContextActionService:BindAction("UpgradeBarrel", OnUpgradeBarrel, false, Enum.KeyCode.E)