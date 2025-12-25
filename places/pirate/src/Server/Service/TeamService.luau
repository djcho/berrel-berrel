-- TeamService ModuleScript in ServerScriptService/Scripts/Service
local SingletonBase = require(game:GetService("ServerScriptService"):WaitForChild("Common"):WaitForChild("SingletonBase"))

local TeamService = setmetatable({}, { __index = SingletonBase })
TeamService.__index = TeamService

local Teams = game:GetService("Teams")
local Players = game:GetService("Players")

function TeamService:Initialize()
	Players.PlayerAdded:Connect(function(player)
		self:AssignTeam(player)
		player.CharacterAdded:Connect(function(character)
			self:OnCharacterAdded(player, character)
		end)
	end)
end

-- 팀을 자동으로 할당하는 함수
function TeamService:AssignTeam(player)
	if #Teams["TeamA"]:GetPlayers() <= #Teams["TeamB"]:GetPlayers() then
		player.Team = Teams["TeamA"]
	else
		player.Team = Teams["TeamB"]
	end
	print(player.Name .. " has been assigned to " .. player.Team.Name)
end

-- 캐릭터가 추가되었을 때 호출되는 함수
function TeamService:OnCharacterAdded(player, character)
	local spawnLocation
	if player.Team == Teams["TeamA"] then
		spawnLocation = workspace:WaitForChild("SpawnLocationTeamA")
		print("Spawn location for TeamA found")
	elseif player.Team == Teams["TeamB"] then
		spawnLocation = workspace:WaitForChild("SpawnLocationTeamB")
		print("Spawn location for TeamB found")
	end
	if spawnLocation then
		character:SetPrimaryPartCFrame(spawnLocation.CFrame)
		print(player.Name .. " spawned at " .. spawnLocation.Name)
	else
		print("Spawn location not found for " .. player.Team.Name)
	end
end

return TeamService
