local throwingBarrelEvent = game.ReplicatedStorage.ThrowingBarrelEvent
local swapBarrelEvent = game.ReplicatedStorage.SwapBarrelEvent


local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
--인게임 마우스 업 이벤트

local swapBarrel = false
throwingBarrelEvent.OnServerEvent:Connect(function(player, mouseHitPosition)
	
	local humanoid = player.Character:WaitForChild("Humanoid")
	humanoid.WalkSpeed = 16 --휴머노이드 속도 감속
	
	local animator = humanoid:WaitForChild("Animator")
	if swapBarrel  then
		local FireBarrel = require(ServerScriptService.Classes.FireBarrel)
		local fireBarrel = FireBarrel.new(ServerStorage.Parts.FireBarrel)
		fireBarrel:Throw(player, mouseHitPosition)
	else
		local OilBarrel = require(ServerScriptService.Classes.OilBarrel)
		local oilBarrel = OilBarrel.new(ServerStorage.Parts.OilBarrel)
		oilBarrel:Throw(player, mouseHitPosition)
	end
	
end)

local debounce = false
swapBarrelEvent.OnServerEvent:Connect(function(player)	
	if debounce then
		return
	end
	
	debounce = true
	swapBarrel = not swapBarrel	
	wait(0.1)
	debounce = false
end)

