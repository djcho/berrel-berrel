-- InventoryService ModuleScript in ServerScriptService/Scripts/Service
local SingletonBase = require(game:GetService("ServerScriptService"):WaitForChild("Common"):WaitForChild("SingletonBase"))

local InventoryService = setmetatable({}, { __index = SingletonBase })
InventoryService.__index = InventoryService

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ToolBarAddItemEvent = Instance.new("RemoteEvent")
ToolBarAddItemEvent.Name = "ToolBarAddItemEvent"
ToolBarAddItemEvent.Parent = ReplicatedStorage

local SyncInventoryEvent = Instance.new("RemoteEvent")
SyncInventoryEvent.Name = "SyncInventoryEvent"
SyncInventoryEvent.Parent = ReplicatedStorage

function InventoryService:Initialize()
	self.PlayerInventories = {}
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
			-- 백팩에 아이템 추가
			local toolItem = item.Model:Clone()
			toolItem.TextureId = item.IconId
			toolItem.Parent = player:WaitForChild("Backpack")

			-- 클라이언트에 아이템 추가 알림
			ToolBarAddItemEvent:FireClient(player, item)
		end

		-- 전체 인벤토리 동기화 이벤트 호출
		self:SyncInventory(player)
		return
	end

	local inventoryItem = self:GetInventoryItem(player, item.Id)
	if not inventoryItem then
		error("Failed to AddItem, Item id is not valid")
	end

	inventoryItem:Merge(item)
	if item then
		table.insert(inventory, item)
	end

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
