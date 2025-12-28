-- BarrelSystemService ModuleScript in ServerScriptService/Scripts/Service
local SingletonBase = require(game:GetService("ServerScriptService"):WaitForChild("Common"):WaitForChild("SingletonBase"))

local BarrelSystemService = setmetatable({}, { __index = SingletonBase })
BarrelSystemService.__index = BarrelSystemService

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local LoudSpeaker = require(game.ServerStorage.Scripts.LoudSpeaker)
local OilBarrel = require(script.Parent.OilBarrel)
local FireBarrel = require(script.Parent.FireBarrel)
local NormalBarrel = require(script.Parent.NormalBarrel)
local PoisonBarrel = require(script.Parent.PoisonBarrel)
local WindBarrel = require(script.Parent.WindBarrel)
local UserData = require(game.ServerStorage.Scripts.UserData)
local ItemDb = require(game.ServerStorage.Items.Database.ItemDb)

-- MatchController 지연 로딩 (순환 참조 방지)
local MatchController = nil
local function getMatchController()
	if not MatchController then
		MatchController = require(game:GetService("ServerScriptService"):WaitForChild("Controller"):WaitForChild("MatchController"))
	end
	return MatchController
end

-- 대기 상태인지 확인
local function isWaitingState()
	local success, result = pcall(function()
		local controller = getMatchController()
		return controller.gameState == "waiting" or controller.gameState == "starting"
	end)
	return success and result
end

-- ShopService 참조 (업그레이드 스탯 적용용)
local ShopService = nil
local function getShopService()
	if not ShopService then
		ShopService = require(game.ServerScriptService.Service.ShopService)
	end
	return ShopService
end

local throwingBarrelEvent = ReplicatedStorage:WaitForChild("ThrowingBarrelEvent")

-- RemoteEvent 및 RemoteFunction 설정
local BarrelStatusUpdateEvent = Instance.new("RemoteEvent")
BarrelStatusUpdateEvent.Name = "BarrelStatusUpdateEvent"
BarrelStatusUpdateEvent.Parent = ReplicatedStorage

local RequestInitialBarrelStatus = Instance.new("RemoteFunction")
RequestInitialBarrelStatus.Name = "RequestInitialBarrelStatus"
RequestInitialBarrelStatus.Parent = ReplicatedStorage

function BarrelSystemService:Initialize()
	-- 플레이어가 나갈 때 유저 데이터를 제거
	Players.PlayerRemoving:Connect(function(player)
		UserData.RemovePlayer(player)
	end)

	-- 배럴 발사 이벤트 처리
	throwingBarrelEvent.OnServerEvent:Connect(function(player, toolName, mouseHitPosition)
		self:HandleThrowingBarrel(player, toolName, mouseHitPosition)
	end)

	-- 초기 배럴 상태 요청 처리
	RequestInitialBarrelStatus.OnServerInvoke = function(player)
		local playerData = UserData.ReturnData(player)
		return playerData.ToolStatus
	end

	-- 배럴 업그레이드 요청 처리
	local requestUpgradeBarrel = ReplicatedStorage:WaitForChild("RequestUpgradeBarrel")
	requestUpgradeBarrel.OnServerInvoke = function(player)
		return self:HandleUpgradeBarrel(player)
	end

	-- 배럴 정보 요청 처리 (업그레이드 적용된 스탯 반환)
	local RequestToolInfo = ReplicatedStorage:WaitForChild("BarrelSystem"):WaitForChild("RequestToolInfo")
	RequestToolInfo.OnServerInvoke = function(player, toolName)
		local baseToolInfo = ItemDb.Tool[toolName]
		if not baseToolInfo then return nil end

		-- 업그레이드 적용된 스탯 가져오기
		local upgradedStats = getShopService():GetBarrelStats(player, toolName)
		if not upgradedStats then return baseToolInfo end

		-- 기본 정보에 업그레이드된 스탯 병합
		local result = {}
		for k, v in pairs(baseToolInfo) do
			result[k] = v
		end
		result.Damage = upgradedStats.Damage
		result.MaxRange = upgradedStats.MaxRange
		result.ReloadTime = upgradedStats.ReloadTime
		result.MaxShots = upgradedStats.MaxShots
		result.ExplosionRadius = upgradedStats.ExplosionRadius

		return result
	end
end

-- 배럴 상태를 클라이언트로 전송하는 함수
function BarrelSystemService:UpdateBarrelStatus(player, toolName, shotIndex, shotLeft, reloading, reloadTime)
	BarrelStatusUpdateEvent:FireClient(player, toolName, shotIndex, shotLeft, reloading, reloadTime)
end

-- 배럴을 재장전하는 함수
function BarrelSystemService:StartReload(player, toolName, _toolInfo, shotIndex)
	local playerData = UserData.ReturnData(player)
	local toolStatus = playerData.ToolStatus[toolName]

	if toolStatus.ShotLeft < toolStatus.MaxShots then
		toolStatus.Reloading[shotIndex] = true
		self:UpdateBarrelStatus(player, toolName, shotIndex, toolStatus.ShotLeft, true, toolStatus.ReloadTime)  -- 상태 변경 시 클라이언트에 전송
		task.delay(toolStatus.ReloadTime, function()
			toolStatus.ShotLeft = toolStatus.ShotLeft + 1
			toolStatus.Reloading[shotIndex] = false
			self:UpdateBarrelStatus(player, toolName, shotIndex, toolStatus.ShotLeft, false, toolStatus.ReloadTime)  -- 상태 변경 시 클라이언트에 전송
		end)
	end
end

-- 플레이어가 물속에 있는지 확인하는 함수 (수영 또는 잠수 상태)
function BarrelSystemService:IsPlayerInWater(character)
	if not character then
		return false
	end

	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid then
		return false
	end

	-- Humanoid 상태로 수영/잠수 체크 (가장 정확함)
	local state = humanoid:GetState()
	if state == Enum.HumanoidStateType.Swimming then
		return true
	end

	return false
end

-- 배럴 발사 처리 함수
function BarrelSystemService:HandleThrowingBarrel(player, toolName, mouseHitPosition)
	-- 1. 플레이어 캐릭터 존재 여부 검증
	local character = player.Character
	if not character or not character:FindFirstChild("HumanoidRootPart") then
		warn("[BarrelSystem] 플레이어 캐릭터가 없습니다: " .. player.Name)
		return
	end

	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		warn("[BarrelSystem] 플레이어가 사망 상태입니다: " .. player.Name)
		return
	end

	-- 물속에서는 통 던지기 불가
	if self:IsPlayerInWater(character) then
		return
	end

	-- 2. 툴 정보 검증
	local toolInfo = ItemDb.Tool[toolName]
	if not toolInfo then
		warn("[BarrelSystem] 유효하지 않은 툴: " .. tostring(toolName))
		return
	end

	-- 3. 유저 데이터 검증
	local userData = UserData.ReturnData(player)
	if not userData or not userData.ToolStatus or not userData.ToolStatus[toolName] then
		warn("[BarrelSystem] 유저 데이터가 없습니다: " .. player.Name)
		return
	end

	-- 3.5. 통 해금 여부 검증 (대기 상태에서는 모든 통 사용 가능)
	if not isWaitingState() then
		if not userData.UnlockedBarrels or not userData.UnlockedBarrels[toolName] then
			-- 기본 통(NormalBarrel)은 항상 사용 가능
			if toolName ~= "NormalBarrel" then
				warn("[BarrelSystem] 해금되지 않은 통입니다: " .. toolName .. " (" .. player.Name .. ")")
				return
			end
		end
	end

	-- 4. mouseHitPosition 유효성 검증
	if typeof(mouseHitPosition) ~= "Vector3" then
		warn("[BarrelSystem] 유효하지 않은 타겟 위치: " .. player.Name)
		return
	end

	-- 업그레이드 적용된 스탯 가져오기 (거리 검증 전에 필요)
	local upgradedStats = getShopService():GetBarrelStats(player, toolName)
	local effectiveToolInfo = {}
	for k, v in pairs(toolInfo) do
		effectiveToolInfo[k] = v
	end
	if upgradedStats then
		effectiveToolInfo.Damage = upgradedStats.Damage
		effectiveToolInfo.MaxRange = upgradedStats.MaxRange
		effectiveToolInfo.ReloadTime = upgradedStats.ReloadTime
		effectiveToolInfo.MaxShots = upgradedStats.MaxShots
	end

	-- 5. 타겟 거리 검증 (업그레이드된 MaxRange의 1.5배까지 허용 - 네트워크 지연 고려)
	local playerPosition = character.HumanoidRootPart.Position
	local targetDistance = (mouseHitPosition - playerPosition).Magnitude
	if targetDistance > effectiveToolInfo.MaxRange * 1.5 then
		warn("[BarrelSystem] 타겟이 너무 멀리 있습니다: " .. player.Name)
		return
	end

	-- 6. 발사 가능 슬롯 확인
	local toolStatus = userData.ToolStatus[toolName]
	local shotIndex = nil
	for i, reloading in toolStatus.Reloading do
		if not reloading then
			shotIndex = i
			break
		end
	end

	if not shotIndex then
		warn("[BarrelSystem] 사용 가능한 발사 슬롯이 없습니다: " .. player.Name)
		return
	end

	-- 검증 통과 후 발사 처리
	toolStatus.ShotLeft = toolStatus.ShotLeft - 1

	local barrel = nil
	if toolName == "OilBarrel" then
		barrel = OilBarrel.new(player, effectiveToolInfo, 1)
	elseif toolName == "FireBarrel" then
		barrel = FireBarrel.new(player, effectiveToolInfo, 1)
	elseif toolName == "PoisonBarrel" then
		barrel = PoisonBarrel.new(player, effectiveToolInfo, 1)
	elseif toolName == "WindBarrel" then
		barrel = WindBarrel.new(player, effectiveToolInfo, 1)
	else
		barrel = NormalBarrel.new(player, effectiveToolInfo, 1)
	end

	barrel:Throw(mouseHitPosition)

	-- 비동기적으로 재장전 시작
	self:StartReload(player, toolName, toolInfo, shotIndex)
end

-- 배럴 업그레이드 처리 함수
function BarrelSystemService:HandleUpgradeBarrel(player)
	local loudSpeaker = LoudSpeaker.new(player)
	local userData = UserData.ReturnData(player)
	if userData.BarrelLevel == 4 then
		loudSpeaker:DoTalk("최고 레벨입니다.")
		return false
	end

	if player.leaderstats.Coins.Value < 50 then
		loudSpeaker:DoTalk("업그레이드에 필요한 골드가 부족합니다.")
		return false
	end

	player.leaderstats.Coins.Value -= 50
	userData.BarrelLevel += 1
	return true
end

return BarrelSystemService:getInstance()
