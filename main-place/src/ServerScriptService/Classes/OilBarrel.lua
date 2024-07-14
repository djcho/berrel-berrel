local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local SoundService = game:GetService("SoundService")
local BaseBarrel = require(ServerScriptService.Classes.BaseBarrel)
local LoudSpeaker = require(ServerScriptService.Classes.LoudSpeaker)

local OilBarrel = {}
OilBarrel.__index = OilBarrel
setmetatable(OilBarrel, BaseBarrel)

function OilBarrel.new(barrelPart, name, hitDamage, level, throwingDistance)
	local self = BaseBarrel.new(barrelPart, name, hitDamage, level, throwingDistance)	
	setmetatable(self, OilBarrel)
	self.DotDamage = 3
	
	return self
end

function OilBarrel:Explode(_, hitPosition)

	local randomOil = math.random(0,2)
	local oilModel = nil
	if randomOil == 0 then
		oilModel = ServerStorage.Models.Oil1
	elseif randomOil == 1 then
		oilModel = ServerStorage.Models.Oil2
	else
		oilModel = ServerStorage.Models.Oil3
	end
	
	local modelClone = oilModel:Clone()
	modelClone.Parent = workspace
	modelClone:SetPrimaryPartCFrame(CFrame.new(hitPosition.X, 0, hitPosition.Z)*CFrame.Angles(0,math.random(0,180),0))
		
	local loudSpeaker = LoudSpeaker.new()	
	loudSpeaker:PlayLoudly(SoundService.NormalBarrelExplode)
	
	local effect = ServerStorage.Effect.BrokenWood:Clone()
	effect.Parent = workspace
	effect.Position = self.BarrelPart.Position
	local effect2 = ServerStorage.Effect.SplashOil:Clone()
	effect2.Parent = workspace
	effect2.Position = self.BarrelPart.Position
	wait(0.5)
	effect:Destroy()
	effect2:Destroy()
end


return OilBarrel