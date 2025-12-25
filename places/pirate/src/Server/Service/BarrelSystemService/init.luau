-- BarrelSystemService ModuleScript in ServerScriptService/Scripts/Service
local SingletonBase = require(game:GetService("ServerScriptService"):WaitForChild("Common"):WaitForChild("SingletonBase"))

local BarrelSystemService = setmetatable({}, { __index = SingletonBase })
BarrelSystemService.__index = BarrelSystemService

local OIL_BARREL_GOLD = 10  -- 오일 배럴 발사에 필요한 골드

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local LoudSpeaker = require(game.ServerStorage.Scripts.LoudSpeaker)
local OilBarrel = require(script.OilBarrel)
local FireBarrel = require(script.FireBarrel)
local NormalBarrel = require(script.NormalBarrel)
local PoisonBarrel = require(script.PoisonBarrel)
local UserData = require(game.ServerStorage.Scripts.UserData)
local ItemDb = require(game.ServerStorage.Items.Database.ItemDb)

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

	-- 배럴 정보 요청 처리
	local RequestToolInfo = ReplicatedStorage:WaitForChild("BarrelSystem"):WaitForChild("RequestToolInfo")
	RequestToolInfo.OnServerInvoke = function(player, toolName)
		return ItemDb.Tool[toolName]
	end
end

-- 배럴 상태를 클라이언트로 전송하는 함수
function BarrelSystemService:UpdateBarrelStatus(player, toolName, shotIndex, shotLeft, reloading, reloadTime)
	BarrelStatusUpdateEvent:FireClient(player, toolName, shotIndex, shotLeft, reloading, reloadTime)
end

-- 배럴을 재장전하는 함수
function BarrelSystemService:StartReload(player, toolName, toolInfo, shotIndex)
	local playerData = UserData.ReturnData(player)
	local toolStatus = playerData.ToolStatus[toolName]

	if toolStatus.ShotLeft < toolStatus.MaxShots then
		toolStatus.Reloading[shotIndex] = true
		self:UpdateBarrelStatus(player, toolName, shotIndex, toolStatus.ShotLeft, true, toolStatus.ReloadTime)  -- 상태 변경 시 클라이언트에 전송
		delay(toolStatus.ReloadTime, function()
			toolStatus.ShotLeft = toolStatus.ShotLeft + 1
			toolStatus.Reloading[shotIndex] = false
			self:UpdateBarrelStatus(player, toolName, shotIndex, toolStatus.ShotLeft, false, toolStatus.ReloadTime)  -- 상태 변경 시 클라이언트에 전송
		end)
	end
end

-- 배럴 발사 처리 함수
function BarrelSystemService:HandleThrowingBarrel(player, toolName, mouseHitPosition)
	local userData = UserData.ReturnData(player)
	local toolInfo = ItemDb.Tool[toolName]

	if not toolInfo then
		warn("Invalid tool name: " .. toolName)
		return
	end

	local toolStatus = userData.ToolStatus[toolName]
	local shotIndex = nil
	for i, reloading in ipairs(toolStatus.Reloading) do
		if not reloading then
			shotIndex = i
			break
		end
	end

	if not shotIndex then
		warn("No available shots to fire.")
		return
	end

	toolStatus.ShotLeft = toolStatus.ShotLeft - 1

	local barrel = nil
	if toolName == "OilBarrel" then
		barrel = OilBarrel.new(player, 1, toolInfo)
		player.leaderstats.Coins.Value -= OIL_BARREL_GOLD
	elseif toolName == "FireBarrel" then
		barrel = FireBarrel.new(player, 1, toolInfo)
	elseif toolName == "PoisonBarrel" then
		barrel = PoisonBarrel.new(player, 1, toolInfo)
	else
		barrel = NormalBarrel.new(player, 1, toolInfo)
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
