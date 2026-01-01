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

-- 기름 모델의 밀도 가져오기 (토네이도에 빨리면 감소)
local function getFireDensity()
	local oilModel = script.Parent and script.Parent.Parent
	if oilModel and oilModel:IsA("Model") and oilModel.Name:match("Oil") then
		return (oilModel:GetAttribute("FireDensity") or 100) / 100
	end
	return 1
end

-- 바람 부스트 확인 함수
local function getSpreadRadius()
	if script:GetAttribute("WindBoosted") then
		return WIND_BOOST_RADIUS
	end
	return BASE_SPREAD_RADIUS
end

-- 불 확산 대상에 스크립트를 추가하는 헬퍼 함수 (오브젝트용)
local function attachFireToObject(targetPart)
	local newScript = script:Clone()
	newScript.Parent = targetPart
	newScript.Disabled = false

	-- 사라지는 시간을 초기화하는 처리 추가
	local modelDestroyer = targetPart.Parent:FindFirstChild("ModelDestroyer")
	if modelDestroyer and modelDestroyer.Configuration and modelDestroyer.Configuration.WaitTime then
		modelDestroyer.Configuration.WaitTime.Value = 10 -- 사라지는 시간을 10초로 초기화
	end
end

-- 캐릭터에 불 스크립트 복제
local function attachFireToCharacter(character, targetPart)
	-- 이미 불이 붙어있으면 스킵
	if character:FindFirstChild("FireSpread", true) then
		return
	end

	local newScript = script:Clone()
	newScript.Parent = targetPart
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
				local character = SpreadPart.Parent
				-- 캐릭터에 불 스크립트 복제 (이미 있으면 스킵됨)
				attachFireToCharacter(character, SpreadPart)
			elseif SpreadPart:FindFirstChild("burnable") then
				if not SpreadPart:FindFirstChild("FireSpread") then
					attachFireToObject(SpreadPart)
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

-- 캐릭터에 붙은 불인 경우: 3초 후 자동 소멸
if CommonUtil:IsPartIncludedCharacter(script.Parent) then
	task.spawn(Burning)

	task.wait(3)  -- 캐릭터 불은 3초간 지속
	burningEndFlag = true
	fire:Destroy()
	smoke:Destroy()
	script:Destroy()
	return
end

task.spawn(Burning)

if script.Parent.Parent.Name:match("Oil") then
	local oilModel = script.Parent.Parent

	-- 사라지는 시간을 초기화하는 처리 추가
	local modelDestroyer = oilModel:FindFirstChild("ModelDestroyer")
	if modelDestroyer and modelDestroyer.Configuration and modelDestroyer.Configuration.WaitTime then
		modelDestroyer.Configuration.WaitTime.Value = 10 -- 사라지는 시간을 10초로 초기화
	end

	-- 이 파츠가 데미지 담당인지 확인 (기름 모델당 하나만)
	local isDamageDealer = false
	if not oilModel:GetAttribute("FireDamageActive") then
		oilModel:SetAttribute("FireDamageActive", true)
		isDamageDealer = true
	end

	-- 데미지 담당 파츠만 범위 내 캐릭터에게 DoT 데미지
	if isDamageDealer then
		task.spawn(function()
			local ItemDbTools = require(ServerStorage.Items.Database.ItemDb).Tool
			local ItemInfo = ItemDbTools["FireBarrel"]
			local tickDamage = ItemInfo.DotDamage or 5

			while not burningEndFlag do
				local processedCharacters = {}
				local spreadRadius = getSpreadRadius()

				-- 기름 모델의 모든 파츠에서 범위 체크
				for _, oilPart in oilModel:GetChildren() do
					if oilPart:IsA("BasePart") then
						local overlapParams = OverlapParams.new()
						overlapParams.FilterType = Enum.RaycastFilterType.Exclude
						overlapParams.FilterDescendantsInstances = {oilModel}

						local partsInRadius = workspace:GetPartBoundsInRadius(oilPart.Position, spreadRadius, overlapParams)

						for _, part in partsInRadius do
							if CommonUtil:IsPartIncludedCharacter(part) then
								local character = part.Parent
								if not processedCharacters[character] then
									processedCharacters[character] = true
									local humanoid = character:FindFirstChild("Humanoid")
									local targetPlayer = Players:GetPlayerFromCharacter(character)

									if humanoid and humanoid.Health > 0 then
										-- 같은 팀이면 스킵 (자기 자신은 데미지 받음)
										local isSelf = targetPlayer == fireStarter
										local isSameTeam = isSameTeamAsFireStarter(targetPlayer)
										if isSelf or not isSameTeam then
											-- 밀도에 비례한 데미지
											local density = getFireDensity()
											local actualDamage = math.floor(tickDamage * density)
											if actualDamage > 0 then
												if not isSelf then
													setCreatorTag(humanoid, targetPlayer)
												end
												humanoid:TakeDamage(actualDamage)
											end
										end
									end
								end
							end
						end
					end
				end

				task.wait(1)  -- 1초마다 데미지
			end
		end)
	end

	task.wait(10)
	burningEndFlag = true
	fire:Destroy()
	smoke:Destroy()

	script.Parent.Material = Enum.Material.CorrodedMetal
	script.Parent:BreakJoints()

	local Debris = game:GetService("Debris")

	local oilPartCount = 0
	for _, v in pairs(oilModel:GetChildren()) do
		if v.Name == "OilPart" then
			oilPartCount += 1
		end
	end

	if oilPartCount == 1 then
		Debris:AddItem(oilModel, 0.2)
	else
		script.Parent:Destroy()
	end
end
