-- 서비스 로드
local ReplicatedStorage = game:GetService("ReplicatedStorage")  -- 복제 스토리지
local ServerStorage = game:GetService("ServerStorage")

-- 모듈 로드
local BaseBarrel = require(script.Parent.BaseBarrel)

-- PoisonBarrel 클래스 정의
local PoisonBarrel = setmetatable({}, BaseBarrel)
PoisonBarrel.__index = PoisonBarrel

-- 새로운 PoisonBarrel 객체 생성 함수
function PoisonBarrel.new(player, level, toolInfo)
	local self = BaseBarrel.new(player, ServerStorage.Parts.PoisonBarrel, level)
	setmetatable(self, PoisonBarrel)
	self.HitDamage = toolInfo.Damage
	self.DotDamage = toolInfo.DotDamage
	self.MaxRange = toolInfo.MaxRange
	self.Name = toolInfo.Name
	return self
end

-- 배럴이 다른 객체와 충돌했을 때 호출되는 함수
function PoisonBarrel:OnTouched(hitPart)
	self:DealDamageToTarget(hitPart, self.HitDamage)
end

-- 배럴을 목표 위치로 던지는 함수
function PoisonBarrel:Throw(targetPosition)
	BaseBarrel.Throw(self, targetPosition, self.MaxRange)
end

-- 기름 웅덩이 위에 떨어졌는지 확인
function PoisonBarrel:CheckOilCombo(hitPosition)
	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Exclude
	overlapParams.FilterDescendantsInstances = {self.Player.Character}

	local partsInRadius = workspace:GetPartBoundsInRadius(hitPosition, 10, overlapParams)

	for _, part in partsInRadius do
		if part.Parent and part.Parent.Name:match("Oil") then
			return part.Parent  -- 기름 모델 반환
		end
	end
	return nil
end

-- 기름을 독성 슬라임으로 변환
function PoisonBarrel:ConvertOilToToxicSlime(oilModel)
	-- 기름 모델 이름 변경 (독성 슬라임)
	oilModel.Name = "ToxicSlime"

	-- 기름 파트들을 보라색으로 변경
	for _, part in oilModel:GetChildren() do
		if part:IsA("BasePart") then
			part.Color = Color3.fromRGB(128, 0, 128)  -- 보라색
			part.Material = Enum.Material.Neon
		end
	end

	-- 독 데미지 스크립트 추가 (강화된 버전)
	local existingPoisonDamage = oilModel:FindFirstChild("ToxicSlimeDamage")
	if not existingPoisonDamage then
		local toxicSlimeDamage = ServerStorage.Scripts.PoisonDamage:Clone()
		toxicSlimeDamage.Name = "ToxicSlimeDamage"
		toxicSlimeDamage:SetAttribute("PoisonOwner", self.Player.Name)
		toxicSlimeDamage:SetAttribute("DamageMultiplier", 1.5)  -- 50% 강화된 데미지
		toxicSlimeDamage.Parent = oilModel
	end

	-- 지속시간 연장
	local modelDestroyer = oilModel:FindFirstChild("ModelDestroyer")
	if modelDestroyer and modelDestroyer.Configuration and modelDestroyer.Configuration.WaitTime then
		modelDestroyer.Configuration.WaitTime.Value = 20  -- 20초 지속
	end
end

-- 배럴이 폭발할 때 호출되는 함수
function PoisonBarrel:Explode(hitPart, hitPosition)
	if(BaseBarrel.Explode(self, hitPart, hitPosition) == false) then
		return
	end

	-- 기름 위에 떨어졌는지 확인
	local oilModel = self:CheckOilCombo(hitPosition)
	if oilModel then
		-- 기름 + 가스 = 독성 슬라임!
		self:ConvertOilToToxicSlime(oilModel)
		self:PlayExplosionEffects(nil)  -- 이펙트만 재생
		return
	end

	local poisonModel = ServerStorage.Models.PoisonFog
	local modelClone = self:CloneAndPositionModel(poisonModel, hitPosition)
	self:AttachScriptsToModel(modelClone)
	self:PlayExplosionEffects(modelClone)
end


-- 오일 모델을 클론하고 위치를 설정하는 함수
function PoisonBarrel:CloneAndPositionModel(poisonModel, hitPosition)
	local modelClone = poisonModel:Clone()
	modelClone.Parent = workspace
	modelClone:SetPrimaryPartCFrame(CFrame.new(hitPosition) * CFrame.Angles(0, math.rad(math.random(0, 180)), 0))
	return modelClone
end

-- 모델에 스크립트를 첨부하는 함수
function PoisonBarrel:AttachScriptsToModel(modelClone)
	-- BindableEvent 생성 (Slower와 PoisonDamage가 필요로 함)
	local bindableEvent = Instance.new("BindableEvent")
	bindableEvent.Name = "OnPartRemoving"
	bindableEvent.Parent = modelClone

	local modelDestroyer = ServerStorage.Scripts.ModelDestroyer:Clone()

	-- Configuration과 WaitTime을 Clone된 스크립트에 미리 생성
	local configuration = Instance.new("Configuration")
	configuration.Name = "Configuration"
	configuration.Parent = modelDestroyer

	local waitTime = Instance.new("IntValue")
	waitTime.Name = "WaitTime"
	waitTime.Value = 15
	waitTime.Parent = configuration

	modelDestroyer.Parent = modelClone

	-- 슬로우 효과 스크립트
	local slower = ServerStorage.Scripts.Slower:Clone()
	slower.Parent = modelClone

	-- 독 피해 스크립트 추가 (DoT 구현)
	local poisonDamage = ServerStorage.Scripts.PoisonDamage:Clone()
	-- 독을 뿌린 플레이어 정보 저장 (킬/어시스트 추적용)
	poisonDamage:SetAttribute("PoisonOwner", self.Player.Name)
	poisonDamage.Parent = modelClone
end

-- 폭발 효과를 재생하는 함수
function PoisonBarrel:PlayExplosionEffects()
	-- 폭발 사운드를 재생
	local remoteEvent = ReplicatedStorage:WaitForChild("PlaySoundEvent")
	remoteEvent:FireAllClients("NormalBarrelExplode", 0, 1.5)

	local effect = ServerStorage.Effect.BrokenWood:Clone()
	effect.Parent = workspace
	effect.Position = self.BarrelPart.Position

	local effect2 = ServerStorage.Effect.SplashPoison:Clone()
	effect2.Parent = workspace
	effect2.Position = self.BarrelPart.Position

	-- 효과가 제대로 보일 수 있도록 잠시 후에 제거
	game.Debris:AddItem(effect, 0.5)  -- 0.5초 후 효과 제거
	game.Debris:AddItem(effect2, 0.5)  -- 0.5초 후 효과 제거
end



return PoisonBarrel
