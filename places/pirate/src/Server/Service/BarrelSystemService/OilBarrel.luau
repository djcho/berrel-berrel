local ReplicatedStorage = game:GetService("ReplicatedStorage")  -- 복제 스토리지
-- 서비스 로드
local ServerStorage = game:GetService("ServerStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local Terrain = workspace.Terrain

-- 모듈 로드
local BaseBarrel = require(script.Parent.BaseBarrel)
local LoudSpeaker = require(ServerStorage.Scripts.LoudSpeaker)
local CommonUtil = require(ServerStorage.Scripts.CommonUtil)

-- OilBarrel 클래스 정의
local OilBarrel = setmetatable({}, BaseBarrel)
OilBarrel.__index = OilBarrel

-- 새로운 OilBarrel 객체 생성 함수
function OilBarrel.new(player, level, toolInfo)
	local self = BaseBarrel.new(player, ServerStorage.Parts.OilBarrel, level)
	setmetatable(self, OilBarrel)
	self.HitDamage = toolInfo.Damage
	self.DotDamage = toolInfo.DotDamage
	self.MaxRange = toolInfo.MaxRange
	self.Name = toolInfo.Name
	return self
end

-- 배럴이 다른 객체와 충돌했을 때 호출되는 함수
function OilBarrel:OnTouched(hitPart)
	local humanoid = CommonUtil:GetHumanoidByPart(hitPart)
	if not humanoid or humanoid.Parent.Name == self.Player.Character.Name then
		return
	end
	humanoid:TakeDamage(self.HitDamage)
end

-- 배럴을 목표 위치로 던지는 함수
function OilBarrel:Throw(targetPosition)
	BaseBarrel.Throw(self, targetPosition, self.MaxRange)
end

-- 배럴이 폭발할 때 호출되는 함수
function OilBarrel:Explode(hitPart, hitPosition)
	if(BaseBarrel.Explode(self, hitPart, hitPosition) == false) then
		return
	end
	
	local oilModel = self:ChooseRandomOilModel()
	local modelClone = self:CloneAndPositionModel(oilModel, hitPosition)
	self:AttachScriptsToModel(modelClone)
	self:PlayExplosionEffects(modelClone)
	self:AnimateOilSpread(modelClone)
end

-- 랜덤 오일 모델 선택 함수
function OilBarrel:ChooseRandomOilModel()
	local randomOil = math.random(0, 2)
	if randomOil == 0 then
		return ServerStorage.Models.Oil1
	elseif randomOil == 1 then
		return ServerStorage.Models.Oil2
	else
		return ServerStorage.Models.Oil3
	end
end

-- 오일 모델을 클론하고 위치를 설정하는 함수
function OilBarrel:CloneAndPositionModel(oilModel, hitPosition)
	local modelClone = oilModel:Clone()
	modelClone.Parent = workspace
	modelClone:SetPrimaryPartCFrame(CFrame.new(hitPosition) * CFrame.Angles(0, math.rad(math.random(0, 180)), 0))
	return modelClone
end

-- 모델에 스크립트를 첨부하는 함수
function OilBarrel:AttachScriptsToModel(modelClone)
	
	local modelDestroyer = ServerStorage.Scripts.ModelDestroyer:Clone()
	modelDestroyer.Configuration.WaitTime.Value = 15
	modelDestroyer.Parent = modelClone
	
	local slower = ServerStorage.Scripts.Slower:Clone()
	slower.Parent = modelClone
	for _, part in pairs(modelClone:GetChildren()) do
		if part.Name:match("Oil") then
			part:SetAttribute("OriginalSize", part.Size)
			part.Size = Vector3.new(0, part.Size.Y, 0) -- 초기 크기를 0으로 설정
		end
	end
end

-- 폭발 효과를 재생하는 함수
function OilBarrel:PlayExplosionEffects(modelClone)
	-- 폭발 사운드를 재생
	local remoteEvent = ReplicatedStorage:WaitForChild("PlaySoundEvent")
	remoteEvent:FireAllClients("NormalBarrelExplode", 0, 1.5)

	local effect = ServerStorage.Effect.BrokenWood:Clone()
	effect.Parent = workspace
	effect.Position = self.BarrelPart.Position

	local effect2 = ServerStorage.Effect.SplashOil:Clone()
	effect2.Parent = workspace
	effect2.Position = self.BarrelPart.Position

	-- 효과가 제대로 보일 수 있도록 잠시 후에 제거
	game.Debris:AddItem(effect, 0.5)  -- 0.5초 후 효과 제거
	game.Debris:AddItem(effect2, 0.5)  -- 0.5초 후 효과 제거
end

-- 기름 퍼지는 효과 애니메이션 함수
function OilBarrel:AnimateOilSpread(modelClone)
	for _, part in pairs(modelClone:GetChildren()) do
		if part:IsA("BasePart") then
			local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
			local originalSize = part:GetAttribute("OriginalSize")
			local goal = {Size = originalSize}
			local tween = TweenService:Create(part, tweenInfo, goal)
			tween:Play()
		end
	end
end


return OilBarrel
