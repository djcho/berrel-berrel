-- PoisonDamage: 독 구름 영역 내 플레이어에게 DoT 피해 + 중독 게이지 시스템
local SimpleZone = require(game:GetService("ReplicatedStorage"):WaitForChild("SimpleZone"))
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local model = script.Parent

-- 독을 뿌린 플레이어 정보 가져오기
local poisonOwnerName = script:GetAttribute("PoisonOwner")
local poisonOwner = poisonOwnerName and Players:FindFirstChild(poisonOwnerName)

-- 맹독 구름인지 확인 (DeadlyPoisonFog)
local isDeadlyPoison = model.Name:match("Deadly") ~= nil

-- 같은 팀인지 확인
local function isSameTeamAsPoisonOwner(targetPlayer)
	if not poisonOwner or not targetPlayer then
		return false
	end
	return poisonOwner.Team and targetPlayer.Team and poisonOwner.Team == targetPlayer.Team
end

-- 독 피해 설정
local BASE_DOT_DAMAGE = 5  -- 기본 틱당 피해량
local DOT_INTERVAL = 1  -- 피해 간격 (초)
local damageMultiplier = script:GetAttribute("DamageMultiplier") or 1  -- 데미지 배율 (독성 슬라임은 1.5)

-- 밀도 기반 데미지 계산 함수
local function getDensityMultiplier()
	local density = model:GetAttribute("Density") or 100
	return math.clamp(density / 100, 0, 1.5)  -- 0% ~ 150% 밀도
end

-- 밀도 기반 파티클 Rate 업데이트 함수
local function updateParticleRates()
	local density = model:GetAttribute("Density") or 100
	local densityRatio = math.clamp(density / 100, 0, 1.5)

	for _, part in model:GetDescendants() do
		if part:IsA("ParticleEmitter") then
			local baseRate = part:GetAttribute("BaseRate")
			if baseRate then
				part.Rate = baseRate * densityRatio
			end
		end
	end
end

-- 밀도가 0 이하면 독구름 소멸
local function checkDensityDestroy()
	local density = model:GetAttribute("Density") or 100
	if density <= 0 then
		model:Destroy()
		return true
	end
	return false
end

-- 중독 게이지 설정
local POISON_GAUGE_MAX = 100  -- 최대 게이지
local POISON_DRAIN_RATE = isDeadlyPoison and 25 or 15  -- 맹독은 25/초, 일반독은 15/초
local POISON_RECOVERY_RATE = 20  -- 영역 밖에서 회복 속도 (20/초)
local STUN_DURATION = isDeadlyPoison and 1.5 or 1  -- 맹독 1.5초, 일반독 1초 기절

-- 중독 게이지 RemoteEvent (없으면 생성)
local poisonSystem = ReplicatedStorage:FindFirstChild("PoisonSystem")
if not poisonSystem then
	poisonSystem = Instance.new("Folder")
	poisonSystem.Name = "PoisonSystem"
	poisonSystem.Parent = ReplicatedStorage
end

local poisonGaugeEvent = poisonSystem:FindFirstChild("PoisonGaugeEvent")
if not poisonGaugeEvent then
	poisonGaugeEvent = Instance.new("RemoteEvent")
	poisonGaugeEvent.Name = "PoisonGaugeEvent"
	poisonGaugeEvent.Parent = poisonSystem
end

-- 전역 중독 게이지 저장소 (모든 독구름이 공유)
local globalPoisonGauges = _G.PoisonGauges or {}
_G.PoisonGauges = globalPoisonGauges

local globalStunned = _G.PoisonStunned or {}
_G.PoisonStunned = globalStunned

local globalRecoveryThreads = _G.PoisonRecoveryThreads or {}
_G.PoisonRecoveryThreads = globalRecoveryThreads

-- 전역 플레이어 독구름 카운터 (몇 개의 독구름에 있는지)
local globalPlayersInPoison = _G.PlayersInPoison or {}
_G.PlayersInPoison = globalPlayersInPoison


-- 맹독 구름은 Tween이 완료될 때까지 잠시 대기 (파트 크기 확장 완료 대기)
if isDeadlyPoison then
	task.wait(0.6)
end

-- 영역 경계 계산
local minBounds = Vector3.new(math.huge, math.huge, math.huge)
local maxBounds = Vector3.new(-math.huge, -math.huge, -math.huge)

local playersInZone = {}
local damageThreads = {}

for _, part in model:GetDescendants() do
	if part:IsA("BasePart") then
		local partPosition = part.Position
		local partSize = part.Size / 2

		local partMin = partPosition - partSize
		local partMax = partPosition + partSize

		minBounds = Vector3.new(
			math.min(minBounds.X, partMin.X),
			math.min(minBounds.Y, partMin.Y),
			math.min(minBounds.Z, partMin.Z)
		)

		maxBounds = Vector3.new(
			math.max(maxBounds.X, partMax.X),
			math.max(maxBounds.Y, partMax.Y),
			math.max(maxBounds.Z, partMax.Z)
		)
	end
end

maxBounds = maxBounds + Vector3.new(0, 50, 0)

local region = Region3.new(minBounds, maxBounds)
local zone = SimpleZone.fromRegion(region.CFrame, region.Size)

-- creator 태그 설정 함수 (킬/어시스트 시스템용)
local function setCreatorTag(humanoid, targetPlayer)
	if not poisonOwner then return end

	-- 같은 팀이면 creator 태그 설정 안함 (팀킬 방지)
	if isSameTeamAsPoisonOwner(targetPlayer) then return end

	-- 기존 creator 태그 제거
	local existingCreator = humanoid:FindFirstChild("creator")
	if existingCreator then
		existingCreator:Destroy()
	end

	-- 새 creator 태그 생성
	local creator = Instance.new("ObjectValue")
	creator.Name = "creator"
	creator.Value = poisonOwner
	creator.Parent = humanoid

	-- 5초 후 자동 제거
	game.Debris:AddItem(creator, 5)
end

-- 독성 화염이 시작되었는지 확인 (ToxicFireSpread가 붙으면 독 데미지 중지)
local function isToxicFireActive()
	-- Disabled 속성이 true면 독성 화염이 활성화된 것
	return script:GetAttribute("Disabled") == true
end

-- Forward declaration
local startRecoveryThread

-- 기절 효과 적용
local function applyStun(player, humanoid)
	if globalStunned[player] then return end
	globalStunned[player] = true

	-- 클라이언트에 기절 알림
	poisonGaugeEvent:FireClient(player, "stun", STUN_DURATION)

	-- 이동 불가 처리
	local walkSpeedBackup = humanoid.WalkSpeed
	local jumpPowerBackup = humanoid.JumpPower
	humanoid.WalkSpeed = 0
	humanoid.JumpPower = 0

	-- 쓰러지는 애니메이션 (Ragdoll 대신 간단한 처리)
	local character = player.Character
	if character then
		local hrp = character:FindFirstChild("HumanoidRootPart")
		if hrp then
			-- 캐릭터를 뒤로 넘어뜨림
			hrp.CFrame = hrp.CFrame * CFrame.Angles(math.rad(-80), 0, 0)
		end
	end

	-- 기절 시간 동안 게이지 회복 (0% -> 100%)
	globalPoisonGauges[player] = 0
	task.spawn(function()
		local elapsed = 0
		local interval = 0.1
		while elapsed < STUN_DURATION and globalStunned[player] do
			elapsed = elapsed + interval
			-- 기절 시간 동안 0% -> 100%로 회복
			local progress = math.min(1, elapsed / STUN_DURATION)
			globalPoisonGauges[player] = POISON_GAUGE_MAX * progress
			poisonGaugeEvent:FireClient(player, "update", globalPoisonGauges[player], POISON_GAUGE_MAX)
			task.wait(interval)
		end
	end)

	-- 기절 시간 후 복구
	task.delay(STUN_DURATION, function()
		if humanoid and humanoid.Health > 0 then
			humanoid.WalkSpeed = walkSpeedBackup
			humanoid.JumpPower = jumpPowerBackup
		end

		-- 1. 먼저 게이지 100%로 설정 (기절 해제 전에!)
		globalPoisonGauges[player] = POISON_GAUGE_MAX
		poisonGaugeEvent:FireClient(player, "update", POISON_GAUGE_MAX, POISON_GAUGE_MAX)

		-- 2. 2초 대기 (기절에서 완전히 회복되도록)
		task.wait(2)

		-- 3. 기절 해제
		globalStunned[player] = false

		-- 독구름 밖이면 UI 숨기기
		if not globalPlayersInPoison[player] or globalPlayersInPoison[player] == 0 then
			poisonGaugeEvent:FireClient(player, "hide")
			globalPoisonGauges[player] = nil
		end
	end)
end

-- 게이지 회복 스레드 시작
startRecoveryThread = function(player)
	-- 아직 다른 독구름에 있으면 회복 안함
	if globalPlayersInPoison[player] and globalPlayersInPoison[player] > 0 then
		return
	end

	-- 기절 중이면 회복 안함 (기절 회복이 알아서 처리)
	if globalStunned[player] then
		return
	end

	-- 기존 회복 스레드가 있으면 취소
	if globalRecoveryThreads[player] then
		pcall(function()
			task.cancel(globalRecoveryThreads[player])
		end)
		globalRecoveryThreads[player] = nil
	end

	-- 게이지가 없으면 초기화
	if not globalPoisonGauges[player] then
		globalPoisonGauges[player] = 0
		poisonGaugeEvent:FireClient(player, "update", 0, POISON_GAUGE_MAX)
	end

	globalRecoveryThreads[player] = task.spawn(function()
		while globalPoisonGauges[player] and globalPoisonGauges[player] < POISON_GAUGE_MAX do
			-- 다시 어떤 독구름에든 들어갔으면 회복 중지
			if globalPlayersInPoison[player] and globalPlayersInPoison[player] > 0 then
				globalRecoveryThreads[player] = nil
				return
			end

			-- 기절 중이면 회복 중지 (기절 회복이 알아서 처리)
			if globalStunned[player] then
				globalRecoveryThreads[player] = nil
				return
			end

			-- 게이지 회복
			globalPoisonGauges[player] = math.min(POISON_GAUGE_MAX, globalPoisonGauges[player] + POISON_RECOVERY_RATE * 0.1)
			poisonGaugeEvent:FireClient(player, "update", globalPoisonGauges[player], POISON_GAUGE_MAX)

			-- 완전히 회복되면 UI 숨기기
			if globalPoisonGauges[player] >= POISON_GAUGE_MAX then
				poisonGaugeEvent:FireClient(player, "hide")
				globalPoisonGauges[player] = nil
				globalRecoveryThreads[player] = nil
				return
			end

			task.wait(0.1)
		end

		-- 게이지가 nil이 되었거나 이미 가득 찼으면 UI 숨기기
		if not globalPoisonGauges[player] or globalPoisonGauges[player] >= POISON_GAUGE_MAX then
			poisonGaugeEvent:FireClient(player, "hide")
		end
		globalRecoveryThreads[player] = nil
	end)
end

-- 플레이어에게 지속 피해를 주는 함수
local function applyPoisonDamage(player)
	-- 게이지 초기화 (처음 들어왔을 때)
	if not globalPoisonGauges[player] then
		globalPoisonGauges[player] = POISON_GAUGE_MAX
	end

	-- 회복 스레드 중지
	if globalRecoveryThreads[player] then
		task.cancel(globalRecoveryThreads[player])
		globalRecoveryThreads[player] = nil
	end

	local damageTimer = 0

	while playersInZone[player] do
		-- 독성 화염이 시작되면 독 데미지 중지 (독성 화염이 대신 더 강한 데미지를 줌)
		if isToxicFireActive() then
			return
		end

		-- 기절 중이면 기절이 완전히 끝날 때까지 대기 (게이지 건드리지 않음)
		if globalStunned[player] then
			while globalStunned[player] do
				task.wait(0.1)
			end
			-- 기절 해제 시점에 이미 1초 대기 후이므로 바로 continue
			continue
		end

		local character = player.Character
		if character then
			local humanoid = character:FindFirstChild("Humanoid")
			if humanoid and humanoid.Health > 0 then
				-- 밀도 체크 (0 이하면 루프 종료)
				if checkDensityDestroy() then
					return
				end

				local densityMult = getDensityMultiplier()

				-- 게이지가 만땅이면 감소 시작 전 대기 (기절 직후 보호)
				if globalPoisonGauges[player] >= POISON_GAUGE_MAX then
					globalPoisonGauges[player] = POISON_GAUGE_MAX
				end

				-- 중독 게이지 감소 (0.1초마다, 밀도에 비례)
				globalPoisonGauges[player] = globalPoisonGauges[player] - POISON_DRAIN_RATE * 0.1 * densityMult
				poisonGaugeEvent:FireClient(player, "update", globalPoisonGauges[player], POISON_GAUGE_MAX)

				-- 게이지가 0 이하면 기절
				if globalPoisonGauges[player] <= 0 then
					globalPoisonGauges[player] = 0
					setCreatorTag(humanoid, player)
					applyStun(player, humanoid)
				end

				-- 1초마다 DoT 데미지 (밀도 기반)
				damageTimer = damageTimer + 0.1
				if damageTimer >= DOT_INTERVAL then
					damageTimer = 0
					setCreatorTag(humanoid, player)
					-- 밀도에 비례한 데미지 계산
					local currentDamage = math.floor(BASE_DOT_DAMAGE * damageMultiplier * densityMult)
					if currentDamage > 0 then
						humanoid:TakeDamage(currentDamage)
					end
				end
			end
		end
		task.wait(0.1)
	end
end

local function onPlayerEnter(player)
	if playersInZone[player] then
		return
	end

	playersInZone[player] = true

	-- 전역 카운터 증가
	globalPlayersInPoison[player] = (globalPlayersInPoison[player] or 0) + 1

	-- 회복 스레드 중지 (다시 독구름에 들어왔으므로)
	if globalRecoveryThreads[player] then
		task.cancel(globalRecoveryThreads[player])
		globalRecoveryThreads[player] = nil
	end

	-- 독 피해 스레드 시작
	damageThreads[player] = task.spawn(function()
		applyPoisonDamage(player)
	end)
end

local function onPlayerExit(player)
	playersInZone[player] = nil

	-- 피해 스레드 정리
	if damageThreads[player] then
		pcall(function()
			task.cancel(damageThreads[player])
		end)
		damageThreads[player] = nil
	end

	-- 전역 카운터 감소
	globalPlayersInPoison[player] = math.max(0, (globalPlayersInPoison[player] or 1) - 1)

	-- 모든 독구름에서 벗어났을 때만 게이지 회복 시작
	if globalPlayersInPoison[player] == 0 then
		-- 기절 중이면 기절 회복이 알아서 처리함
		if globalStunned[player] then
			return
		end

		-- 게이지가 있고 가득 차지 않았으면 회복 시작
		if globalPoisonGauges[player] and globalPoisonGauges[player] < POISON_GAUGE_MAX then
			startRecoveryThread(player)
		elseif globalPoisonGauges[player] and globalPoisonGauges[player] >= POISON_GAUGE_MAX then
			-- 게이지가 가득 찼으면 UI 숨기기
			poisonGaugeEvent:FireClient(player, "hide")
			globalPoisonGauges[player] = nil
		elseif not globalPoisonGauges[player] then
			-- 게이지가 없으면 UI 숨기기
			poisonGaugeEvent:FireClient(player, "hide")
		end
	end
end

local enterConnection = zone.playerEntered:Connect(onPlayerEnter)
local exitConnection = zone.playerExited:Connect(onPlayerExit)

-- 모델이 제거될 때 정리
local function cleanup()
	enterConnection:Disconnect()
	exitConnection:Disconnect()
	zone:destroy()

	-- 모든 피해 스레드 정리 및 전역 카운터 감소
	for player, thread in damageThreads do
		task.cancel(thread)
		playersInZone[player] = nil

		-- 전역 카운터 감소
		globalPlayersInPoison[player] = math.max(0, (globalPlayersInPoison[player] or 1) - 1)

		-- 모든 독구름에서 벗어났으면 회복 시작
		if globalPlayersInPoison[player] == 0 then
			if globalPoisonGauges[player] and globalPoisonGauges[player] < POISON_GAUGE_MAX then
				startRecoveryThread(player)
			else
				poisonGaugeEvent:FireClient(player, "hide")
				globalPoisonGauges[player] = nil
			end
		end
	end
	damageThreads = {}
end

model.AncestryChanged:Connect(function()
	if not model:IsDescendantOf(game) then
		cleanup()
	end
end)

-- BindableEvent가 있다면 연결 (ModelDestroyer 호환)
local bindableEvent = model:FindFirstChild("OnPartRemoving")
if bindableEvent then
	bindableEvent.Event:Connect(cleanup)
end

-- 밀도 변경 감지: 파티클 Rate 자동 업데이트
model.AttributeChanged:Connect(function(attributeName)
	if attributeName == "Density" then
		updateParticleRates()
		-- 밀도가 0 이하면 소멸
		checkDensityDestroy()
	end
end)
