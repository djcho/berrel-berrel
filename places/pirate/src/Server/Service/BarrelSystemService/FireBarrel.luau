--[[
	FireBarrel: 화염통
	기름이나 독에 불을 붙여 강력한 데미지를 줍니다.
	불 + 불 = 대폭발! (불이 붙은 곳에 다시 불을 던지면 대폭발)
]]

local ServerStorage = game:GetService("ServerStorage")

local BaseBarrel = require(script.Parent.BaseBarrel)
local ItemDb = require(ServerStorage.Items.Database.ItemDb)
local CommonUtil = require(ServerStorage.Scripts.CommonUtil)

local FireBarrel = setmetatable({}, BaseBarrel)
FireBarrel.__index = FireBarrel

function FireBarrel.new(player, toolInfo, level)
	local self = BaseBarrel.new(player, toolInfo, level)
	setmetatable(self, FireBarrel)

	-- ItemDb에서 불 전용 설정 가져오기
	local itemConfig = ItemDb.Tool["FireBarrel"]
	self.FireDuration = itemConfig.FireDuration or 10
	self.ToxicFireDuration = itemConfig.ToxicFireDuration or 12

	return self
end

function FireBarrel:OnTouched(hitPart)
	self:DealDamageToTarget(hitPart, self.HitDamage)
end

function FireBarrel:Throw(targetPosition)
	BaseBarrel.Throw(self, targetPosition)
end

-- 기존 불이 있는지 확인
function FireBarrel:CheckFireCombo(position)
	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Exclude
	overlapParams.FilterDescendantsInstances = {self.Player.Character}

	local partsInRadius = workspace:GetPartBoundsInRadius(position, 12, overlapParams)

	for _, part in partsInRadius do
		-- Fire 이펙트 또는 FireSpread 스크립트가 있는지 확인
		if part:FindFirstChildWhichIsA("Fire") then
			return true, part
		end
		if part:FindFirstChild("FireSpread") or part:FindFirstChild("ToxicFireSpread") then
			return true, part
		end
	end
	return false, nil
end

-- 대폭발 효과 (불 + 불 조합)
function FireBarrel:CreateMegaExplosion(explosionOrigin, triggerPart)
	local megaRadius = self.ExplosionRadius * 1.5
	local megaDamage = self.HitDamage * 1.5

	-- 대폭발 이펙트
	local effectPart = Instance.new("Part")
	effectPart.Name = "MegaExplosionEffect"
	effectPart.Size = Vector3.new(1, 1, 1)
	effectPart.Position = explosionOrigin
	effectPart.Anchored = true
	effectPart.CanCollide = false
	effectPart.Transparency = 1
	effectPart.Parent = workspace

	-- 큰 폭발 이펙트
	local effectFolder = ServerStorage:FindFirstChild("Effect")
	if effectFolder then
		local sparkEffect = effectFolder:FindFirstChild("SplashSpark")
		if sparkEffect then
			local effect = sparkEffect:Clone()
			effect.Parent = effectPart
			if effect:IsA("ParticleEmitter") then
				effect:Emit(50)  -- 더 많은 파티클
			end
		end
	end

	-- 폭발음 재생 (더 크게)
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local remoteEvent = ReplicatedStorage:FindFirstChild("PlaySoundEvent")
	if remoteEvent then
		remoteEvent:FireAllClients("FireBarrelExplode", 0, 1.5)  -- 볼륨 1.5배
	end

	-- 범위 내 모든 적에게 대미지
	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Exclude
	overlapParams.FilterDescendantsInstances = {self.Player.Character}

	local partsInRadius = workspace:GetPartBoundsInRadius(explosionOrigin, megaRadius, overlapParams)
	local processedCharacters = {}

	for _, part in partsInRadius do
		local character = part.Parent
		local humanoid = character and character:FindFirstChild("Humanoid")

		if humanoid and not processedCharacters[character] then
			processedCharacters[character] = true

			local targetPlayer = game.Players:GetPlayerFromCharacter(character)
			local isSameTeam = CommonUtil:IsSameTeam(self.Player, targetPlayer)

			if not isSameTeam then
				self:SetCreatorTag(humanoid)
				humanoid:TakeDamage(megaDamage)

				-- 넉백 효과
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if hrp then
					local direction = (hrp.Position - explosionOrigin).Unit
					direction = Vector3.new(direction.X, 0.3, direction.Z).Unit

					local bodyVelocity = Instance.new("BodyVelocity")
					bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
					bodyVelocity.Velocity = direction * 60
					bodyVelocity.Parent = hrp
					game.Debris:AddItem(bodyVelocity, 0.3)
				end
			end
		end
	end

	-- 기존 불을 소멸시킴 (연료 소진)
	if triggerPart and triggerPart.Parent then
		local fireModel = triggerPart.Parent
		if fireModel.Name:match("Oil") or fireModel.Name:match("Poison") then
			local modelDestroyer = fireModel:FindFirstChild("ModelDestroyer")
			if modelDestroyer and modelDestroyer.Configuration and modelDestroyer.Configuration.WaitTime then
				modelDestroyer.Configuration.WaitTime.Value = 1  -- 즉시 소멸
			end
		end
	end

	game.Debris:AddItem(effectPart, 3)
end

function FireBarrel:Explode(hitPart, hitPosition)
	if BaseBarrel.Explode(self, hitPart, hitPosition) == false then
		return
	end

	local explosionOrigin = self.BarrelPart.Position

	-- 불 + 불 = 대폭발 체크
	local hasExistingFire, firePart = self:CheckFireCombo(explosionOrigin)
	if hasExistingFire then
		self:CreateMegaExplosion(explosionOrigin, firePart)
		return  -- 대폭발 후 추가 불 붙이기 생략
	end

	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Exclude
	overlapParams.FilterDescendantsInstances = {self.Player.Character}
	local partsInRadius = workspace:GetPartBoundsInRadius(explosionOrigin, self.ExplosionRadius, overlapParams)

	local processedModels = {}

	for _, part in partsInRadius do
		if part.Name ~= "Baseplate" and part.Parent and not processedModels[part.Parent] then
			-- 독 구름에 불을 붙이면 폭발 후 소멸
			if part.Parent.Name:match("Poison") then
				processedModels[part.Parent] = true
				local poisonModel = part.Parent
				local poisonCenter = poisonModel.PrimaryPart and poisonModel.PrimaryPart.Position or part.Position

				-- 화끈한 폭발 이펙트!
				local effectPart = Instance.new("Part")
				effectPart.Name = "PoisonExplosionEffect"
				effectPart.Size = Vector3.new(1, 1, 1)
				effectPart.Position = poisonCenter
				effectPart.Anchored = true
				effectPart.CanCollide = false
				effectPart.Transparency = 1
				effectPart.Parent = workspace

				-- Roblox Explosion 이펙트 (시각 효과만, 데미지 없음)
				local explosion = Instance.new("Explosion")
				explosion.Position = poisonCenter
				explosion.BlastRadius = 0  -- 데미지 없음
				explosion.BlastPressure = 0
				explosion.DestroyJointRadiusPercent = 0
				explosion.ExplosionType = Enum.ExplosionType.NoCraters
				explosion.Parent = workspace

				-- 불꽃 폭발 파티클 (빨강-주황-노랑 화염)
				local fireParticle = Instance.new("ParticleEmitter")
				fireParticle.Name = "PoisonFireBurst"
				fireParticle.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 100)),  -- 밝은 노랑 (불꽃 중심)
					ColorSequenceKeypoint.new(0.2, Color3.fromRGB(255, 180, 0)),  -- 주황
					ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 80, 0)),   -- 빨간 주황
					ColorSequenceKeypoint.new(0.8, Color3.fromRGB(150, 30, 0)),   -- 어두운 빨강
					ColorSequenceKeypoint.new(1, Color3.fromRGB(50, 20, 10))      -- 검은 연기
				})
				fireParticle.Size = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 2),
					NumberSequenceKeypoint.new(0.15, 10),
					NumberSequenceKeypoint.new(0.4, 14),
					NumberSequenceKeypoint.new(1, 0)
				})
				fireParticle.Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 0.1),
					NumberSequenceKeypoint.new(0.3, 0.3),
					NumberSequenceKeypoint.new(0.7, 0.6),
					NumberSequenceKeypoint.new(1, 1)
				})
				fireParticle.Lifetime = NumberRange.new(0.2, 0.45)
				fireParticle.Speed = NumberRange.new(25, 50)
				fireParticle.SpreadAngle = Vector2.new(180, 180)  -- 모든 방향으로
				fireParticle.Acceleration = Vector3.new(0, 20, 0)  -- 위로 올라감
				fireParticle.RotSpeed = NumberRange.new(-200, 200)
				fireParticle.LightEmission = 1
				fireParticle.LightInfluence = 0
				fireParticle.Parent = effectPart
				fireParticle:Emit(150)

				-- 폭발음 재생
				local ReplicatedStorage = game:GetService("ReplicatedStorage")
				local remoteEvent = ReplicatedStorage:FindFirstChild("PlaySoundEvent")
				if remoteEvent then
					remoteEvent:FireAllClients("FireBarrelExplode", 0, 1.2)
				end

				game.Debris:AddItem(effectPart, 0.5)

				-- 범위 내 모두에게 데미지 (자신 포함)
				local poisonExplosionRadius = 10
				local poisonDamage = self.HitDamage * 1.2
				local damageParams = OverlapParams.new()

				local damageParts = workspace:GetPartBoundsInRadius(part.Position, poisonExplosionRadius, damageParams)
				local processedCharacters = {}

				for _, damagePart in damageParts do
					local character = damagePart.Parent
					local humanoid = character and character:FindFirstChild("Humanoid")

					if humanoid and not processedCharacters[character] then
						processedCharacters[character] = true
						local targetPlayer = game.Players:GetPlayerFromCharacter(character)
						local isSelf = targetPlayer == self.Player
						local isSameTeam = CommonUtil:IsSameTeam(self.Player, targetPlayer)

						-- 자기 자신이거나 다른 팀이면 데미지
						if isSelf or not isSameTeam then
							if not isSelf then
								self:SetCreatorTag(humanoid)
							end
							humanoid:TakeDamage(poisonDamage)

							-- 넉백 효과
							local hrp = character:FindFirstChild("HumanoidRootPart")
							if hrp then
								local direction = (hrp.Position - poisonCenter).Unit
								direction = Vector3.new(direction.X, 0.3, direction.Z).Unit

								local bodyVelocity = Instance.new("BodyVelocity")
								bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
								bodyVelocity.Velocity = direction * 50
								bodyVelocity.Parent = hrp
								game.Debris:AddItem(bodyVelocity, 0.25)
							end
						end
					end
				end

				-- 독구름 즉시 소멸
				poisonModel:Destroy()

			-- 기름 웅덩이는 기존 FireSpread 사용 (ToxicOil은 ToxicFireSpread)
			elseif part.Parent.Name:match("Oil") then
				processedModels[part.Parent] = true
				local isToxicOil = part.Parent.Name:match("Toxic")

				for _, oilPart in part.Parent:GetChildren() do
					if oilPart:IsA("BasePart") and not oilPart:FindFirstChild("FireSpread") and not oilPart:FindFirstChild("ToxicFireSpread") then
						local fireScript
						if isToxicOil then
							fireScript = ServerStorage.Scripts.ToxicFireSpread:Clone()
						else
							fireScript = ServerStorage.Scripts.FireSpread:Clone()
						end
						fireScript:SetAttribute("FireStarter", self.Player.Name)
						fireScript.Parent = oilPart
					end
				end

				local modelDestroyer = part.Parent:FindFirstChild("ModelDestroyer")
				if modelDestroyer and modelDestroyer.Configuration and modelDestroyer.Configuration.WaitTime then
					modelDestroyer.Configuration.WaitTime.Value = isToxicOil and self.ToxicFireDuration or self.FireDuration
				end
			end
		end
	end
end

return FireBarrel
