-- PoisonDamage: 독 구름 영역 내 플레이어에게 DoT 피해 적용
local SimpleZone = require(game:GetService("ReplicatedStorage"):WaitForChild("SimpleZone"))
local Players = game:GetService("Players")

local model = script.Parent

-- 독을 뿌린 플레이어 정보 가져오기
local poisonOwnerName = script:GetAttribute("PoisonOwner")
local poisonOwner = poisonOwnerName and Players:FindFirstChild(poisonOwnerName)

-- 같은 팀인지 확인
local function isSameTeamAsPoisonOwner(targetPlayer)
	if not poisonOwner or not targetPlayer then
		return false
	end
	return poisonOwner.Team and targetPlayer.Team and poisonOwner.Team == targetPlayer.Team
end

-- 독 피해 설정
local DOT_DAMAGE = 5  -- 틱당 피해량
local DOT_INTERVAL = 1  -- 피해 간격 (초)

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

-- 플레이어에게 지속 피해를 주는 함수
local function applyPoisonDamage(player)
	while playersInZone[player] do
		local character = player.Character
		if character then
			local humanoid = character:FindFirstChild("Humanoid")
			if humanoid and humanoid.Health > 0 then
				-- 매 데미지마다 creator 태그 갱신 (같은 팀이면 무시)
				setCreatorTag(humanoid, player)
				humanoid:TakeDamage(DOT_DAMAGE)
			end
		end
		task.wait(DOT_INTERVAL)
	end
end

local function onPlayerEnter(player)
	if playersInZone[player] then
		return
	end

	playersInZone[player] = true

	-- 독 피해 스레드 시작
	damageThreads[player] = task.spawn(function()
		applyPoisonDamage(player)
	end)
end

local function onPlayerExit(player)
	playersInZone[player] = nil

	-- 피해 스레드 정리
	if damageThreads[player] then
		task.cancel(damageThreads[player])
		damageThreads[player] = nil
	end
end

local enterConnection = zone.playerEntered:Connect(onPlayerEnter)
local exitConnection = zone.playerExited:Connect(onPlayerExit)

-- 모델이 제거될 때 정리
local function cleanup()
	enterConnection:Disconnect()
	exitConnection:Disconnect()
	zone:destroy()

	-- 모든 피해 스레드 정리
	for player, thread in damageThreads do
		task.cancel(thread)
		playersInZone[player] = nil
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
