-- UserService ModuleScript in ServerScriptService/Scripts/Service
local SingletonBase = require(game:GetService("ServerScriptService"):WaitForChild("Common"):WaitForChild("SingletonBase"))

local PlayerDataService = setmetatable({}, { __index = SingletonBase })
PlayerDataService.__index = PlayerDataService

local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")
local ItemStorage = ServerStorage:FindFirstChild("Items")

-- InventoryService로 변경된 부분을 반영
local InventoryService = require(game:GetService("ServerScriptService"):WaitForChild("Service"):WaitForChild("InventoryService"))
local FireBarrelItem = require(ItemStorage.FireBarrelItem)
local OilBarrelItem = require(ItemStorage.OilBarrelItem)
local NormalBarrelItem = require(ItemStorage.NormalBarrelItem)
local PoisonBarrelItem = require(ItemStorage.PoisonBarrelItem)
local WindBarrelItem = require(ItemStorage.WindBarrelItem)
local ItemDb = require(ItemStorage.Database.ItemDb)
local UserData = require(ServerStorage.Scripts.UserData)

-- ShopService 지연 로딩 (순환 참조 방지)
local ShopService = nil
local function getShopService()
	if not ShopService then
		ShopService = require(game:GetService("ServerScriptService"):WaitForChild("Service"):WaitForChild("ShopService"))
	end
	return ShopService
end

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

function PlayerDataService:Initialize()
	Players.PlayerAdded:Connect(function(player)
		self:OnPlayerJoined(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		self:OnPlayerLeft(player)
	end)
end

-- 리더스탯 초기화
function PlayerDataService:SetupLeaderstats(player)
	local folder = Instance.new("Folder", player)
	folder.Name = "leaderstats"

	local intValue = Instance.new("IntValue", folder)
	intValue.Name = "Kill"
	intValue.Value = 0

	intValue = Instance.new("IntValue", folder)
	intValue.Name = "Death"
	intValue.Value = 0

	intValue = Instance.new("IntValue", folder)
	intValue.Name = "Coins"
	intValue.Value = 0
end

-- 최대 업그레이드 설정 (대기실용)
local MAX_UPGRADE_CONFIG = {
	MaxShots = 99,       -- 대기실: 무한 (99개)
	ReloadReduction = 1.5,  -- 재장전 시간 -1.5초
}

-- 업그레이드 설정 (ShopService와 동일)
local UPGRADE_CONFIG = {
	Cooldown = { bonusPerLevel = 0.5 },
	MaxShots = { bonusPerLevel = 1 },
}

-- 배럴 상태 초기화 함수
function PlayerDataService:InitializeBarrelStatus(player, isWaiting)
	local playerData = UserData.ReturnData(player)
	-- ToolStatus 완전 초기화 (대기실 → 게임 시작 전환 시 필요)
	playerData.ToolStatus = {}

	local inventory = InventoryService:GetOrCreateInventory(player)

	for _, item in pairs(inventory) do
		local toolName = item.Name
		local toolItemInfo = ItemDb.Tool[toolName]
		if toolItemInfo then
			local maxShots = toolItemInfo.MaxShots
			local reloadTime = toolItemInfo.ReloadTime

			-- 대기 상태면 최고 능력치 적용
			if isWaiting then
				maxShots = maxShots + MAX_UPGRADE_CONFIG.MaxShots
				reloadTime = math.max(0.5, reloadTime - MAX_UPGRADE_CONFIG.ReloadReduction)
			else
				-- 게임 중에는 업그레이드 적용
				local upgrades = playerData.BarrelUpgrades and playerData.BarrelUpgrades[toolName]
				if upgrades then
					maxShots = maxShots + (upgrades.MaxShots or 0) * UPGRADE_CONFIG.MaxShots.bonusPerLevel
					reloadTime = math.max(0.5, reloadTime - (upgrades.Cooldown or 0) * UPGRADE_CONFIG.Cooldown.bonusPerLevel)
				end
			end

			playerData.ToolStatus[toolName] = {
				ToolName = toolName,
				MaxShots = maxShots,
				ShotLeft = maxShots,
				Reloading = {},
				ReloadTime = reloadTime
			}
			for _ = 1, maxShots do
				table.insert(playerData.ToolStatus[toolName].Reloading, false)
			end
		end
	end
end

-- 캐릭터가 생성되었을 때 호출
function PlayerDataService:OnCharacterAdded(character)
	local player = game.Players:GetPlayerFromCharacter(character)

	-- Player 객체에 'HasDiedOnce' 라는 BoolValue를 추가하고 초기화
	if not player:FindFirstChild("HasDiedOnce") then
		local hasDiedOnce = Instance.new("BoolValue")
		hasDiedOnce.Name = "HasDiedOnce"
		hasDiedOnce.Value = false
		hasDiedOnce.Parent = player
	end

	local humanoid = character:WaitForChild("Humanoid")
	humanoid.NameOcclusion = Enum.NameOcclusion.NoOcclusion
	humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOn

	-- burnable 값은 항상 설정
	local existingBurnable = humanoid:FindFirstChild("burnable")
	if not existingBurnable then
		local boolValue = Instance.new("BoolValue", humanoid)
		boolValue.Name = "burnable"
		boolValue.Value = true
	end

	-- 만약 HasDiedOnce가 true라면 인벤토리 재구성 생략 (이미 있음)
	if player.HasDiedOnce.Value == true then
		return
	end

	InventoryService:ClearInventory(player)

	-- 대기 상태면 모든 통 해금, 아니면 해금된 통만
	local playerData = UserData.ReturnData(player)
	local unlockedBarrels

	if isWaitingState() then
		-- 대기 상태: 모든 통 사용 가능
		unlockedBarrels = {
			NormalBarrel = true,
			OilBarrel = true,
			FireBarrel = true,
			PoisonBarrel = true,
			WindBarrel = true,
		}
	else
		-- 게임 진행 중: 해금된 통만
		unlockedBarrels = playerData.UnlockedBarrels or { NormalBarrel = true }
	end

	if unlockedBarrels["NormalBarrel"] then
		InventoryService:AddItem(player, NormalBarrelItem.new())
	end
	if unlockedBarrels["OilBarrel"] then
		InventoryService:AddItem(player, OilBarrelItem.new())
	end
	if unlockedBarrels["FireBarrel"] then
		InventoryService:AddItem(player, FireBarrelItem.new())
	end
	if unlockedBarrels["PoisonBarrel"] then
		InventoryService:AddItem(player, PoisonBarrelItem.new())
	end
	if unlockedBarrels["WindBarrel"] then
		InventoryService:AddItem(player, WindBarrelItem.new())
	end

	-- 배럴 상태 초기화 (대기 상태면 최고 능력치로)
	self:InitializeBarrelStatus(player, isWaitingState())
end


-- 플레이어가 게임에 들어왔을 때 호출
function PlayerDataService:OnPlayerJoined(player)
	self:SetupLeaderstats(player)
	UserData.AddPlayer(player, {
		ToolStatus = {},
		BarrelLevel = 1,
		UnlockedBarrels = { NormalBarrel = true },  -- 기본 통 해금
		BarrelUpgrades = {},
	})

	-- ShopService 데이터 초기화
	task.defer(function()
		getShopService():InitializePlayerShopData(player)
	end)

	player.CharacterAdded:Connect(function(character)
		self:OnCharacterAdded(character)
	end)

	-- 캐릭터가 이미 생성된 경우 처리
	if player.Character then
		self:OnCharacterAdded(player.Character)
	end
end

-- 플레이어가 나갔을 때 호출
function PlayerDataService:OnPlayerLeft(player)
	UserData.RemovePlayer(player)
end

-- 싱글톤 인스턴스를 반환
return PlayerDataService:getInstance()
