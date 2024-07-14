local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local SoundService = game:GetService("SoundService")
local BaseBarrel = require(ServerScriptService.Classes.BaseBarrel)
local LoudSpeaker = require(ServerScriptService.Classes.LoudSpeaker)

local FireBarrel = {}
FireBarrel.__index = FireBarrel
setmetatable(FireBarrel, BaseBarrel)

function FireBarrel.new(barrelPart, name, hitDamage, level, throwingDistance)
	local self = BaseBarrel.new(barrelPart, name, hitDamage, level, throwingDistance)	
	setmetatable(self, FireBarrel)
	self.DotDamage = 3

	return self
end

-----------------------public method----------------------------

function FireBarrel:Explode(hitPart, hitPosition)
	local randomOil = math.random(0,2)
	local oilModel = nil
	if randomOil == 0 then
		oilModel = ServerStorage.Models.Oil1
	elseif randomOil == 1 then
		oilModel = ServerStorage.Models.Oil2
	else
		oilModel = ServerStorage.Models.Oil3
	end
	
	if hitPart.Name ~= "Baseplate" then
		local fireSpreadScript = ServerStorage.FireSpread
		fireSpreadScript:Clone().Parent = hitPart
	end
	
	local loudSpeaker = LoudSpeaker.new()	
	loudSpeaker:PlayLoudly(SoundService.FireBarrelExplode)

	local effect = ServerStorage.Effect.BrokenWood:Clone()
	effect.Parent = workspace
	effect.Position = self.BarrelPart.Position
	local effect2 = ServerStorage.Effect.SplashSpark:Clone()
	effect2.Parent = workspace
	effect2.Position = self.BarrelPart.Position
	wait(0.5)
	effect:Destroy()
	effect2:Destroy()
end


return FireBarrel