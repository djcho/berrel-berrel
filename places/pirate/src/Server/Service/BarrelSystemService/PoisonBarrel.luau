--[[
	PoisonBarrel: 독구름통
	독 구름을 생성하여 지속 피해를 줍니다. 기름과 조합하면 독성 슬라임!
	독 + 독 = 맹독 구름! (기존 독과 합쳐져 더 강해짐)
]]

local ServerStorage = game:GetService("ServerStorage")
local TweenService = game:GetService("TweenService")

local BaseBarrel = require(script.Parent.BaseBarrel)
local ItemDb = require(ServerStorage.Items.Database.ItemDb)

local PoisonBarrel = setmetatable({}, BaseBarrel)
PoisonBarrel.__index = PoisonBarrel

function PoisonBarrel.new(player, toolInfo, level)
	local self = BaseBarrel.new(player, toolInfo, level)
	setmetatable(self, PoisonBarrel)

	-- ItemDb에서 독 전용 설정 가져오기
	local itemConfig = ItemDb.Tool["PoisonBarrel"]
	self.PoisonModel = itemConfig.PoisonModel or "PoisonFog"
	self.PoisonDuration = itemConfig.PoisonDuration or 15
	self.ToxicSlimeDuration = itemConfig.ToxicSlimeDuration or 20
	self.ToxicSlimeDamageMultiplier = itemConfig.ToxicSlimeDamageMultiplier or 1.5

	return self
end

function PoisonBarrel:OnTouched(hitPart)
	self:DealDamageToTarget(hitPart, self.HitDamage)
end

function PoisonBarrel:Throw(targetPosition)
	BaseBarrel.Throw(self, targetPosition)
end

-- 기존 독 구름 확인
function PoisonBarrel:CheckPoisonCombo(hitPosition)
	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Exclude
	overlapParams.FilterDescendantsInstances = {self.Player.Character}

	local partsInRadius = workspace:GetPartBoundsInRadius(hitPosition, 12, overlapParams)

	for _, part in partsInRadius do
		if part.Parent and part.Parent.Name:match("Poison") and not part.Parent.Name:match("Toxic") then
			-- 이미 불이 붙은 독구름은 맹독 콤보 대상에서 제외 (독성 화염으로 소모된 상태)
			local hasToxicFire = part.Parent:FindFirstChild("ToxicFireSpread", true)
			local hasFireSpread = part.Parent:FindFirstChild("FireSpread", true)
			if not hasToxicFire and not hasFireSpread then
				return part.Parent
			end
		end
	end
	return nil
end

-- 맹독 구름 효과 (독 + 독 조합)
function PoisonBarrel:CreateDeadlyPoison(existingPoison, hitPosition)
	-- 기존 독 강화
	existingPoison.Name = "DeadlyPoisonFog"

	-- 밀도 시스템: 맹독은 150% 밀도로 시작 (두 독이 합쳐짐)
	local currentDensity = existingPoison:GetAttribute("Density") or 100
	existingPoison:SetAttribute("Density", math.min(150, currentDensity + 50))
	existingPoison:SetAttribute("BaseDensity", 150)

	-- 파츠 크기 3배로 확대 + 기존 이펙트를 어두운 보라색으로 변경
	for _, part in existingPoison:GetChildren() do
		if part:IsA("BasePart") then
			-- 투사체 충돌 방지
			part.CanCollide = false
			part.CanQuery = false
			part.CanTouch = false

			-- 크기 2배 확대 + 높이도 증가 (영역 30% 줄임: 3→2배)
			local currentSize = part.Size
			local newSize = Vector3.new(currentSize.X * 2, currentSize.Y * 1.8, currentSize.Z * 2)
			TweenService:Create(part, TweenInfo.new(0.5, Enum.EasingStyle.Elastic), {Size = newSize}):Play()

			-- 기존 파티클 이펙트를 어두운 보라색으로 변경 (독성 느낌)
			for _, child in part:GetChildren() do
				if child:IsA("ParticleEmitter") then
					-- 원본 Rate 저장 (아직 없으면)
					if not child:GetAttribute("BaseRate") then
						child:SetAttribute("BaseRate", child.Rate)
					end

					child.Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, Color3.fromRGB(60, 0, 90)),  -- 어두운 보라
						ColorSequenceKeypoint.new(0.5, Color3.fromRGB(40, 0, 60)),  -- 더 어두운 보라
						ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 0, 30))  -- 거의 검은 보라
					})
					-- 파티클 크기 증가
					child.Size = NumberSequence.new({
						NumberSequenceKeypoint.new(0, 3),
						NumberSequenceKeypoint.new(0.5, 5),
						NumberSequenceKeypoint.new(1, 2)
					})
					child.Rate = child.Rate * 2  -- 파티클 빈도 2배
					-- 새 BaseRate 저장 (맹독 기준)
					child:SetAttribute("BaseRate", child.Rate)
					child.Lifetime = NumberRange.new(2, 3)
					child.Transparency = NumberSequence.new({
						NumberSequenceKeypoint.new(0, 0.55),
						NumberSequenceKeypoint.new(0.5, 0.65),
						NumberSequenceKeypoint.new(1, 0.92)
					})
				end
			end
		end
	end

	-- 기존 PoisonDamage 스크립트 제거하고 새로 생성 (맹독 설정 적용을 위해)
	local oldPoisonDamage = existingPoison:FindFirstChild("PoisonDamage")
	if oldPoisonDamage then
		oldPoisonDamage:Destroy()
	end

	-- 새 PoisonDamage 스크립트 생성 (맹독 설정으로)
	local newPoisonDamage = ServerStorage.Scripts.PoisonDamage:Clone()
	newPoisonDamage:SetAttribute("PoisonOwner", self.Player.Name)
	local currentMultiplier = 1 * 2  -- 맹독은 데미지 2배
	newPoisonDamage:SetAttribute("DamageMultiplier", currentMultiplier)
	newPoisonDamage.Parent = existingPoison

	-- 지속 시간 증가
	local modelDestroyer = existingPoison:FindFirstChild("ModelDestroyer")
	if modelDestroyer and modelDestroyer.Configuration and modelDestroyer.Configuration.WaitTime then
		modelDestroyer.Configuration.WaitTime.Value = modelDestroyer.Configuration.WaitTime.Value + 10
	end

	-- 맹독 이펙트 (어두운 보라색 폭발)
	local effectFolder = ServerStorage:FindFirstChild("Effect")
	if effectFolder then
		local poisonEffect = effectFolder:FindFirstChild("SplashPoison")
		if poisonEffect then
			local effectPart = Instance.new("Part")
			effectPart.Size = Vector3.new(1, 1, 1)
			effectPart.Position = hitPosition
			effectPart.Anchored = true
			effectPart.CanCollide = false
			effectPart.Transparency = 1
			effectPart.Parent = workspace

			local effect = poisonEffect:Clone()
			effect.Parent = effectPart
			if effect:IsA("ParticleEmitter") then
				-- 어두운 보라색으로 변경 (독성 느낌)
				effect.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromRGB(60, 0, 90)),
					ColorSequenceKeypoint.new(0.5, Color3.fromRGB(40, 0, 60)),
					ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 0, 30))
				})
				effect:Emit(60)  -- 더 많이 방출
			end

			game.Debris:AddItem(effectPart, 2)
		end
	end
end

-- 기름 웅덩이 위에 떨어졌는지 확인
function PoisonBarrel:CheckOilCombo(hitPosition)
	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Exclude
	overlapParams.FilterDescendantsInstances = {self.Player.Character}

	local partsInRadius = workspace:GetPartBoundsInRadius(hitPosition, 10, overlapParams)

	for _, part in partsInRadius do
		if part.Parent and part.Parent.Name:match("Oil") then
			return part.Parent
		end
	end
	return nil
end

-- 기름을 독성 슬라임으로 변환
function PoisonBarrel:ConvertOilToToxicSlime(oilModel)
	oilModel.Name = "ToxicOil"

	for _, part in oilModel:GetChildren() do
		if part:IsA("BasePart") then
			part.Color = Color3.fromRGB(30, 80, 30)  -- 어두운 초록색 독성 기름
		end
	end

	local existingBindable = oilModel:FindFirstChild("OnPartRemoving")
	if not existingBindable then
		local bindableEvent = Instance.new("BindableEvent")
		bindableEvent.Name = "OnPartRemoving"
		bindableEvent.Parent = oilModel
	end

	local existingPoisonDamage = oilModel:FindFirstChild("ToxicSlimeDamage")
	if not existingPoisonDamage then
		local toxicSlimeDamage = ServerStorage.Scripts.PoisonDamage:Clone()
		toxicSlimeDamage.Name = "ToxicSlimeDamage"
		toxicSlimeDamage:SetAttribute("PoisonOwner", self.Player.Name)
		toxicSlimeDamage:SetAttribute("DamageMultiplier", self.ToxicSlimeDamageMultiplier)
		toxicSlimeDamage.Parent = oilModel
	end

	local modelDestroyer = oilModel:FindFirstChild("ModelDestroyer")
	if modelDestroyer and modelDestroyer.Configuration and modelDestroyer.Configuration.WaitTime then
		modelDestroyer.Configuration.WaitTime.Value = self.ToxicSlimeDuration
	end
end

function PoisonBarrel:Explode(hitPart, hitPosition)
	if BaseBarrel.Explode(self, hitPart, hitPosition) == false then
		return
	end

	local explosionOrigin = self.BarrelPart.Position

	-- 독 + 독 = 맹독 체크 (우선순위 1)
	local existingPoison = self:CheckPoisonCombo(explosionOrigin)
	if existingPoison then
		self:CreateDeadlyPoison(existingPoison, explosionOrigin)
		return
	end

	-- 기름 위에 떨어졌는지 확인 (우선순위 2)
	local oilModel = self:CheckOilCombo(hitPosition)
	if oilModel then
		-- 기름 + 가스 = 독성 슬라임!
		self:ConvertOilToToxicSlime(oilModel)
		return
	end

	local poisonModel = ServerStorage.Models:FindFirstChild(self.PoisonModel)
	if poisonModel then
		local modelClone = self:CloneAndPositionModel(poisonModel, hitPosition)
		self:AttachScriptsToModel(modelClone)
	end
end

function PoisonBarrel:CloneAndPositionModel(poisonModel, hitPosition)
	local modelClone = poisonModel:Clone()
	modelClone.Parent = workspace
	modelClone:SetPrimaryPartCFrame(CFrame.new(hitPosition) * CFrame.Angles(0, math.rad(math.random(0, 180)), 0))
	return modelClone
end

function PoisonBarrel:AttachScriptsToModel(modelClone)
	local bindableEvent = Instance.new("BindableEvent")
	bindableEvent.Name = "OnPartRemoving"
	bindableEvent.Parent = modelClone

	-- 밀도 시스템: 초기 밀도 100%
	modelClone:SetAttribute("Density", 100)
	modelClone:SetAttribute("BaseDensity", 100)  -- 원본 밀도 저장 (파티클 Rate 복원용)

	-- 각 파티클의 원본 Rate 저장
	for _, part in modelClone:GetDescendants() do
		if part:IsA("ParticleEmitter") then
			part:SetAttribute("BaseRate", part.Rate)
		end
	end

	local modelDestroyer = ServerStorage.Scripts.ModelDestroyer:Clone()

	local configuration = Instance.new("Configuration")
	configuration.Name = "Configuration"
	configuration.Parent = modelDestroyer

	local waitTime = Instance.new("IntValue")
	waitTime.Name = "WaitTime"
	waitTime.Value = self.PoisonDuration
	waitTime.Parent = configuration

	modelDestroyer.Parent = modelClone

	local slower = ServerStorage.Scripts.Slower:Clone()
	slower.Parent = modelClone

	local poisonDamage = ServerStorage.Scripts.PoisonDamage:Clone()
	poisonDamage:SetAttribute("PoisonOwner", self.Player.Name)
	poisonDamage.Parent = modelClone
end

return PoisonBarrel
