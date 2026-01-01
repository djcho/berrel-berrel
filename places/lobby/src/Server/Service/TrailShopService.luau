--[[
	TrailShopService: Trail 구매 및 장착 관리 서비스 (로비용)

	기능:
	- DataStore를 통한 Trail 데이터 영구 저장
	- MarketplaceService를 통한 Developer Product 구매 처리
	- 배럴별 Trail 장착 관리
	- 텔레포트 시 Trail 데이터 전달
]]

local DataStoreService = game:GetService("DataStoreService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local TrailDb = require(script.Parent.Parent.Database.TrailDb)

-- CoinService 지연 로딩
local CoinService = nil
local function getCoinService()
	if not CoinService then
		local success, result = pcall(function()
			return require(script.Parent.CoinService).getInstance()
		end)
		if success then
			CoinService = result
		end
	end
	return CoinService
end

local TrailShopService = {}
TrailShopService.__index = TrailShopService

local isStudio = RunService:IsStudio()
local DATASTORE_NAME = "TrailDataStore"
local DATA_KEY_PREFIX = "TrailData_"

-- 싱글톤 인스턴스
local instance = nil

function TrailShopService.new()
	local self = setmetatable({}, TrailShopService)
	self.dataStore = nil
	self.playerCache = {} -- UserId -> TrailData
	self.pendingPurchases = {} -- UserId -> { productId, timestamp }
	return self
end

function TrailShopService.getInstance()
	if not instance then
		instance = TrailShopService.new()
	end
	return instance
end

function TrailShopService:Initialize()
	-- DataStore 초기화
	if not isStudio then
		local success, result = pcall(function()
			return DataStoreService:GetDataStore(DATASTORE_NAME)
		end)
		if success then
			self.dataStore = result
			print("[TrailShopService] DataStore 연결 완료")
		else
			warn("[TrailShopService] DataStore 초기화 실패:", result)
		end
	else
		print("[TrailShopService] Studio 환경 - MockDataStore 사용")
	end

	-- RemoteFunction/Event 생성
	self:SetupRemotes()

	-- MarketplaceService ProcessReceipt 설정
	self:SetupMarketplace()

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

	-- 미리보기 배럴 모델 미리 로드
	task.spawn(function()
		self:LoadPreviewBarrelModel()
	end)

	print("[TrailShopService] 초기화 완료")
end

function TrailShopService:SetupRemotes()
	local trailFolder = ReplicatedStorage:FindFirstChild("TrailSystem")
	if not trailFolder then
		trailFolder = Instance.new("Folder")
		trailFolder.Name = "TrailSystem"
		trailFolder.Parent = ReplicatedStorage
	end

	-- Trail 데이터 조회
	local getTrailsFunc = Instance.new("RemoteFunction")
	getTrailsFunc.Name = "GetTrails"
	getTrailsFunc.Parent = trailFolder
	getTrailsFunc.OnServerInvoke = function(player)
		return self:GetPlayerTrailData(player)
	end

	-- Trail 장착
	local equipTrailFunc = Instance.new("RemoteFunction")
	equipTrailFunc.Name = "EquipTrail"
	equipTrailFunc.Parent = trailFolder
	equipTrailFunc.OnServerInvoke = function(player, barrelName, trailName)
		return self:EquipTrail(player, barrelName, trailName)
	end

	-- Trail 구매 요청 (PromptProductPurchase 트리거)
	local purchaseTrailFunc = Instance.new("RemoteFunction")
	purchaseTrailFunc.Name = "PurchaseTrail"
	purchaseTrailFunc.Parent = trailFolder
	purchaseTrailFunc.OnServerInvoke = function(player, trailName)
		return self:RequestPurchase(player, trailName)
	end

	-- Trail 데이터 업데이트 이벤트 (서버 -> 클라이언트)
	local trailUpdateEvent = Instance.new("RemoteEvent")
	trailUpdateEvent.Name = "TrailDataUpdated"
	trailUpdateEvent.Parent = trailFolder

	-- Trail 에셋 로드 요청 (미리보기용)
	local loadTrailAssetFunc = Instance.new("RemoteFunction")
	loadTrailAssetFunc.Name = "LoadTrailAsset"
	loadTrailAssetFunc.Parent = trailFolder
	loadTrailAssetFunc.OnServerInvoke = function(player, trailName)
		return self:LoadTrailAsset(trailName)
	end
end

function TrailShopService:SetupMarketplace()
	MarketplaceService.ProcessReceipt = function(receiptInfo)
		return self:ProcessReceipt(receiptInfo)
	end

	-- 구매 완료 이벤트 (UI 업데이트용)
	MarketplaceService.PromptProductPurchaseFinished:Connect(function(userId, productId, isPurchased)
		if isPurchased then
			local player = Players:GetPlayerByUserId(userId)
			if player then
				-- 구매 완료 후 클라이언트에 알림
				self:NotifyTrailUpdate(player, self.playerCache[userId])
			end
		end
	end)
end

-- 플레이어 데이터 로드
function TrailShopService:OnPlayerJoined(player)
	local data = self:LoadPlayerData(player)
	self.playerCache[player.UserId] = data
	print("[TrailShopService] 플레이어 데이터 로드:", player.Name)
end

-- 플레이어 데이터 저장 및 캐시 제거
function TrailShopService:OnPlayerLeft(player)
	local data = self.playerCache[player.UserId]
	if data then
		self:SavePlayerData(player, data)
		self.playerCache[player.UserId] = nil
		print("[TrailShopService] 플레이어 데이터 저장:", player.Name)
	end
end

-- DataStore에서 플레이어 데이터 로드
function TrailShopService:LoadPlayerData(player)
	local defaultData = self:CreateDefaultData()

	if isStudio or not self.dataStore then
		return defaultData
	end

	local success, result = pcall(function()
		return self.dataStore:GetAsync(DATA_KEY_PREFIX .. player.UserId)
	end)

	if success and result then
		-- 기존 데이터에 새 필드 병합 (버전 업데이트 대응)
		for key, value in pairs(defaultData) do
			if result[key] == nil then
				result[key] = value
			end
		end
		-- 기본 Trail이 빠져있으면 추가
		for _, trailName in ipairs(TrailDb.GetDefaultOwnedTrails()) do
			if not table.find(result.OwnedTrails, trailName) then
				table.insert(result.OwnedTrails, trailName)
			end
		end
		return result
	end

	return defaultData
end

-- DataStore에 플레이어 데이터 저장
function TrailShopService:SavePlayerData(player, data)
	if isStudio or not self.dataStore then
		return true
	end

	data.LastUpdated = os.time()

	local success, err = pcall(function()
		self.dataStore:SetAsync(DATA_KEY_PREFIX .. player.UserId, data)
	end)

	if not success then
		warn("[TrailShopService] 데이터 저장 실패:", err)
		return false
	end

	return true
end

-- 기본 데이터 생성
function TrailShopService:CreateDefaultData()
	return {
		OwnedTrails = TrailDb.GetDefaultOwnedTrails(),
		EquippedTrails = table.clone(TrailDb.DefaultTrails),
		LastUpdated = os.time(),
	}
end

-- 플레이어 Trail 데이터 조회 (클라이언트용)
function TrailShopService:GetPlayerTrailData(player)
	local data = self.playerCache[player.UserId]
	if not data then
		data = self:LoadPlayerData(player)
		self.playerCache[player.UserId] = data
	end

	return {
		ownedTrails = data.OwnedTrails,
		equippedTrails = data.EquippedTrails,
		allTrails = TrailDb.Trails,
		defaultTrails = TrailDb.DefaultTrails,
		rarities = TrailDb.Rarities,
	}
end

-- Trail 장착
function TrailShopService:EquipTrail(player, barrelName, trailName)
	local data = self.playerCache[player.UserId]
	if not data then
		return { success = false, message = "데이터를 찾을 수 없습니다." }
	end

	-- 소유 여부 확인
	if not table.find(data.OwnedTrails, trailName) then
		return { success = false, message = "소유하지 않은 Trail입니다." }
	end

	-- 유효한 배럴인지 확인
	if not TrailDb.DefaultTrails[barrelName] then
		return { success = false, message = "유효하지 않은 배럴입니다." }
	end

	-- Trail 존재 여부 확인
	if not TrailDb.GetTrailByName(trailName) then
		return { success = false, message = "존재하지 않는 Trail입니다." }
	end

	-- 장착
	data.EquippedTrails[barrelName] = trailName

	-- 저장 (비동기)
	task.spawn(function()
		self:SavePlayerData(player, data)
	end)

	-- 클라이언트 업데이트
	self:NotifyTrailUpdate(player, data)

	local trailInfo = TrailDb.GetTrailByName(trailName)
	return {
		success = true,
		message = trailInfo.DisplayName .. "을(를) 장착했습니다.",
	}
end

-- 구매 요청 (코인 또는 로벅스)
function TrailShopService:RequestPurchase(player, trailName)
	local trailInfo = TrailDb.GetTrailByName(trailName)
	if not trailInfo then
		return { success = false, message = "존재하지 않는 Trail입니다." }
	end

	-- 이미 소유 중인지 확인
	local data = self.playerCache[player.UserId]
	if data and table.find(data.OwnedTrails, trailName) then
		return { success = false, message = "이미 소유한 Trail입니다." }
	end

	-- 코인 가격이 있으면 코인으로 구매
	if trailInfo.CoinPrice and trailInfo.CoinPrice > 0 then
		local coinService = getCoinService()
		if not coinService then
			return { success = false, message = "코인 시스템을 사용할 수 없습니다." }
		end

		-- 코인 충분한지 확인
		if not coinService:HasEnoughCoins(player, trailInfo.CoinPrice) then
			return { success = false, message = "코인이 부족합니다. (필요: " .. trailInfo.CoinPrice .. ")" }
		end

		-- 코인 차감
		local success, result = coinService:SpendCoins(player, trailInfo.CoinPrice)
		if not success then
			return { success = false, message = result }
		end

		-- Trail 지급
		return self:GrantTrail(player, trailName)
	end

	-- 로벅스 구매 (ProductId가 있는 경우)
	if trailInfo.ProductId then
		local success, err = pcall(function()
			MarketplaceService:PromptProductPurchase(player, trailInfo.ProductId)
		end)

		if not success then
			warn("[TrailShopService] 구매 창 열기 실패:", err)
			return { success = false, message = "구매 창을 열 수 없습니다." }
		end

		return { success = true, message = "구매 창을 열었습니다." }
	end

	-- 무료 아이템
	if not trailInfo.CoinPrice or trailInfo.CoinPrice == 0 then
		return self:GrantTrail(player, trailName)
	end

	return { success = false, message = "구매할 수 없는 Trail입니다." }
end

-- Trail 지급 (내부용)
function TrailShopService:GrantTrail(player, trailName)
	local data = self.playerCache[player.UserId]
	if not data then
		return { success = false, message = "데이터를 찾을 수 없습니다." }
	end

	if table.find(data.OwnedTrails, trailName) then
		return { success = false, message = "이미 소유한 Trail입니다." }
	end

	table.insert(data.OwnedTrails, trailName)

	-- 저장
	task.spawn(function()
		self:SavePlayerData(player, data)
	end)

	-- 클라이언트 업데이트
	self:NotifyTrailUpdate(player, data)

	local trailInfo = TrailDb.GetTrailByName(trailName)
	print("[TrailShopService] Trail 지급 완료:", player.Name, trailName)

	return {
		success = true,
		message = trailInfo.DisplayName .. "을(를) 획득했습니다!",
	}
end

-- Developer Product 구매 처리
function TrailShopService:ProcessReceipt(receiptInfo)
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then
		-- 플레이어가 없으면 나중에 다시 처리
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	-- ProductId로 Trail 찾기
	local trailName, trailInfo = TrailDb.GetTrailByProductId(receiptInfo.ProductId)
	if not trailName then
		-- 다른 시스템의 Product일 수 있음
		warn("[TrailShopService] 알 수 없는 ProductId:", receiptInfo.ProductId)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	-- 플레이어 데이터에 Trail 추가
	local data = self.playerCache[player.UserId]
	if not data then
		data = self:LoadPlayerData(player)
		self.playerCache[player.UserId] = data
	end

	-- 이미 소유 중이면 무시 (중복 구매 방지)
	if not table.find(data.OwnedTrails, trailName) then
		table.insert(data.OwnedTrails, trailName)

		-- 저장
		local saved = self:SavePlayerData(player, data)
		if not saved then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end

		-- 클라이언트 업데이트
		self:NotifyTrailUpdate(player, data)

		print("[TrailShopService] Trail 구매 완료:", player.Name, trailName)
	end

	return Enum.ProductPurchaseDecision.PurchaseGranted
end

-- 클라이언트에 Trail 데이터 업데이트 알림
function TrailShopService:NotifyTrailUpdate(player, data)
	local trailFolder = ReplicatedStorage:FindFirstChild("TrailSystem")
	if trailFolder then
		local updateEvent = trailFolder:FindFirstChild("TrailDataUpdated")
		if updateEvent then
			updateEvent:FireClient(player, {
				ownedTrails = data.OwnedTrails,
				equippedTrails = data.EquippedTrails,
			})
		end
	end
end

-- 텔레포트 데이터에 포함할 Trail 정보 반환
function TrailShopService:GetTeleportTrailData(player)
	local data = self.playerCache[player.UserId]
	if not data then
		return {
			EquippedTrails = table.clone(TrailDb.DefaultTrails),
			OwnedTrails = TrailDb.GetDefaultOwnedTrails(),
		}
	end

	return {
		EquippedTrails = data.EquippedTrails,
		OwnedTrails = data.OwnedTrails,
	}
end

-- Trail 에셋 저장 폴더 (클라이언트가 접근 가능)
local trailAssetsFolder = nil

local function getTrailAssetsFolder()
	if not trailAssetsFolder then
		trailAssetsFolder = ReplicatedStorage:FindFirstChild("TrailAssets")
		if not trailAssetsFolder then
			trailAssetsFolder = Instance.new("Folder")
			trailAssetsFolder.Name = "TrailAssets"
			trailAssetsFolder.Parent = ReplicatedStorage
		end
	end
	return trailAssetsFolder
end

-- 미리보기 배럴 모델 에셋 ID
local PREVIEW_BARREL_ASSET_ID = 3678395320

-- 미리보기 배럴 모델 로드 (서버 초기화 시 한 번만)
function TrailShopService:LoadPreviewBarrelModel()
	local InsertService = game:GetService("InsertService")
	local assetsFolder = getTrailAssetsFolder()

	-- 이미 로드되어 있는지 확인
	local existing = assetsFolder:FindFirstChild("PreviewBarrel")
	if existing then
		print("[TrailShopService] 미리보기 배럴 모델 이미 존재")
		return
	end

	print("[TrailShopService] 미리보기 배럴 모델 로드 시도:", PREVIEW_BARREL_ASSET_ID)

	local success, result = pcall(function()
		return InsertService:LoadAsset(PREVIEW_BARREL_ASSET_ID)
	end)

	if success and result then
		-- 모델 또는 파트 찾기
		local model = result:FindFirstChildWhichIsA("Model") or result:FindFirstChildWhichIsA("BasePart")
		if model then
			model = model:Clone()
			model.Name = "PreviewBarrel"
			model.Parent = assetsFolder
			print("[TrailShopService] 미리보기 배럴 모델 로드 완료")
		else
			warn("[TrailShopService] 배럴 에셋에서 Model/BasePart를 찾을 수 없음")
		end
		result:Destroy()
	else
		warn("[TrailShopService] 미리보기 배럴 모델 로드 실패:", result)
	end
end

-- Trail 에셋 로드 (미리보기용) - ReplicatedStorage에 저장 후 이름 반환
local trailAssetCache = {} -- trailName -> true (로드 완료 여부)

function TrailShopService:LoadTrailAsset(trailName)
	local InsertService = game:GetService("InsertService")

	local trailInfo = TrailDb.GetTrailByName(trailName)
	if not trailInfo then
		warn("[TrailShopService] Trail 정보 없음:", trailName)
		return nil
	end

	if not trailInfo.AssetId then
		warn("[TrailShopService] AssetId 없음:", trailName)
		return nil
	end

	local assetsFolder = getTrailAssetsFolder()

	-- 이미 ReplicatedStorage에 있는지 확인
	local existingAsset = assetsFolder:FindFirstChild(trailName)
	if existingAsset then
		return trailName -- 이름만 반환 (클라이언트가 ReplicatedStorage에서 가져감)
	end

	-- 캐시 확인 (로드 진행 중 중복 방지)
	if trailAssetCache[trailName] then
		return trailName
	end

	print("[TrailShopService] 에셋 로드 시도:", trailName, "AssetId:", trailInfo.AssetId)

	-- InsertService로 에셋 로드
	local success, result = pcall(function()
		return InsertService:LoadAsset(trailInfo.AssetId)
	end)

	if not success then
		warn("[TrailShopService] InsertService:LoadAsset 실패:", trailName, "AssetId:", trailInfo.AssetId, "에러:", result)
		return nil
	end

	print("[TrailShopService] 에셋 로드 성공:", trailName)

	-- 로드된 모델에서 Trail/ParticleEmitter 찾기
	local assetModel = result
	local trailObject = nil

	-- 디버그: 에셋 구조 출력
	print("[TrailShopService] 에셋 구조 (", trailName, "):")
	for _, child in ipairs(assetModel:GetDescendants()) do
		print("  -", child.Name, ":", child.ClassName)
	end

	for _, child in ipairs(assetModel:GetDescendants()) do
		-- Trail, ParticleEmitter, Fire, Smoke, Sparkles 등 이펙트 클래스 지원
		if child:IsA("Trail") or child:IsA("ParticleEmitter") or child:IsA("Fire") or child:IsA("Smoke") or child:IsA("Sparkles") then
			trailObject = child:Clone()
			print("[TrailShopService] 이펙트 발견:", child.Name, child.ClassName)
			break
		end
	end

	-- 에셋 정리
	assetModel:Destroy()

	if trailObject then
		-- ReplicatedStorage에 저장 (클라이언트 접근용)
		trailObject.Name = trailName
		trailObject.Parent = assetsFolder
		trailAssetCache[trailName] = true
		print("[TrailShopService] ReplicatedStorage에 저장 완료:", trailName)
		return trailName
	end

	warn("[TrailShopService] Trail/ParticleEmitter를 찾을 수 없음:", trailName)
	return nil
end

return TrailShopService
