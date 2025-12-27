-- ToxicFireSpread: 독 웅덩이에 불이 붙었을 때 초록색 독성 화염 생성
-- 일반 화염보다 강한 데미지를 줌

-- ServerStorage에 있을 때는 실행하지 않음 (Clone되어 workspace로 갈 때만 실행)
if script.Parent:IsDescendantOf(game:GetService("ServerStorage")) then
	return
end

local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")
local CommonUtil = require(ServerStorage.Scripts.CommonUtil)

-- 불을 붙인 플레이어 정보 가져오기
local fireStarterName = script:GetAttribute("FireStarter")
local fireStarter = fireStarterName and Players:FindFirstChild(fireStarterName)

local BASE_SPREAD_RADIUS = 12  -- 기본 독성 화염 확산 반경 (일반보다 넓음)
local SPREAD_INTERVAL = 0.5  -- 확산 체크 간격
local WIND_BOOST_RADIUS = 20  -- 바람 부스트 시 확산 반경
local TOXIC_DOT_DAMAGE = 15  -- 독성 화염 틱당 데미지 (일반 화염 10 + 독 5 = 15)
local TOXIC_DOT_TICKS = 4  -- 데미지 틱 횟수 (일반보다 1회 더)

local burningEndFlag = false

-- 바람 부스트 확인 함수
local function getSpreadRadius()
	if script:GetAttribute("WindBoosted") then
		return WIND_BOOST_RADIUS
	end
	return BASE_SPREAD_RADIUS
end

-- 불 확산 대상에 스크립트를 추가하는 헬퍼 함수
local function attachFireToTarget(targetPart)
	local newScript = script:Clone()
	newScript.Parent = targetPart
	newScript.Disabled = false

	-- 사라지는 시간을 초기화하는 처리 추가
	local modelDestroyer = targetPart.Parent:FindFirstChild("ModelDestroyer")
	if modelDestroyer and modelDestroyer.Configuration and modelDestroyer.Configuration.WaitTime then
		modelDestroyer.Configuration.WaitTime.Value = 12 -- 독성 화염은 12초 지속
	end
end

local function Burning()
	while not burningEndFlag do
		-- GetPartBoundsInRadius 사용 (Part 생성 없이 성능 개선)
		local overlapParams = OverlapParams.new()
		overlapParams.FilterType = Enum.RaycastFilterType.Exclude
		overlapParams.FilterDescendantsInstances = {script.Parent}

		local partsInRadius = workspace:GetPartBoundsInRadius(script.Parent.Position, getSpreadRadius(), overlapParams)

		for _, SpreadPart in partsInRadius do
			if CommonUtil:IsPartIncludedCharacter(SpreadPart) then
				-- 캐릭터에는 일반 FireSpread와 ToxicFireSpread 둘 다 확인
				if not SpreadPart.Parent:FindFirstChild("FireSpread", true) and not SpreadPart.Parent:FindFirstChild("ToxicFireSpread", true) then
					attachFireToTarget(SpreadPart)
				end
			elseif SpreadPart:FindFirstChild("burnable") then
				if not SpreadPart:FindFirstChild("FireSpread") and not SpreadPart:FindFirstChild("ToxicFireSpread") then
					attachFireToTarget(SpreadPart)
				end
			end
		end

		task.wait(SPREAD_INTERVAL)
	end
end

-- 같은 팀인지 확인
local function isSameTeamAsFireStarter(targetPlayer)
	if not fireStarter or not targetPlayer then
		return false
	end
	return fireStarter.Team and targetPlayer.Team and fireStarter.Team == targetPlayer.Team
end

-- creator 태그 설정 함수 (킬/어시스트 시스템용)
local function setCreatorTag(humanoid, targetPlayer)
	if not fireStarter then return end

	-- 같은 팀이면 creator 태그 설정 안함 (팀킬 방지)
	if isSameTeamAsFireStarter(targetPlayer) then return end

	-- 기존 creator 태그 제거
	local existingCreator = humanoid:FindFirstChild("creator")
	if existingCreator then
		existingCreator:Destroy()
	end

	-- 새 creator 태그 생성
	local creator = Instance.new("ObjectValue")
	creator.Name = "creator"
	creator.Value = fireStarter
	creator.Parent = humanoid

	-- 5초 후 자동 제거
	game.Debris:AddItem(creator, 5)
end

local function TakeToxicDotDamage(humanoid, targetPlayer)
	if not humanoid then
		return
	end

	-- 같은 팀이면 데미지 안줌 (팀킬 방지)
	if isSameTeamAsFireStarter(targetPlayer) then
		return
	end

	-- 독성 화염 데미지: 일반보다 강함
	for _ = 1, TOXIC_DOT_TICKS do
		-- 매 데미지마다 creator 태그 갱신
		setCreatorTag(humanoid, targetPlayer)
		humanoid:TakeDamage(TOXIC_DOT_DAMAGE)
		task.wait(1)
	end
end

-- 초록색 독성 화염 이펙트 생성
local fire = Instance.new("Fire", script.Parent)
fire.Color = Color3.fromRGB(0, 255, 0)  -- 초록색 불꽃
fire.SecondaryColor = Color3.fromRGB(100, 200, 50)  -- 연두색 보조 색상

local smoke = Instance.new("Smoke", script.Parent)
smoke.Color = Color3.fromRGB(50, 150, 50)  -- 초록색 연기
smoke.Opacity = 0.05
smoke.RiseVelocity = 6
smoke.Size = 0.15
smoke.Parent = fire.Parent

if CommonUtil:IsPartIncludedCharacter(script.Parent) then
	fire.Size = 6  -- 캐릭터에 붙은 불은 더 큼
else
	local originalSize = script.Parent:GetAttribute("OriginalSize")
	if originalSize then
		fire.Size = math.abs(originalSize.X) + math.abs(originalSize.Y) + math.abs(originalSize.Z)
	else
		fire.Size = 10
	end
end

task.wait(0.15)

task.spawn(Burning)

-- PoisonFog 모델에 붙은 경우
if script.Parent.Parent.Name:match("Poison") then
	-- 사라지는 시간을 초기화
	local modelDestroyer = script.Parent.Parent:FindFirstChild("ModelDestroyer")
	if modelDestroyer and modelDestroyer.Configuration and modelDestroyer.Configuration.WaitTime then
		modelDestroyer.Configuration.WaitTime.Value = 12 -- 독성 화염은 12초 지속
	end

	-- PoisonDamage 스크립트 비활성화 (독성 화염이 대신 데미지를 줌)
	local poisonDamage = script.Parent.Parent:FindFirstChild("PoisonDamage")
	if poisonDamage then
		poisonDamage:SetAttribute("Disabled", true)
	end

	task.wait(12)  -- 독성 화염은 12초 지속 (일반 10초보다 길음)
	fire:Destroy()
	smoke:Destroy()

	script.Parent.Material = Enum.Material.CorrodedMetal
	script.Parent:BreakJoints()

	local Debris = game:GetService("Debris")

	local poisonPartCount = 0
	for _, v in pairs(script.Parent.Parent:GetChildren()) do
		if v:IsA("BasePart") then
			poisonPartCount += 1
		end
	end

	if poisonPartCount == 1 then
		Debris:AddItem(script.Parent.Parent, 0.2)
	else
		script.Parent:Destroy()
	end
	burningEndFlag = true
elseif CommonUtil:IsPartIncludedCharacter(script.Parent) then
	local humanoid = CommonUtil:GetHumanoidByPart(script.Parent)
	local targetPlayer = CommonUtil:GetPlayerByPart(script.Parent)
	task.spawn(function()
		TakeToxicDotDamage(humanoid, targetPlayer)
	end)
	task.wait(5)  -- 캐릭터에 붙은 독성 화염은 5초 지속
	burningEndFlag = true
	fire:Destroy()
	smoke:Destroy()
	script:Destroy()
	return
end
