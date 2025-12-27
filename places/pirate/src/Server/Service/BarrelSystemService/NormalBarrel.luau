-- 서비스 로드
local ServerStorage = game:GetService("ServerStorage")  -- 서버 스토리지
local ReplicatedStorage = game:GetService("ReplicatedStorage")  -- 복제 스토리지

-- 모듈 로드
local BaseBarrel = require(script.Parent.BaseBarrel)  -- 기본 배럴 클래스

-- NormalBarrel 클래스 정의
local NormalBarrel = setmetatable({}, BaseBarrel)
NormalBarrel.__index = NormalBarrel

-- 새로운 NormalBarrel 객체 생성 함수
function NormalBarrel.new(player, level, toolInfo)
	local self = BaseBarrel.new(player, ServerStorage.Parts.NormalBarrel, level)
	setmetatable(self, NormalBarrel)
	self.HitDamage = toolInfo.Damage
	self.DotDamage = toolInfo.DotDamage
	self.MaxRange = toolInfo.MaxRange
	self.Name = toolInfo.Name
	return self
end

-- 배럴이 다른 객체와 충돌했을 때 호출되는 함수
function NormalBarrel:OnTouched(hitPart)
	self:DealDamageToTarget(hitPart, self.HitDamage)
end

-- 배럴을 목표 위치로 던지는 함수
function NormalBarrel:Throw(targetPosition)
	-- BaseBarrel의 Throw 함수 호출
	BaseBarrel.Throw(self, targetPosition, self.MaxRange)
end

-- 배럴이 폭발할 때 호출되는 함수
function NormalBarrel:Explode(hitPart, hitPosition)
	if(BaseBarrel.Explode(self, hitPart, hitPosition) == false) then
		return
	end
	
	-- 폭발 사운드를 재생
	local remoteEvent = ReplicatedStorage:WaitForChild("PlaySoundEvent")
	remoteEvent:FireAllClients("NormalBarrelExplode", 0, 1.5)

	-- 폭발 효과를 생성하고 월드에 배치
	local effect = ServerStorage.Effect.BrokenWood:Clone()
	effect.Parent = workspace
	effect.Position = hitPosition

	-- 효과가 제대로 보일 수 있도록 잠시 후에 제거
	game.Debris:AddItem(effect, 0.5)  -- 0.5초 후 효과 제거
end

return NormalBarrel
