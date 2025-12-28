-- InventoryService ModuleScript in ServerScriptService/Scripts/Service
local SingletonBase = require(game:GetService("ServerScriptService"):WaitForChild("Common"):WaitForChild("SingletonBase"))

local InventoryService = setmetatable({}, { __index = SingletonBase })
InventoryService.__index = InventoryService

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local ToolBarAddItemEvent = Instance.new("RemoteEvent")
ToolBarAddItemEvent.Name = "ToolBarAddItemEvent"
ToolBarAddItemEvent.Parent = ReplicatedStorage

local SyncInventoryEvent = Instance.new("RemoteEvent")
SyncInventoryEvent.Name = "SyncInventoryEvent"
SyncInventoryEvent.Parent = ReplicatedStorage

function InventoryService:Initialize()
	self.PlayerInventories = {}
end

-- Tool 객체를 동적으로 생성하는 함수
function InventoryService:CreateToolInstance(itemInfo)
	local tool = Instance.new("Tool")
	tool.Name = itemInfo.Name
	tool.CanBeDropped = false
	tool.RequiresHandle = true

	-- Handle 생성 (ServerStorage/Parts에서 파츠 가져오기)
	local partName = itemInfo.PartName or itemInfo.Name
	local partTemplate = ServerStorage.Parts:FindFirstChild(partName)

	-- Fallback 파트 사용
	if not partTemplate and itemInfo.FallbackPartName then
		partTemplate = ServerStorage.Parts:FindFirstChild(itemInfo.FallbackPartName)
	end

	local handle
	if partTemplate then
		handle = partTemplate:Clone()
	else
		-- 파츠가 없으면 기본 파트 생성
		handle = Instance.new("Part")
		handle.Size = Vector3.new(1, 1, 2)
		handle.Color = Color3.fromRGB(139, 90, 43)
	end

	handle.Name = "Handle"
	handle.Parent = tool

	-- FireProjectile 클라이언트 스크립트 추가 (마우스 입력 및 발사 처리)
	local fireProjectileTemplate = ServerStorage.Scripts:FindFirstChild("FireProjectile")
	if fireProjectileTemplate then
		local fireProjectile = fireProjectileTemplate:Clone()
		fireProjectile.Parent = tool
	else
		warn("[InventoryService] FireProjectile script not found in ServerStorage/Scripts")
	end

	return tool
end

-- 플레이어의 인벤토리를 초기화하거나 가져오는 함수
function InventoryService:GetOrCreateInventory(player)
	if not self.PlayerInventories[player.UserId] then
		self.PlayerInventories[player.UserId] = {}
	end
	return self.PlayerInventories[player.UserId]
end

function InventoryService:IsExist(player, itemId)
	local inventory = self:GetOrCreateInventory(player)
	for _, v in pairs(inventory) do
		if v.Id == itemId then
			return true
		end
	end
	return false
end

function InventoryService:GetInventoryItem(player, itemId)
	local inventory = self:GetOrCreateInventory(player)
	for _, v in pairs(inventory) do
		if v.Id == itemId then
			return v
		end
	end
end

function InventoryService:AddItem(player, item)
	local inventory = self:GetOrCreateInventory(player)
	if not self:IsExist(player, item.Id) then
		table.insert(inventory, item)

		if item.Category == "Tool" then
			-- Tool 객체 동적 생성
			local toolItem = self:CreateToolInstance(item)
			toolItem.TextureId = item.IconId
			toolItem.Parent = player:WaitForChild("Backpack")

			-- 클라이언트에 아이템 추가 알림
			ToolBarAddItemEvent:FireClient(player, item)
		end

		-- 전체 인벤토리 동기화 이벤트 호출
		self:SyncInventory(player)
		return
	end

	-- 이미 존재하는 아이템은 Merge만 수행 (중복 추가 방지)
	local inventoryItem = self:GetInventoryItem(player, item.Id)
	if not inventoryItem then
		error("Failed to AddItem, Item id is not valid")
	end

	inventoryItem:Merge(item)
	-- 기존 아이템에 Merge했으므로 새로 추가하지 않음

	-- 전체 인벤토리 동기화 이벤트 호출
	self:SyncInventory(player)
end

-- 모든 아이템을 삭제하는 함수 추가
function InventoryService:ClearInventory(player)
	local inventory = self:GetOrCreateInventory(player)
	-- 백팩에서 모든 도구를 제거
	local backpack = player:FindFirstChild("Backpack")
	if backpack then
		for _, tool in pairs(backpack:GetChildren()) do
			if tool:IsA("Tool") then
				tool:Destroy()
			end
		end
	end

	-- 인벤토리 초기화
	self.PlayerInventories[player.UserId] = {}

	-- 전체 인벤토리 동기화 이벤트 호출
	self:SyncInventory(player)
end

function InventoryService:GetItems(player)
	return self:GetOrCreateInventory(player)
end

function InventoryService:SyncInventory(player)
	SyncInventoryEvent:FireClient(player, self:GetItems(player))
end

function InventoryService:OnPlayerLeft(player)
	self.PlayerInventories[player.UserId] = nil
end

return InventoryService:getInstance()
