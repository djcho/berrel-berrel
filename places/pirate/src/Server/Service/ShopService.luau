-- ShopService: 상점 구매 및 업그레이드 관리 서비스
local SingletonBase = require(game:GetService("ServerScriptService"):WaitForChild("Common"):WaitForChild("SingletonBase"))

local ShopService = setmetatable({}, { __index = SingletonBase })
ShopService.__index = ShopService

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local UserData = require(ServerStorage.Scripts.UserData)
local ItemDb = require(ServerStorage.Items.Database.ItemDb)

-- InventoryService 지연 로딩 (순환 참조 방지)
local InventoryService = nil
local function getInventoryService()
	if not InventoryService then
		InventoryService = require(game:GetService("ServerScriptService"):WaitForChild("Service"):WaitForChild("InventoryService"))
	end
	return InventoryService
end

-- 배럴 아이템 클래스 맵 (지연 로딩)
local BarrelItemClasses = nil
local function getBarrelItemClasses()
	if not BarrelItemClasses then
		local ItemStorage = ServerStorage:WaitForChild("Items")
		BarrelItemClasses = {
			NormalBarrel = require(ItemStorage.NormalBarrelItem),
			OilBarrel = require(ItemStorage.OilBarrelItem),
			FireBarrel = require(ItemStorage.FireBarrelItem),
			PoisonBarrel = require(ItemStorage.PoisonBarrelItem),
			WindBarrel = require(ItemStorage.WindBarrelItem),
		}
	end
	return BarrelItemClasses
end

-- 상점 아이템 설정 (통 해금 가격)
local BARREL_UNLOCK_PRICES = {
	NormalBarrel = 0,      -- 기본 해금
	OilBarrel = 100,
	FireBarrel = 200,
	PoisonBarrel = 250,
	WindBarrel = 150,
}

-- 업그레이드 설정 (레벨별 가격 및 효과)
local UPGRADE_CONFIG = {
	-- 데미지 업그레이드 (최대 5레벨)
	Damage = {
		maxLevel = 5,
		prices = { 50, 100, 150, 200, 300 },
		bonusPerLevel = 5,  -- 레벨당 데미지 +5
	},
	-- 사거리 업그레이드 (최대 5레벨)
	Range = {
		maxLevel = 5,
		prices = { 40, 80, 120, 160, 240 },
		bonusPerLevel = 20,  -- 레벨당 사거리 +20
	},
	-- 쿨타임 감소 업그레이드 (최대 3레벨)
	Cooldown = {
		maxLevel = 3,
		prices = { 100, 200, 300 },
		bonusPerLevel = 0.5,  -- 레벨당 재장전 시간 -0.5초
	},
	-- 보유 갯수 업그레이드 (최대 3레벨)
	MaxShots = {
		maxLevel = 3,
		prices = { 150, 300, 500 },
		bonusPerLevel = 1,  -- 레벨당 최대 보유 +1
	},
}

function ShopService:Initialize()
	-- 중복 초기화 방지
	if self._initialized then
		return
	end
	self._initialized = true

	-- RemoteFunction/Event 생성 (이미 있으면 재사용)
	local shopFolder = ReplicatedStorage:FindFirstChild("ShopSystem")
	if not shopFolder then
		shopFolder = Instance.new("Folder")
		shopFolder.Name = "ShopSystem"
		shopFolder.Parent = ReplicatedStorage
	end

	-- 통 해금 요청
	local unlockBarrelFunc = shopFolder:FindFirstChild("UnlockBarrel")
	if not unlockBarrelFunc then
		unlockBarrelFunc = Instance.new("RemoteFunction")
		unlockBarrelFunc.Name = "UnlockBarrel"
		unlockBarrelFunc.Parent = shopFolder
	end
	unlockBarrelFunc.OnServerInvoke = function(player, barrelName)
		return self:UnlockBarrel(player, barrelName)
	end

	-- 업그레이드 요청
	local upgradeBarrelFunc = shopFolder:FindFirstChild("UpgradeBarrel")
	if not upgradeBarrelFunc then
		upgradeBarrelFunc = Instance.new("RemoteFunction")
		upgradeBarrelFunc.Name = "UpgradeBarrel"
		upgradeBarrelFunc.Parent = shopFolder
	end
	upgradeBarrelFunc.OnServerInvoke = function(player, barrelName, upgradeType)
		return self:UpgradeBarrel(player, barrelName, upgradeType)
	end

	-- 상점 데이터 요청
	local getShopDataFunc = shopFolder:FindFirstChild("GetShopData")
	if not getShopDataFunc then
		getShopDataFunc = Instance.new("RemoteFunction")
		getShopDataFunc.Name = "GetShopData"
		getShopDataFunc.Parent = shopFolder
	end
	getShopDataFunc.OnServerInvoke = function(player)
		return self:GetShopData(player)
	end

	-- 플레이어 샵 데이터 요청 (골드 포함)
	local getPlayerShopDataFunc = shopFolder:FindFirstChild("GetPlayerShopData")
	if not getPlayerShopDataFunc then
		getPlayerShopDataFunc = Instance.new("RemoteFunction")
		getPlayerShopDataFunc.Name = "GetPlayerShopData"
		getPlayerShopDataFunc.Parent = shopFolder
	end
	getPlayerShopDataFunc.OnServerInvoke = function(player)
		return self:GetPlayerShopData(player)
	end

	print("[ShopService] 초기화 완료")
end

-- 플레이어의 상점 관련 데이터 초기화
function ShopService:InitializePlayerShopData(player)
	local playerData = UserData.ReturnData(player)
	if not playerData then return end

	-- 해금된 통 목록
	playerData.UnlockedBarrels = playerData.UnlockedBarrels or {
		NormalBarrel = true,  -- 기본 해금
	}

	-- 통별 업그레이드 레벨
	playerData.BarrelUpgrades = playerData.BarrelUpgrades or {}

	for barrelName, _ in pairs(BARREL_UNLOCK_PRICES) do
		if not playerData.BarrelUpgrades[barrelName] then
			playerData.BarrelUpgrades[barrelName] = {
				Damage = 0,
				Range = 0,
				Cooldown = 0,
				MaxShots = 0,
			}
		end
	end
end

-- 특정 통의 ToolStatus 초기화
function ShopService:InitializeBarrelToolStatus(player, barrelName)
	local playerData = UserData.ReturnData(player)
	if not playerData then return end

	playerData.ToolStatus = playerData.ToolStatus or {}

	local toolItemInfo = ItemDb.Tool[barrelName]
	if toolItemInfo and not playerData.ToolStatus[barrelName] then
		playerData.ToolStatus[barrelName] = {
			ToolName = barrelName,
			MaxShots = toolItemInfo.MaxShots,
			ShotLeft = toolItemInfo.MaxShots,
			Reloading = {},
			ReloadTime = toolItemInfo.ReloadTime
		}
		for _ = 1, toolItemInfo.MaxShots do
			table.insert(playerData.ToolStatus[barrelName].Reloading, false)
		end
	end
end

-- 통 해금
function ShopService:UnlockBarrel(player, barrelName)
	local playerData = UserData.ReturnData(player)
	if not playerData then
		return { success = false, message = "플레이어 데이터를 찾을 수 없습니다." }
	end

	-- 이미 해금된 통인지 확인
	if playerData.UnlockedBarrels and playerData.UnlockedBarrels[barrelName] then
		return { success = false, message = "이미 해금된 통입니다." }
	end

	-- 가격 확인
	local price = BARREL_UNLOCK_PRICES[barrelName]
	if not price then
		return { success = false, message = "존재하지 않는 통입니다." }
	end

	-- 골드 확인
	local leaderstats = player:FindFirstChild("leaderstats")
	local coins = leaderstats and leaderstats:FindFirstChild("Coins")
	if not coins or coins.Value < price then
		return { success = false, message = "골드가 부족합니다. (" .. price .. " 필요)" }
	end

	-- 구매 처리
	coins.Value = coins.Value - price
	playerData.UnlockedBarrels = playerData.UnlockedBarrels or {}
	playerData.UnlockedBarrels[barrelName] = true

	-- ToolStatus 먼저 초기화 (클라이언트가 상태 요청하기 전에)
	self:InitializeBarrelToolStatus(player, barrelName)

	-- 인벤토리에 통 추가 (클라이언트에 이벤트 발생)
	local barrelItemClass = getBarrelItemClasses()[barrelName]
	if barrelItemClass then
		getInventoryService():AddItem(player, barrelItemClass.new())
	end

	return { success = true, message = barrelName .. " 해금 완료!" }
end

-- 통 업그레이드
function ShopService:UpgradeBarrel(player, barrelName, upgradeType)
	local playerData = UserData.ReturnData(player)
	if not playerData then
		return { success = false, message = "플레이어 데이터를 찾을 수 없습니다." }
	end

	-- 해금 여부 확인
	if not playerData.UnlockedBarrels or not playerData.UnlockedBarrels[barrelName] then
		return { success = false, message = "먼저 통을 해금해야 합니다." }
	end

	-- 업그레이드 타입 확인
	local upgradeConfig = UPGRADE_CONFIG[upgradeType]
	if not upgradeConfig then
		return { success = false, message = "존재하지 않는 업그레이드 타입입니다." }
	end

	-- 현재 레벨 확인
	local currentLevel = playerData.BarrelUpgrades[barrelName][upgradeType] or 0
	if currentLevel >= upgradeConfig.maxLevel then
		return { success = false, message = "이미 최대 레벨입니다." }
	end

	-- 가격 확인
	local price = upgradeConfig.prices[currentLevel + 1]
	local leaderstats = player:FindFirstChild("leaderstats")
	local coins = leaderstats and leaderstats:FindFirstChild("Coins")
	if not coins or coins.Value < price then
		return { success = false, message = "골드가 부족합니다. (" .. price .. " 필요)" }
	end

	-- 업그레이드 처리
	coins.Value = coins.Value - price
	playerData.BarrelUpgrades[barrelName][upgradeType] = currentLevel + 1

	-- ToolStatus 업데이트 (실시간 적용)
	self:ApplyUpgradeToToolStatus(player, barrelName, upgradeType)

	return {
		success = true,
		message = upgradeType .. " 업그레이드 완료! (Lv." .. (currentLevel + 1) .. ")",
		newLevel = currentLevel + 1
	}
end

-- 업그레이드 효과를 ToolStatus에 적용
function ShopService:ApplyUpgradeToToolStatus(player, barrelName, upgradeType)
	local playerData = UserData.ReturnData(player)
	if not playerData or not playerData.ToolStatus then return end

	local toolStatus = playerData.ToolStatus[barrelName]
	if not toolStatus then return end

	local level = playerData.BarrelUpgrades[barrelName][upgradeType] or 0
	local config = UPGRADE_CONFIG[upgradeType]

	if upgradeType == "MaxShots" then
		local baseMaxShots = ItemDb.Tool[barrelName].MaxShots
		local newMaxShots = baseMaxShots + (level * config.bonusPerLevel)
		toolStatus.MaxShots = newMaxShots
		-- ShotLeft도 1 증가 (새 슬롯은 바로 사용 가능)
		toolStatus.ShotLeft = toolStatus.ShotLeft + 1
		-- Reloading 배열도 확장
		while #toolStatus.Reloading < newMaxShots do
			table.insert(toolStatus.Reloading, false)
		end
	elseif upgradeType == "Cooldown" then
		local baseReloadTime = ItemDb.Tool[barrelName].ReloadTime
		toolStatus.ReloadTime = math.max(0.5, baseReloadTime - (level * config.bonusPerLevel))
	end

	-- 클라이언트에 상태 업데이트 전송
	local BarrelStatusUpdateEvent = ReplicatedStorage:FindFirstChild("BarrelStatusUpdateEvent")
	if BarrelStatusUpdateEvent then
		BarrelStatusUpdateEvent:FireClient(player, barrelName, nil, toolStatus.ShotLeft, false, toolStatus.ReloadTime)
	end
end

-- 플레이어의 통에 적용된 실제 스탯 계산
function ShopService:GetBarrelStats(player, barrelName)
	local playerData = UserData.ReturnData(player)
	local baseStats = ItemDb.Tool[barrelName]

	if not baseStats then return nil end

	local upgrades = playerData and playerData.BarrelUpgrades and playerData.BarrelUpgrades[barrelName] or {}

	local damageBonus = (upgrades.Damage or 0) * UPGRADE_CONFIG.Damage.bonusPerLevel
	local rangeBonus = (upgrades.Range or 0) * UPGRADE_CONFIG.Range.bonusPerLevel
	local cooldownReduction = (upgrades.Cooldown or 0) * UPGRADE_CONFIG.Cooldown.bonusPerLevel
	local maxShotsBonus = (upgrades.MaxShots or 0) * UPGRADE_CONFIG.MaxShots.bonusPerLevel

	return {
		Damage = baseStats.Damage + damageBonus,
		MaxRange = baseStats.MaxRange + rangeBonus,
		ReloadTime = math.max(0.5, baseStats.ReloadTime - cooldownReduction),
		MaxShots = baseStats.MaxShots + maxShotsBonus,
		ExplosionRadius = baseStats.ExplosionRadius,
		DotDamage = baseStats.DotDamage,
	}
end

-- 상점 데이터 반환 (클라이언트 UI용)
function ShopService:GetShopData(player)
	local playerData = UserData.ReturnData(player)
	self:InitializePlayerShopData(player)

	local shopData = {
		barrels = {},
		upgradeConfig = UPGRADE_CONFIG,
	}

	for barrelName, unlockPrice in pairs(BARREL_UNLOCK_PRICES) do
		local baseStats = ItemDb.Tool[barrelName]
		local isUnlocked = playerData.UnlockedBarrels and playerData.UnlockedBarrels[barrelName] or false
		local upgrades = playerData.BarrelUpgrades and playerData.BarrelUpgrades[barrelName] or {}

		shopData.barrels[barrelName] = {
			displayName = baseStats.DisplayName,
			iconId = baseStats.IconId,
			unlockPrice = unlockPrice,
			isUnlocked = isUnlocked,
			baseStats = {
				Damage = baseStats.Damage,
				MaxRange = baseStats.MaxRange,
				ReloadTime = baseStats.ReloadTime,
				MaxShots = baseStats.MaxShots,
				ExplosionRadius = baseStats.ExplosionRadius,
			},
			upgrades = {
				Damage = upgrades.Damage or 0,
				Range = upgrades.Range or 0,
				Cooldown = upgrades.Cooldown or 0,
				MaxShots = upgrades.MaxShots or 0,
			},
			currentStats = self:GetBarrelStats(player, barrelName),
		}
	end

	return shopData
end

-- 플레이어 상점 데이터 (골드 포함)
function ShopService:GetPlayerShopData(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	local coins = leaderstats and leaderstats:FindFirstChild("Coins")

	return {
		gold = coins and coins.Value or 0,
		shopData = self:GetShopData(player),
	}
end

-- 통이 해금되어 있는지 확인
function ShopService:IsBarrelUnlocked(player, barrelName)
	local playerData = UserData.ReturnData(player)
	if not playerData or not playerData.UnlockedBarrels then
		return barrelName == "NormalBarrel"  -- 기본 통은 항상 해금
	end
	return playerData.UnlockedBarrels[barrelName] == true
end

return ShopService:getInstance()
