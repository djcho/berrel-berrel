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

local BASE_SPREAD_RADIUS = 10  -- 기본 불 확산 반경
local SPREAD_INTERVAL = 0.5  -- 확산 체크 간격 (성능 개선)
local WIND_BOOST_RADIUS = 18  -- 바람 부스트 시 확산 반경

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
		modelDestroyer.Configuration.WaitTime.Value = 10 -- 사라지는 시간을 10초로 초기화
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
				if not SpreadPart.Parent:FindFirstChild("FireSpread", true) then
					attachFireToTarget(SpreadPart)
				end
			elseif SpreadPart:FindFirstChild("burnable") then
				if not SpreadPart:FindFirstChild("FireSpread") then
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

local function TakeDotDamage(humanoid, tickDamage, targetPlayer)
	if not humanoid then
		return
	end

	if tickDamage == nil or tickDamage <= 0 then
		tickDamage = 3
	end

	for _ = 1, 3 do
		-- 매 데미지마다 creator 태그 갱신 (같은 팀이면 무시)
		setCreatorTag(humanoid, targetPlayer)
		humanoid:TakeDamage(tickDamage)
		task.wait(1)
	end
end

local fire = Instance.new("Fire", script.Parent)
local smoke = Instance.new("Smoke", script.Parent)
smoke.Color = Color3.new(0, 0, 0)
smoke.Opacity = 0.03
smoke.RiseVelocity = 5
smoke.Size = 0.1
smoke.Parent = fire.Parent
if CommonUtil:IsPartIncludedCharacter(script.Parent) then
	fire.Size = 5
else
	local originalSize = script.Parent:GetAttribute("OriginalSize")
	if originalSize then
		fire.Size = math.abs(originalSize.X) + math.abs(originalSize.Y) + math.abs(originalSize.Z)
	else
		-- OriginalSize가 없으면 파트의 실제 크기 사용
		local partSize = script.Parent.Size
		fire.Size = math.abs(partSize.X) + math.abs(partSize.Y) + math.abs(partSize.Z)
	end
end

task.wait(0.15)

task.spawn(Burning)

if script.Parent.Parent.Name:match("Oil") then
	-- 사라지는 시간을 초기화하는 처리 추가
	local modelDestroyer = script.Parent.Parent:FindFirstChild("ModelDestroyer")
	if modelDestroyer and modelDestroyer.Configuration and modelDestroyer.Configuration.WaitTime then
		modelDestroyer.Configuration.WaitTime.Value = 10 -- 사라지는 시간을 10초로 초기화
	end

	task.wait(10)
	fire:Destroy()
	smoke:Destroy()

	script.Parent.Material = Enum.Material.CorrodedMetal
	script.Parent:BreakJoints()

	local Debris = game:GetService("Debris")

	local oilPartCount = 0
	for _, v in pairs(script.Parent.Parent:GetChildren()) do
		if v.Name == "OilPart" then
			oilPartCount += 1
		end
	end

	if oilPartCount == 1 then
		Debris:AddItem(script.Parent.Parent, 0.2)
	else
		script.Parent:Destroy()
	end
	burningEndFlag = true
elseif CommonUtil:IsPartIncludedCharacter(script.Parent) then
	local humanoid = CommonUtil:GetHumanoidByPart(script.Parent)
	local targetPlayer = CommonUtil:GetPlayerByPart(script.Parent)
	task.spawn(function()
		local ItemDbTools = require(ServerStorage.Items.Database.ItemDb).Tool
		local ItemInfo = ItemDbTools["FireBarrel"]
		TakeDotDamage(humanoid, ItemInfo.DotDamage, targetPlayer)
	end)
	task.wait(4)
	burningEndFlag = true
	fire:Destroy()
	smoke:Destroy()
	script:Destroy()
	return
end
