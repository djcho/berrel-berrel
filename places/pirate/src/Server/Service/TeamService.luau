-- TeamService ModuleScript in ServerScriptService/Scripts/Service
local SingletonBase = require(game:GetService("ServerScriptService"):WaitForChild("Common"):WaitForChild("SingletonBase"))

local TeamService = setmetatable({}, { __index = SingletonBase })
TeamService.__index = TeamService

local TeamsService = game:GetService("Teams")
local Players = game:GetService("Players")

-- 팀 객체 캐싱
local teamA = nil
local teamB = nil

-- 팀을 생성하거나 가져오는 함수
local function createOrGetTeam(name, teamColor)
	local team = TeamsService:FindFirstChild(name)
	if not team then
		team = Instance.new("Team")
		team.Name = name
		team.TeamColor = teamColor
		team.AutoAssignable = false
		team.Parent = TeamsService
		print("[TeamService] 팀 생성: " .. name)
	end
	return team
end

-- 팀 객체를 안전하게 가져오는 함수
local function getTeams()
	if not teamA then
		teamA = TeamsService:FindFirstChild("TeamA")
	end
	if not teamB then
		teamB = TeamsService:FindFirstChild("TeamB")
	end
	return teamA, teamB
end

function TeamService:Initialize()
	-- 팀 생성 (없으면 생성)
	teamA = createOrGetTeam("TeamA", BrickColor.new("Bright red"))
	teamB = createOrGetTeam("TeamB", BrickColor.new("Bright blue"))

	Players.PlayerAdded:Connect(function(player)
		self:AssignTeam(player)
		player.CharacterAdded:Connect(function(character)
			self:OnCharacterAdded(player, character)
		end)
	end)

	-- 이미 접속해 있는 플레이어들 처리
	for _, player in ipairs(Players:GetPlayers()) do
		if not player.Team then
			self:AssignTeam(player)
		end
	end

	print("[TeamService] 초기화 완료")
end

-- 팀을 자동으로 할당하는 함수 (균형 잡힌 배정)
function TeamService:AssignTeam(player)
	local tA, tB = getTeams()

	if not tA or not tB then
		warn("[TeamService] 팀을 찾을 수 없습니다!")
		return
	end

	local teamACount = #tA:GetPlayers()
	local teamBCount = #tB:GetPlayers()

	-- 동일 인원일 때 랜덤 배정 (균형 유지)
	if teamACount == teamBCount then
		if math.random(1, 2) == 1 then
			player.Team = tA
		else
			player.Team = tB
		end
	elseif teamACount < teamBCount then
		player.Team = tA
	else
		player.Team = tB
	end

	print("[TeamService] " .. player.Name .. " -> " .. player.Team.Name .. " (A:" .. #tA:GetPlayers() .. " B:" .. #tB:GetPlayers() .. ")")
end

-- 특정 팀으로 강제 배정
function TeamService:ForceAssignTeam(player, teamName)
	local tA, tB = getTeams()

	if teamName == "TeamA" and tA then
		player.Team = tA
	elseif teamName == "TeamB" and tB then
		player.Team = tB
	else
		warn("[TeamService] 유효하지 않은 팀: " .. tostring(teamName))
		return false
	end

	print("[TeamService] " .. player.Name .. " 강제 배정 -> " .. player.Team.Name)
	return true
end

-- 팀 인원 수 가져오기
function TeamService:GetTeamCounts()
	local tA, tB = getTeams()
	return {
		TeamA = tA and #tA:GetPlayers() or 0,
		TeamB = tB and #tB:GetPlayers() or 0
	}
end

-- 두 플레이어가 같은 팀인지 확인
function TeamService:IsSameTeam(player1, player2)
	if not player1 or not player2 then
		return false
	end
	return player1.Team and player2.Team and player1.Team == player2.Team
end

-- 플레이어와 캐릭터가 같은 팀인지 확인 (캐릭터로부터 플레이어를 찾아서 비교)
function TeamService:IsSameTeamByCharacter(player, character)
	if not player or not character then
		return false
	end
	local targetPlayer = Players:GetPlayerFromCharacter(character)
	if not targetPlayer then
		return false
	end
	return self:IsSameTeam(player, targetPlayer)
end

-- 캐릭터가 추가되었을 때 호출되는 함수
function TeamService:OnCharacterAdded(player, character)
	local tA, tB = getTeams()
	local spawnLocation = nil

	if player.Team == tA then
		spawnLocation = workspace:FindFirstChild("SpawnLocationTeamA")
	elseif player.Team == tB then
		spawnLocation = workspace:FindFirstChild("SpawnLocationTeamB")
	end

	if spawnLocation and character.PrimaryPart then
		-- PivotTo 사용 (SetPrimaryPartCFrame은 deprecated)
		character:PivotTo(spawnLocation.CFrame + Vector3.new(0, 3, 0))
		print("[TeamService] " .. player.Name .. " 스폰 위치: " .. spawnLocation.Name)
	elseif not spawnLocation then
		warn("[TeamService] 스폰 위치를 찾을 수 없음: " .. (player.Team and player.Team.Name or "팀 없음"))
	end
end

return TeamService
