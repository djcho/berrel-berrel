--[[
	CoinService: 로비 코인 관리 서비스

	기능:
	- DataStore를 통한 코인 영구 저장
	- 코인 획득/사용 API
	- 리더스탯 표시
]]

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local CoinService = {}
CoinService.__index = CoinService

local isStudio = RunService:IsStudio()
local DATASTORE_NAME = "PlayerCoinStore"
local DATA_KEY_PREFIX = "Coins_"
local DEFAULT_COINS = 1000 -- 신규 유저 기본 코인 (테스트용)

-- 싱글톤 인스턴스
local instance = nil

function CoinService.new()
	local self = setmetatable({}, CoinService)
	self.dataStore = nil
	self.playerCoins = {} -- UserId -> coins
	return self
end

function CoinService.getInstance()
	if not instance then
		instance = CoinService.new()
	end
	return instance
end

function CoinService:Initialize()
	-- DataStore 초기화
	if not isStudio then
		local success, result = pcall(function()
			return DataStoreService:GetDataStore(DATASTORE_NAME)
		end)
		if success then
			self.dataStore = result
			print("[CoinService] DataStore 연결 완료")
		else
			warn("[CoinService] DataStore 초기화 실패:", result)
		end
	else
		print("[CoinService] Studio 환경 - MockDataStore 사용")
	end

	-- RemoteFunction 생성
	self:SetupRemotes()

	-- 플레이어 이벤트 연결
	Players.PlayerAdded:Connect(function(player)
		self:OnPlayerJoined(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		self:OnPlayerLeft(player)
	end)

	-- 이미 접속한 플레이어 처리
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(function()
			self:OnPlayerJoined(player)
		end)
	end

	print("[CoinService] 초기화 완료")
end

function CoinService:SetupRemotes()
	local coinFolder = ReplicatedStorage:FindFirstChild("CoinSystem")
	if not coinFolder then
		coinFolder = Instance.new("Folder")
		coinFolder.Name = "CoinSystem"
		coinFolder.Parent = ReplicatedStorage
	end

	-- 코인 조회
	local getCoinsFunc = Instance.new("RemoteFunction")
	getCoinsFunc.Name = "GetCoins"
	getCoinsFunc.Parent = coinFolder
	getCoinsFunc.OnServerInvoke = function(player)
		return self:GetCoins(player)
	end

	-- 코인 업데이트 이벤트 (서버 -> 클라이언트)
	local coinUpdateEvent = Instance.new("RemoteEvent")
	coinUpdateEvent.Name = "CoinUpdated"
	coinUpdateEvent.Parent = coinFolder
end

function CoinService:OnPlayerJoined(player)
	local coins = self:LoadCoins(player)
	self.playerCoins[player.UserId] = coins

	-- 리더스탯 설정
	self:SetupLeaderstats(player, coins)

	print("[CoinService] 플레이어 코인 로드:", player.Name, coins)
end

function CoinService:OnPlayerLeft(player)
	local coins = self.playerCoins[player.UserId]
	if coins then
		self:SaveCoins(player, coins)
		self.playerCoins[player.UserId] = nil
		print("[CoinService] 플레이어 코인 저장:", player.Name, coins)
	end
end

function CoinService:SetupLeaderstats(player, coins)
	local folder = player:FindFirstChild("leaderstats")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "leaderstats"
		folder.Parent = player
	end

	local coinValue = folder:FindFirstChild("Coins")
	if not coinValue then
		coinValue = Instance.new("IntValue")
		coinValue.Name = "Coins"
		coinValue.Parent = folder
	end
	coinValue.Value = coins
end

function CoinService:LoadCoins(player)
	if isStudio or not self.dataStore then
		return DEFAULT_COINS
	end

	local success, result = pcall(function()
		return self.dataStore:GetAsync(DATA_KEY_PREFIX .. player.UserId)
	end)

	if success and result then
		return result
	end

	return DEFAULT_COINS
end

function CoinService:SaveCoins(player, coins)
	if isStudio or not self.dataStore then
		return true
	end

	local success, err = pcall(function()
		self.dataStore:SetAsync(DATA_KEY_PREFIX .. player.UserId, coins)
	end)

	if not success then
		warn("[CoinService] 코인 저장 실패:", err)
		return false
	end

	return true
end

-- 코인 조회
function CoinService:GetCoins(player)
	return self.playerCoins[player.UserId] or 0
end

-- 코인 추가
function CoinService:AddCoins(player, amount)
	local userId = player.UserId
	local current = self.playerCoins[userId] or 0
	local newAmount = current + amount

	self.playerCoins[userId] = newAmount
	self:UpdateLeaderstats(player, newAmount)
	self:NotifyCoinUpdate(player, newAmount)

	-- 비동기 저장
	task.spawn(function()
		self:SaveCoins(player, newAmount)
	end)

	return newAmount
end

-- 코인 사용 (차감)
function CoinService:SpendCoins(player, amount)
	local userId = player.UserId
	local current = self.playerCoins[userId] or 0

	if current < amount then
		return false, "코인이 부족합니다."
	end

	local newAmount = current - amount
	self.playerCoins[userId] = newAmount
	self:UpdateLeaderstats(player, newAmount)
	self:NotifyCoinUpdate(player, newAmount)

	-- 비동기 저장
	task.spawn(function()
		self:SaveCoins(player, newAmount)
	end)

	return true, newAmount
end

-- 코인 충분한지 확인
function CoinService:HasEnoughCoins(player, amount)
	local current = self.playerCoins[player.UserId] or 0
	return current >= amount
end

function CoinService:UpdateLeaderstats(player, coins)
	local folder = player:FindFirstChild("leaderstats")
	if folder then
		local coinValue = folder:FindFirstChild("Coins")
		if coinValue then
			coinValue.Value = coins
		end
	end
end

function CoinService:NotifyCoinUpdate(player, coins)
	local coinFolder = ReplicatedStorage:FindFirstChild("CoinSystem")
	if coinFolder then
		local updateEvent = coinFolder:FindFirstChild("CoinUpdated")
		if updateEvent then
			updateEvent:FireClient(player, coins)
		end
	end
end

-- UserId로 코인 추가 (플레이어가 로비에 없어도 DataStore에 직접 저장)
function CoinService:AddCoinsByUserId(userId, amount)
	if isStudio then
		print("[CoinService] Studio 환경 - 원격 코인 추가 시뮬레이션:", userId, amount)
		return true
	end

	if not self.dataStore then
		warn("[CoinService] DataStore 없음 - 코인 추가 실패")
		return false
	end

	-- 현재 로비에 접속 중인 플레이어인지 확인
	local player = Players:GetPlayerByUserId(userId)
	if player then
		-- 로비에 있으면 기존 방식으로 추가
		self:AddCoins(player, amount)
		print("[CoinService] 로비 플레이어 코인 추가:", player.Name, amount)
		return true
	end

	-- 로비에 없으면 DataStore에 직접 추가
	local success, err = pcall(function()
		self.dataStore:UpdateAsync(DATA_KEY_PREFIX .. userId, function(currentValue)
			local current = currentValue or DEFAULT_COINS
			return current + amount
		end)
	end)

	if success then
		print("[CoinService] DataStore 직접 코인 추가 완료:", userId, amount)
		return true
	else
		warn("[CoinService] DataStore 코인 추가 실패:", err)
		return false
	end
end

return CoinService
