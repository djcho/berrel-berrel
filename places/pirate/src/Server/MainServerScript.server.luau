-- ServiceLoader in ServerScriptService
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Controllers
local GameRoomInitializer = require(game.ServerScriptService.Controller.GameRoomInitializer)
local MatchController = require(game.ServerScriptService.Controller.MatchController)

-- Services
local InventoryService = require(game.ServerScriptService.Service.InventoryService)
local PlayerDataService = require(game.ServerScriptService.Service.PlayerDataService)
local CoinAreaService = require(game.ServerScriptService.Service.CoinAreaService)
local BarrelSystemService = require(game.ServerScriptService.Service.BarrelSystemService.BarrelSystemService)
local TeamService = require(game.ServerScriptService.Service.TeamService)

-- 서비스 초기화
TeamService:Initialize()
MatchController:Initialize()

-- 익사 데미지 RemoteEvent 생성 및 처리
local drowningEvent = Instance.new("RemoteEvent")
drowningEvent.Name = "DrowningDamageEvent"
drowningEvent.Parent = ReplicatedStorage

-- 익사 데미지 쿨다운 (남용 방지)
local drowningCooldowns = {}
local DROWN_COOLDOWN = 0.9  -- 초당 1회 정도만 허용

drowningEvent.OnServerEvent:Connect(function(player, damage)
	-- 쿨다운 체크
	local now = tick()
	if drowningCooldowns[player] and now - drowningCooldowns[player] < DROWN_COOLDOWN then
		return
	end
	drowningCooldowns[player] = now

	-- 데미지 검증 (최대 15까지만 허용)
	if type(damage) ~= "number" or damage <= 0 or damage > 15 then
		return
	end

	local character = player.Character
	if not character then return end

	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return end

	-- 익사 데미지 적용
	humanoid:TakeDamage(damage)
end)

-- 플레이어 나가면 쿨다운 정리
game.Players.PlayerRemoving:Connect(function(player)
	drowningCooldowns[player] = nil
end)

print("[MainServerScript] 모든 서비스 초기화 완료")
