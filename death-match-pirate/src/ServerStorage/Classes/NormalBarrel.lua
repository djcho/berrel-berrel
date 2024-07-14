local OBJECT_NAME = "NormalBarrel"

local ServerScriptService = game:GetService("ServerScriptService")
local NORMAL_BARREL_DAMAGE = 5
local ServerStorage = game:GetService("ServerStorage")
local SoundService = game:GetService("SoundService")
local BaseBarrel = require(ServerStorage.Classes.BaseBarrel)
local LoudSpeaker = require(ServerStorage.Classes.LoudSpeaker)
local CommonUtil = require(ServerStorage.Classes.CommonUtil)

local NormalBarrel = {}
NormalBarrel.__index = NormalBarrel
setmetatable(NormalBarrel, BaseBarrel)

function NormalBarrel.new(player, barrelPart, level)
	local self = BaseBarrel.new(player, barrelPart, level)	
	setmetatable(self, NormalBarrel)
	self.HitDamage = NORMAL_BARREL_DAMAGE
	self.DotDamage = 3
	self.Name = OBJECT_NAME
	return self
end

function NormalBarrel:OnTouched(hitPart)
	local humanoid = CommonUtil:GetHumanoidByPart(hitPart)
	if not humanoid or humanoid.Parent.Name == self.Player.Character.Name then
		return
	end

	if humanoid.Parent.Name == self.Player.Character.Name then
		return
	end
	
	humanoid:TakeDamage(self.HitDamage)
end


function NormalBarrel:Explode(hitPart, hitPosition)
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


return NormalBarrel
