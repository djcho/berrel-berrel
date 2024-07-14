local OBJECT_NAME = "FireBarrel"
local FIRE_BARREL_DAMAGE = 15
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local SoundService = game:GetService("SoundService")
local BaseBarrel = require(ServerStorage.Classes.BaseBarrel)
local LoudSpeaker = require(ServerStorage.Classes.LoudSpeaker)
local CommonUtil = require(ServerStorage.Classes.CommonUtil)

local FireBarrel = {}
FireBarrel.__index = FireBarrel
setmetatable(FireBarrel, BaseBarrel)

function FireBarrel.new(player, barrelPart, level)
	local self = BaseBarrel.new(player, barrelPart, level)	
	setmetatable(self, FireBarrel)
	self.HitDamage = FIRE_BARREL_DAMAGE
	self.DotDamage = 3
	self.Name = OBJECT_NAME
	return self
end

-----------------------public method----------------------------
function FireBarrel:OnTouched(hitPart)
	local humanoid = CommonUtil:GetHumanoidByPart(hitPart)
	if not humanoid or humanoid.Parent.Name == self.Player.Character.Name then
		return
	end

	humanoid:TakeDamage(self.HitDamage)
end


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
	
	if hitPart.Name ~= "Baseplate" and hitPart.Parent and hitPart.Parent.Name:match("Oil") then

		local fireSpreadScript = ServerStorage.Script.FireSpread
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
