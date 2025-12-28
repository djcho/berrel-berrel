--[[
	WindBarrel: 바람통
	강력한 바람으로 적을 밀어냅니다.
	바람 + 바람 = 토네이도!
	바람 + 불 = 화염 폭풍!
]]

local ServerStorage = game:GetService("ServerStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local BaseBarrel = require(script.Parent.BaseBarrel)
local ItemDb = require(ServerStorage.Items.Database.ItemDb)

local WindBarrel = setmetatable({}, BaseBarrel)
WindBarrel.__index = WindBarrel

function WindBarrel.new(player, toolInfo, level)
	local self = BaseBarrel.new(player, toolInfo, level)
	setmetatable(self, WindBarrel)

	-- ItemDb에서 바람 전용 설정 가져오기
	local itemConfig = ItemDb.Tool["WindBarrel"]
	self.WindSpreadRadius = itemConfig.WindSpreadRadius or 20
	self.GasPushDistance = itemConfig.GasPushDistance or 25
	self.OilPushDistance = itemConfig.OilPushDistance or 15
	self.KnockbackForce = toolInfo.KnockbackForce or itemConfig.KnockbackForce or 80

	return self
end

function WindBarrel:OnTouched(hitPart)
	self:DealDamageToTarget(hitPart, self.HitDamage)
end

function WindBarrel:Throw(targetPosition)
	BaseBarrel.Throw(self, targetPosition)
end

-- 넉백 적용 함수 (플레이어만 대상)
function WindBarrel:ApplyKnockback(character, explosionOrigin)
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChild("Humanoid")

	if not humanoidRootPart or not humanoid or humanoid.Health <= 0 then
		return
	end

	-- 플레이어 캐릭터인지 확인
	local targetPlayer = Players:GetPlayerFromCharacter(character)
	if not targetPlayer then
		return  -- NPC는 넉백 안함
	end

	local direction = (humanoidRootPart.Position - explosionOrigin).Unit
	direction = Vector3.new(direction.X, 0.3, direction.Z).Unit

	-- 넉백 강도 약간 감소 (80 -> 60)
	local knockbackForce = self.KnockbackForce * 0.75

	local bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
	bodyVelocity.Velocity = direction * knockbackForce
	bodyVelocity.Parent = humanoidRootPart

	game.Debris:AddItem(bodyVelocity, 0.3)
end

-- 화염 폭풍 효과 (바람 + 불 조합)
function WindBarrel:CreateFireStorm(fireModel, explosionOrigin)
	-- 화염 폭풍: 불 확산 범위 2배, 대미지 1.5배
	for _, part in fireModel:GetDescendants() do
		if part.Name == "FireSpread" or part.Name == "ToxicFireSpread" then
			part:SetAttribute("WindBoosted", true)
			part:SetAttribute("FireStorm", true)

			-- 불꽃 크기 증가
			local fire = part.Parent:FindFirstChildWhichIsA("Fire")
			if fire then
				fire.Size = fire.Size * 2
				fire.Heat = fire.Heat * 1.5
			end
		end
	end

	-- 주변 적에게 화염 데미지
	local fireStormRadius = 18
	local fireStormDamage = 20

	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Exclude
	overlapParams.FilterDescendantsInstances = {self.Player.Character}

	local partsInRadius = workspace:GetPartBoundsInRadius(explosionOrigin, fireStormRadius, overlapParams)
	local processedCharacters = {}

	for _, part in partsInRadius do
		local character = part.Parent
		local humanoid = character and character:FindFirstChild("Humanoid")

		if humanoid and not processedCharacters[character] then
			processedCharacters[character] = true

			local targetPlayer = Players:GetPlayerFromCharacter(character)
			if targetPlayer and targetPlayer ~= self.Player then
				if not (self.Player.Team and targetPlayer.Team and self.Player.Team == targetPlayer.Team) then
					self:SetCreatorTag(humanoid)
					humanoid:TakeDamage(fireStormDamage)
				end
			end
		end
	end

	-- 화염 폭풍 이펙트
	local effectFolder = ServerStorage:FindFirstChild("Effect")
	if effectFolder then
		local sparkEffect = effectFolder:FindFirstChild("SplashSpark")
		if sparkEffect then
			local stormPart = Instance.new("Part")
			stormPart.Name = "FireStormEffect"
			stormPart.Size = Vector3.new(1, 1, 1)
			stormPart.Position = explosionOrigin
			stormPart.Anchored = true
			stormPart.CanCollide = false
			stormPart.Transparency = 1
			stormPart.Parent = workspace

			local effect = sparkEffect:Clone()
			effect.Parent = stormPart
			if effect:IsA("ParticleEmitter") then
				effect:Emit(50)
			end

			game.Debris:AddItem(stormPart, 3)
		end
	end
end

-- 기름/독 밀어내기 + 화염폭풍 체크
function WindBarrel:SpreadPoolsWithWind(explosionOrigin)
	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Exclude
	overlapParams.FilterDescendantsInstances = {self.Player.Character}

	local partsInRadius = workspace:GetPartBoundsInRadius(explosionOrigin, self.WindSpreadRadius, overlapParams)
	local processedModels = {}
	local triggeredFireStorm = false

	for _, part in partsInRadius do
		if part.Parent and not processedModels[part.Parent] then
			local parentName = part.Parent.Name

			-- 독 구름 밀어내기
			if parentName:match("Poison") then
				processedModels[part.Parent] = true
				self:PushModel(part.Parent, explosionOrigin, 5)  -- 5 스터드만 밀기

				-- 불이 붙어있으면 화염 폭풍
				if not triggeredFireStorm then
					for _, child in part.Parent:GetDescendants() do
						if child.Name == "ToxicFireSpread" or child.Name == "FireSpread" then
							triggeredFireStorm = true
							self:CreateFireStorm(part.Parent, explosionOrigin)
							break
						end
					end
				end

			-- 기름 웅덩이 밀어내기
			elseif parentName:match("Oil") then
				processedModels[part.Parent] = true
				self:PushModel(part.Parent, explosionOrigin, 3)  -- 3 스터드만 밀기

				-- 불이 붙어있으면 화염 폭풍
				if not triggeredFireStorm then
					for _, child in part.Parent:GetDescendants() do
						if child.Name == "FireSpread" or child.Name == "ToxicFireSpread" then
							triggeredFireStorm = true
							self:CreateFireStorm(part.Parent, explosionOrigin)
							break
						end
					end
				end
			end
		end
	end

	return triggeredFireStorm
end

-- 모델을 바람 방향으로 밀어내는 함수
function WindBarrel:PushModel(model, explosionOrigin, distance)
	local primaryPart = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
	if not primaryPart then return end

	local direction = (primaryPart.Position - explosionOrigin).Unit
	direction = Vector3.new(direction.X, 0, direction.Z).Unit

	local targetPosition = primaryPart.Position + direction * distance

	local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

	for _, part in model:GetChildren() do
		if part:IsA("BasePart") then
			local offset = part.Position - primaryPart.Position
			local targetPos = targetPosition + offset
			local tween = TweenService:Create(part, tweenInfo, {Position = targetPos})
			tween:Play()
		end
	end
end

-- 토네이도 효과 (바람 + 바람 조합)
function WindBarrel:CreateTornado(position)
	-- 충돌 감지용 투명 파트
	local tornadoPart = Instance.new("Part")
	tornadoPart.Name = "Tornado"
	tornadoPart.Size = Vector3.new(15, 40, 15)
	tornadoPart.Position = position + Vector3.new(0, 5, 0)
	tornadoPart.Anchored = true
	tornadoPart.CanCollide = false
	tornadoPart.CanQuery = false
	tornadoPart.CanTouch = false
	tornadoPart.Transparency = 1
	tornadoPart.Parent = workspace

	-- 토네이도 메시파트 (시각 효과)
	local tornadoMesh = nil
	-- 토네이도 메시가 X축 -90도 회전된 상태로 저장되어 있으므로, 수직으로 세우기 위해 X축 90도 회전 적용
	local standUpRotation = CFrame.Angles(math.rad(90), 0, 0)
	local partsFolder = ServerStorage:FindFirstChild("Parts")
	local tornadoTemplate = partsFolder and partsFolder:FindFirstChild("Tornado")

	if tornadoTemplate then
		tornadoMesh = tornadoTemplate:Clone()

		-- Model인 경우와 Part인 경우 처리
		if tornadoMesh:IsA("Model") then
			-- 수직으로 세워서 배치
			tornadoMesh:PivotTo(CFrame.new(position) * standUpRotation)
			for _, part in tornadoMesh:GetDescendants() do
				if part:IsA("BasePart") then
					part.Anchored = true
					part.CanCollide = false
					part.CanQuery = false
					part.CanTouch = false
				end
			end
		elseif tornadoMesh:IsA("BasePart") then
			-- 수직으로 세워서 배치
			tornadoMesh.CFrame = CFrame.new(position) * standUpRotation
			tornadoMesh.Anchored = true
			tornadoMesh.CanCollide = false
			tornadoMesh.CanQuery = false
			tornadoMesh.CanTouch = false
		end

		tornadoMesh.Parent = workspace
	end

	-- 토네이도 중앙 SplashAir 이펙트 (바닥에 위치)
	local effectPart = nil
	local effectFolder = ServerStorage:FindFirstChild("Effect")
	if effectFolder then
		local airEffect = effectFolder:FindFirstChild("SplashAir")
		if airEffect then
			effectPart = Instance.new("Part")
			effectPart.Name = "TornadoEffect"
			effectPart.Size = Vector3.new(1, 1, 1)
			effectPart.Position = position + Vector3.new(0, 1, 0)  -- 바닥 근처
			effectPart.Anchored = true
			effectPart.CanCollide = false
			effectPart.CanQuery = false
			effectPart.CanTouch = false
			effectPart.Transparency = 1
			effectPart.Parent = workspace

			local effect = airEffect:Clone()
			effect.Parent = effectPart
		end
	end

	-- 토네이도 지속 효과 (5초간 주변 플레이어를 빨아들이며 회전)
	local tornadoRadius = 11
	local tornadoDuration = 5
	local startTime = tick()
	local ownerPlayer = self.Player
	local rotationSpeed = 360  -- 초당 360도 회전
	local tickCount = 0

	task.spawn(function()
		while tick() - startTime < tornadoDuration do
			if not tornadoPart or not tornadoPart.Parent then break end

			-- 토네이도 메시 회전 (Y축 회전 먼저 적용 후 세우기)
			if tornadoMesh and tornadoMesh.Parent then
				local elapsed = tick() - startTime
				local rotation = elapsed * rotationSpeed
				-- Y축 회전을 먼저 적용한 다음 세우기 회전 적용
				local rotateCFrame = CFrame.new(position) * CFrame.Angles(0, math.rad(rotation), 0) * standUpRotation

				if tornadoMesh:IsA("Model") then
					tornadoMesh:PivotTo(rotateCFrame)
				elseif tornadoMesh:IsA("BasePart") then
					tornadoMesh.CFrame = rotateCFrame
				end
			end

			-- 주기적으로 이펙트 방출
			tickCount = tickCount + 1
			if effectPart and effectPart.Parent and tickCount % 6 == 0 then
				local effect = effectPart:FindFirstChildWhichIsA("ParticleEmitter")
				if effect then
					effect:Emit(10)
				end
			end

			-- 모든 오브젝트 감지
			local overlapParams = OverlapParams.new()
			overlapParams.FilterType = Enum.RaycastFilterType.Exclude
			overlapParams.FilterDescendantsInstances = {}

			local partsInRadius = workspace:GetPartBoundsInRadius(tornadoPart.Position, tornadoRadius, overlapParams)
			local processedCharacters = {}
			local processedObjects = {}

			for _, part in partsInRadius do
				-- 플레이어 처리
				local character = part.Parent
				local humanoid = character and character:FindFirstChild("Humanoid")

				if humanoid and not processedCharacters[character] then
					processedCharacters[character] = true

					local targetPlayer = Players:GetPlayerFromCharacter(character)
					if targetPlayer then
						local hrp = character:FindFirstChild("HumanoidRootPart")
						if hrp then
							local toCenter = (tornadoPart.Position - hrp.Position)
							local distance = toCenter.Magnitude

							local pullStrength = math.clamp((tornadoRadius - distance) / tornadoRadius, 0.2, 1)
							local tangent = Vector3.new(-toCenter.Z, 0, toCenter.X).Unit
							local inward = toCenter.Unit

							local bodyVelocity = Instance.new("BodyVelocity")
							bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
							bodyVelocity.Velocity = tangent * 30 + inward * (20 * pullStrength) + Vector3.new(0, 20 * pullStrength, 0)
							bodyVelocity.Parent = hrp
							game.Debris:AddItem(bodyVelocity, 0.25)

							-- 틱당 데미지 (적만)
							local isSameTeam = ownerPlayer.Team and targetPlayer.Team and ownerPlayer.Team == targetPlayer.Team
							local isSelf = targetPlayer == ownerPlayer
							if distance < 10 and not isSelf and not isSameTeam then
								humanoid:TakeDamage(3)
							end
						end
					end
				-- 오브젝트 처리 (독, 불, 날아가는 배럴)
				elseif part:IsA("BasePart") then
					local parentModel = part.Parent
					local parentName = parentModel and parentModel.Name or ""

					-- 제외할 것들: 투사체 가이드, 토네이도 자체, 이펙트
					local isExcluded = part.Name == "TargetPart"
						or part.Name == "Tornado"
						or part.Name == "TornadoEffect"
						or part.Name == "WindZone"
						or part:FindFirstChildWhichIsA("Beam")

					if isExcluded then
						continue
					end

					-- 기름인지 확인
					local isOil = parentName:match("Oil") or part.Name:match("Oil")

					-- 기름에 붙은 Fire 이펙트는 작은 불들로 분리해서 토네이도로 빨아들임
					if isOil then
						local fireEffect = part:FindFirstChildWhichIsA("Fire")

						if fireEffect and not processedObjects[fireEffect] then
							processedObjects[fireEffect] = true

							-- 작은 불 파편 여러 개 생성 (3~5개)
							local fireCount = math.random(3, 5)
							for _ = 1, fireCount do
								local firePart = Instance.new("Part")
								firePart.Name = "TornadoFire"
								firePart.Size = Vector3.new(0.5, 0.5, 0.5)
								-- 랜덤 오프셋으로 흩어지게
								local randomOffset = Vector3.new(
									math.random(-3, 3),
									math.random(0, 2),
									math.random(-3, 3)
								)
								firePart.Position = part.Position + randomOffset
								firePart.Anchored = false
								firePart.CanCollide = false
								firePart.CanQuery = false
								firePart.Transparency = 1
								firePart.Parent = workspace

								-- 작은 불 이펙트 복제
								local newFire = Instance.new("Fire")
								newFire.Size = fireEffect.Size * 0.4
								newFire.Heat = fireEffect.Heat * 0.5
								newFire.Color = fireEffect.Color
								newFire.SecondaryColor = fireEffect.SecondaryColor
								newFire.Parent = firePart

								-- 토네이도 중심으로 빨려들어가기 (토네이도가 사라질 때까지)
								task.spawn(function()
									while firePart and firePart.Parent do
										-- 토네이도가 사라지면 불도 사라짐
										if not tornadoPart or not tornadoPart.Parent then
											if firePart and firePart.Parent then
												firePart:Destroy()
											end
											break
										end

										local toCenter = (tornadoPart.Position - firePart.Position)
										local dist = toCenter.Magnitude
										local pullStr = math.clamp((tornadoRadius * 2 - dist) / (tornadoRadius * 2), 0.3, 1)
										local tangent = Vector3.new(-toCenter.Z, 0, toCenter.X).Unit
										local inward = toCenter.Unit

										-- BodyVelocity로 부드럽게 이동
										local existingBV = firePart:FindFirstChild("FireVelocity")
										if existingBV then existingBV:Destroy() end

										local bv = Instance.new("BodyVelocity")
										bv.Name = "FireVelocity"
										bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
										bv.Velocity = tangent * 20 + inward * (25 * pullStr) + Vector3.new(0, 10 * pullStr, 0)
										bv.Parent = firePart
										game.Debris:AddItem(bv, 0.1)

										task.wait(0.08)
									end
								end)
							end

							-- 원래 Fire 크기 줄이기 (일부만 남김)
							fireEffect.Size = fireEffect.Size * 0.3
						end
						continue  -- 기름 파트 자체는 이동하지 않음
					end

					-- 빨아들일 대상: 독, 불이 붙은 파트, 날아가는 배럴
					local isPoison = parentName:match("Poison") or part.Name:match("Poison")
					local hasFire = part:FindFirstChildWhichIsA("Fire")
					local isBarrel = (parentName:match("Barrel") or part.Name:match("Barrel")) and not part.Anchored

					local shouldPull = isPoison or hasFire or isBarrel

					if shouldPull and not processedObjects[part] then
						processedObjects[part] = true

						local toCenter = (tornadoPart.Position - part.Position)
						local distance = toCenter.Magnitude
						local pullStrength = math.clamp((tornadoRadius - distance) / tornadoRadius, 0.2, 1)
						local tangent = Vector3.new(-toCenter.Z, 0, toCenter.X).Unit
						local inward = toCenter.Unit

						-- Anchored된 오브젝트는 Tween으로 이동
						if part.Anchored then
							local targetPos = part.Position + tangent * 2 + inward * 1.5
							TweenService:Create(part, TweenInfo.new(0.1), {Position = targetPos}):Play()
						else
							-- Anchored=false는 BodyVelocity로 이동
							local existingBV = part:FindFirstChild("TornadoVelocity")
							if existingBV then existingBV:Destroy() end

							local bodyVelocity = Instance.new("BodyVelocity")
							bodyVelocity.Name = "TornadoVelocity"
							bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
							bodyVelocity.Velocity = tangent * 25 + inward * (15 * pullStrength) + Vector3.new(0, 15 * pullStrength, 0)
							bodyVelocity.Parent = part
							game.Debris:AddItem(bodyVelocity, 0.25)
						end
					end
				end
			end

			-- 독구름 모델 직접 검색 (CanQuery=false여서 GetPartBoundsInRadius에 안잡히는 경우 대응)
			-- 밀도 감소는 매 틱마다 적용해야 하므로 processedObjects와 별도로 처리
			for _, child in workspace:GetChildren() do
				if child:IsA("Model") and child.Name:match("Poison") then
					local primaryPart = child.PrimaryPart or child:FindFirstChildWhichIsA("BasePart")
					if primaryPart then
						local distance = (primaryPart.Position - tornadoPart.Position).Magnitude
						if distance < tornadoRadius * 1.5 then
							-- 밀도 시스템: 토네이도에 빨려들수록 밀도 감소
							local currentDensity = child:GetAttribute("Density") or 100
							local densityDrain = 3  -- 틱당 밀도 감소량 (0.05초마다 3% = 초당 60%)
							local newDensity = math.max(0, currentDensity - densityDrain)
							child:SetAttribute("Density", newDensity)

							-- 독구름의 모든 파츠를 토네이도 중심으로 이동 (한번만)
							if not processedObjects[child] then
								processedObjects[child] = true
								for _, part in child:GetDescendants() do
									if part:IsA("BasePart") then
										local toCenter = (tornadoPart.Position - part.Position)
										local tangent = Vector3.new(-toCenter.Z, 0, toCenter.X).Unit
										local inward = toCenter.Unit

										local targetPos = part.Position + tangent * 2 + inward * 1.5
										TweenService:Create(part, TweenInfo.new(0.1), {Position = targetPos}):Play()
									end
								end
							end
						end
					end
				end
			end

			task.wait(0.05)
		end

		-- 토네이도 종료
		if tornadoPart and tornadoPart.Parent then
			tornadoPart:Destroy()
		end
		if tornadoMesh and tornadoMesh.Parent then
			tornadoMesh:Destroy()
		end
		if effectPart and effectPart.Parent then
			effectPart:Destroy()
		end
	end)
end

-- 바람 영역 생성 (토네이도 조합 감지용)
function WindBarrel:CreateWindZone(position)
	local windZone = Instance.new("Part")
	windZone.Name = "WindZone"
	windZone.Size = Vector3.new(20, 10, 20)
	windZone.Position = position
	windZone.Anchored = true
	windZone.CanCollide = false
	windZone.CanQuery = false  -- 마우스 레이캐스트에서 무시
	windZone.CanTouch = false
	windZone.Transparency = 1
	windZone.Parent = workspace
	windZone:SetAttribute("WindBarrelZone", true)
	windZone:SetAttribute("Owner", self.Player.Name)

	-- SplashAir 이펙트 지속 표시
	local effectFolder = ServerStorage:FindFirstChild("Effect")
	if effectFolder then
		local airEffect = effectFolder:FindFirstChild("SplashAir")
		if airEffect then
			local effect = airEffect:Clone()
			effect.Parent = windZone

			-- 3초간 주기적으로 이펙트 방출
			task.spawn(function()
				local duration = 3
				local startTime = tick()
				while tick() - startTime < duration do
					if not windZone or not windZone.Parent then break end
					if effect:IsA("ParticleEmitter") then
						effect:Emit(5)
					end
					task.wait(0.3)
				end
			end)
		end
	end

	-- 3초 후 자동 소멸
	game.Debris:AddItem(windZone, 3)

	return windZone
end

-- 주변에 다른 바람 영역이 있는지 확인
-- 반환값: "windzone" = 바람 영역 발견 (토네이도 생성)
--        nil = 아무것도 없음 (바람 영역 생성)
function WindBarrel:CheckWindCombo(position)
	-- workspace 직접 검색 (GetPartBoundsInRadius는 CanQuery=false인 파트를 못 찾음)
	local foundWindZone = false
	local partsToDestroy = {}

	for _, child in workspace:GetChildren() do
		-- WindZone만 체크 (TornadoEffect는 토네이도의 이펙트이므로 제외)
		if child.Name == "WindZone" then
			local distance = (child.Position - position).Magnitude
			if distance < 20 then
				table.insert(partsToDestroy, child)
				foundWindZone = true
			end
		end
	end

	-- 찾은 WindZone 모두 삭제
	for _, part in partsToDestroy do
		part:Destroy()
	end

	if foundWindZone then
		return "windzone"
	end
	return nil
end

function WindBarrel:Explode(hitPart, hitPosition)
	if BaseBarrel.Explode(self, hitPart, hitPosition) == false then
		return
	end

	local explosionOrigin = self.BarrelPart.Position

	-- 바람 + 바람 = 토네이도 체크
	local comboResult = self:CheckWindCombo(explosionOrigin)
	if comboResult == "windzone" then
		-- 바람 영역이 있으면 토네이도 생성
		self:CreateTornado(explosionOrigin)
	else
		-- 아무것도 없거나 토네이도가 있어도 바람 영역 생성 (다음 바람통과 조합 가능)
		self:CreateWindZone(explosionOrigin)
	end

	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Exclude
	overlapParams.FilterDescendantsInstances = {self.Player.Character}
	local partsInRadius = workspace:GetPartBoundsInRadius(explosionOrigin, self.ExplosionRadius, overlapParams)

	local processedCharacters = {}
	for _, part in partsInRadius do
		local character = part.Parent
		local humanoid = character and character:FindFirstChild("Humanoid")

		if humanoid and not processedCharacters[character] then
			processedCharacters[character] = true

			local targetPlayer = Players:GetPlayerFromCharacter(character)
			if targetPlayer and targetPlayer ~= self.Player then
				if not (self.Player.Team and targetPlayer.Team and self.Player.Team == targetPlayer.Team) then
					self:ApplyKnockback(character, explosionOrigin)
					self:DealDamageToTarget(part, self.HitDamage)
				end
			end
		end
	end

	-- 기름/독 밀어내기 + 화염폭풍 체크
	self:SpreadPoolsWithWind(explosionOrigin)
end

return WindBarrel
