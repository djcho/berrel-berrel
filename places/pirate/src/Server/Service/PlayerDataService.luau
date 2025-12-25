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
local ItemDb = require(ItemStorage.Database.ItemDb)
local UserData = require(ServerStorage.Scripts.UserData)

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

	-- 만약 HasDiedOnce가 true라면 더 이상 죽이지 않음
	if player.HasDiedOnce.Value == true then
		return
	end

	local humanoid = character:WaitForChild("Humanoid")
	humanoid.NameOcclusion = Enum.NameOcclusion.NoOcclusion
	humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOn

	local boolValue = Instance.new("BoolValue", humanoid)
	boolValue.Name = "burnable"
	boolValue.Value = true

	InventoryService:ClearInventory(player)
	InventoryService:AddItem(player, NormalBarrelItem.new())    
	InventoryService:AddItem(player, OilBarrelItem.new())
	InventoryService:AddItem(player, FireBarrelItem.new())
	InventoryService:AddItem(player, PoisonBarrelItem.new())   

	-- 배럴 상태 초기화
	self:InitializeBarrelStatus(player)
end


-- 플레이어가 게임에 들어왔을 때 호출
function PlayerDataService:OnPlayerJoined(player)
	self:SetupLeaderstats(player)
	UserData.AddPlayer(player, {
		ToolStatus = {},
		BarrelLevel = 1
	})

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
