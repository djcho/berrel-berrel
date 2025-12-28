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

-- 배럴 상태 초기화 함수
function PlayerDataService:InitializeBarrelStatus(player)
	local playerData = UserData.ReturnData(player)
	playerData.ToolStatus = playerData.ToolStatus or {}

	local inventory = InventoryService:GetOrCreateInventory(player)

	for _, item in pairs(inventory) do
		local toolName = item.Name
		local toolItemInfo = ItemDb.Tool[toolName]
		if toolItemInfo and not playerData.ToolStatus[toolName] then
			playerData.ToolStatus[toolName] = {
				ToolName = toolName,
				MaxShots = toolItemInfo.MaxShots,
				ShotLeft = toolItemInfo.MaxShots,
				Reloading = {},
				ReloadTime = toolItemInfo.ReloadTime
			}
			for i = 1, toolItemInfo.MaxShots do
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

	-- 해금된 배럴만 인벤토리에 추가
	local playerData = UserData.ReturnData(player)
	local unlockedBarrels = playerData.UnlockedBarrels or { NormalBarrel = true }

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

	-- 배럴 상태 초기화
	self:InitializeBarrelStatus(player)
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
