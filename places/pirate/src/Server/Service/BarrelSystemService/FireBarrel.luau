-- 서비스 로드
local ServerStorage = game:GetService("ServerStorage")  -- 서버 스토리지
local ReplicatedStorage = game:GetService("ReplicatedStorage")  -- 복제 스토리지

-- 모듈 로드
local BaseBarrel = require(script.Parent.BaseBarrel)  -- 기본 배럴 클래스

-- FireBarrel 클래스 정의
local FireBarrel = setmetatable({}, BaseBarrel)
FireBarrel.__index = FireBarrel

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

-- 배럴이 다른 객체와 충돌했을 때 호출되는 함수
function FireBarrel:OnTouched(hitPart)
	self:DealDamageToTarget(hitPart, self.HitDamage)
end

-- 배럴을 목표 위치로 던지는 함수
function FireBarrel:Throw(targetPosition)
	BaseBarrel.Throw(self, targetPosition, self.MaxRange)
end

-- 배럴이 폭발할 때 호출되는 함수
function FireBarrel:Explode(hitPart, hitPosition)
	if BaseBarrel.Explode(self, hitPart, hitPosition) == false then
		return
	end

	local explosionOrigin = self.BarrelPart.Position
	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Exclude
	overlapParams.FilterDescendantsInstances = {self.Player.Character}
	local partsInRadius = workspace:GetPartBoundsInRadius(explosionOrigin, self.ExplosionRadius, overlapParams)

	for _, part in partsInRadius do
		if part.Name ~= "Baseplate" and part.Parent then
			-- 독 웅덩이에 불을 붙이면 독성 화염 (ToxicFireSpread) 사용
			if part.Parent.Name:match("Poison") then
				-- 이미 불이 붙어있으면 건너뛰기
				if not part:FindFirstChild("ToxicFireSpread") and not part:FindFirstChild("FireSpread") then
					local toxicFireScript = ServerStorage.Scripts.ToxicFireSpread:Clone()
					toxicFireScript:SetAttribute("FireStarter", self.Player.Name)
					toxicFireScript.Parent = part

					local modelDestroyer = part.Parent:FindFirstChild("ModelDestroyer")
					if modelDestroyer and modelDestroyer.Configuration and modelDestroyer.Configuration.WaitTime then
						modelDestroyer.Configuration.WaitTime.Value = 12 -- 독성 화염은 12초 지속
					end
				end
			-- 기름 웅덩이는 기존 FireSpread 사용
			elseif part.Parent.Name:match("Oil") then
				if not part:FindFirstChild("FireSpread") then
					local fireSpreadScript = ServerStorage.Scripts.FireSpread:Clone()
					fireSpreadScript:SetAttribute("FireStarter", self.Player.Name)
					fireSpreadScript.Parent = part

					local modelDestroyer = part.Parent:FindFirstChild("ModelDestroyer")
					if modelDestroyer and modelDestroyer.Configuration and modelDestroyer.Configuration.WaitTime then
						modelDestroyer.Configuration.WaitTime.Value = 10 -- 사라지는 시간을 10초로 초기화
					end
				end
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
