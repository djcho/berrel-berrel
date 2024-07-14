local OBJECT_NAME = "OilBarrel"
local OIL_BARREL_DAMAGE = 10
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local SoundService = game:GetService("SoundService")
local BaseBarrel = require(ServerStorage.Classes.BaseBarrel)
local LoudSpeaker = require(ServerStorage.Classes.LoudSpeaker)
local CommonUtil = require(ServerStorage.Classes.CommonUtil)

local OilBarrel = {}
OilBarrel.__index = OilBarrel
setmetatable(OilBarrel, BaseBarrel)

function OilBarrel.new(player, barrelPart, level)
	local self = BaseBarrel.new(player, barrelPart, level)	
	setmetatable(self, OilBarrel)
	self.HitDamage = OIL_BARREL_DAMAGE
	self.DotDamage = 3
	self.Name = OBJECT_NAME
	return self
end

function OilBarrel:OnTouched(hitPart)
	local humanoid = CommonUtil:GetHumanoidByPart(hitPart)
	if not humanoid or humanoid.Parent.Name == self.Player.Character.Name then
		return
	end

	humanoid:TakeDamage(self.HitDamage)
end


function OilBarrel:Explode(hitPart, hitPosition)
	
	
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
	modelClone:SetPrimaryPartCFrame(CFrame.new(hitPosition.X, hitPosition.Y, hitPosition.Z)*CFrame.Angles(0,math.random(0,180),0))
	
	local slower = nil
	for _, v in pairs(modelClone:GetChildren()) do
		if v.Name:match("Oil") then
			slower = ServerStorage.Script.Slower:Clone()
			slower.Parent = v
		end		
	end

	local modelDestroyer = ServerStorage.Script.ModelDestroyer:Clone()
	modelDestroyer.Configuration.WaitTime.Value = 15
	modelDestroyer.Parent = modelClone
		
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
