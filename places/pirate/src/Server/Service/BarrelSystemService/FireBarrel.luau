-- 서비스 로드
local ServerScriptService = game:GetService("ServerScriptService")  -- 서버 스크립트 서비스
local ServerStorage = game:GetService("ServerStorage")  -- 서버 스토리지
local SoundService = game:GetService("SoundService")  -- 사운드 서비스
local ReplicatedStorage = game:GetService("ReplicatedStorage")  -- 복제 스토리지

-- 모듈 로드
local BaseBarrel = require(script.Parent.BaseBarrel)  -- 기본 배럴 클래스
local LoudSpeaker = require(ServerStorage.Scripts.LoudSpeaker)  -- 라우드 스피커 클래스
local CommonUtil = require(ServerStorage.Scripts.CommonUtil)  -- 공용 유틸리티 클래스

-- FireBarrel 클래스 정의
local FireBarrel = {}
FireBarrel.__index = FireBarrel
setmetatable(FireBarrel, BaseBarrel)

-- 새로운 FireBarrel 객체 생성 함수
function FireBarrel.new(player, level, toolInfo)
	local self = BaseBarrel.new(player, ServerStorage.Parts.FireBarrel, level)
	setmetatable(self, FireBarrel)
	self.HitDamage = toolInfo.Damage
	self.DotDamage = toolInfo.DotDamage
	self.MaxRange = toolInfo.MaxRange
	self.Name = toolInfo.Name
	self.ExplosionRadius = toolInfo.ExplosionRadius
	return self
end

-----------------------공개 메서드----------------------------

-- 배럴이 다른 객체와 충돌했을 때 호출되는 함수
function FireBarrel:OnTouched(hitPart)
	local humanoid = CommonUtil:GetHumanoidByPart(hitPart)
	if not humanoid or humanoid.Parent.Name == self.Player.Character.Name then
		return
	end

	humanoid:TakeDamage(self.HitDamage)
end

-- 배럴을 목표 위치로 던지는 함수
function FireBarrel:Throw(targetPosition)
	BaseBarrel.Throw(self, targetPosition, self.MaxRange)
end

-- 배럴이 폭발할 때 호출되는 함수
function FireBarrel:Explode(hitPart, hitPosition)
	if(BaseBarrel.Explode(self, hitPart, hitPosition) == false) then
		return
	end

	local explosionOrigin = self.BarrelPart.Position
	local partsInRadius = workspace:FindPartsInRegion3(Region3.new(
		explosionOrigin - Vector3.new(self.ExplosionRadius, self.ExplosionRadius, self.ExplosionRadius),
		explosionOrigin + Vector3.new(self.ExplosionRadius, self.ExplosionRadius, self.ExplosionRadius)
		))

	for _, part in pairs(partsInRadius) do
		if part.Name ~= "Baseplate" and part.Parent and part.Parent.Name:match("Oil") then
			local fireSpreadScript = ServerStorage.Scripts.FireSpread:Clone()
			fireSpreadScript.Parent = part

			-- 사라지는 시간을 초기화하는 처리 추가
			local modelDestroyer = part.Parent:FindFirstChild("ModelDestroyer")
			if modelDestroyer and modelDestroyer.Configuration and modelDestroyer.Configuration.WaitTime then
				modelDestroyer.Configuration.WaitTime.Value = 10 -- 사라지는 시간을 10초로 초기화
			end
		end
	end
	
	-- 폭발 사운드를 재생
	local remoteEvent = ReplicatedStorage:WaitForChild("PlaySoundEvent")
	remoteEvent:FireAllClients("FireBarrelExplode", 0, 1.5)

	local effect = ServerStorage.Effect.BrokenWood:Clone()
	effect.Parent = workspace
	effect.Position = self.BarrelPart.Position
	local effect2 = ServerStorage.Effect.SplashSpark:Clone()
	effect2.Parent = workspace
	effect2.Position = self.BarrelPart.Position

	game.Debris:AddItem(effect, 0.5)  -- 0.5초 후 효과 제거
	game.Debris:AddItem(effect2, 0.5)  -- 0.5초 후 효과 제거
end

return FireBarrel
