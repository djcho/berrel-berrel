--[[
	TrailDataService: Trail 데이터 관리 서비스 (해적맵용)

	기능:
	- 텔레포트 데이터에서 Trail 정보 수신
	- DataStore에서 Trail 정보 직접 로드 (fallback)
	- 플레이어별 장착된 Trail 조회
	- Trail 에셋 로드 및 캐싱 (AssetId 또는 ServerStorage)
]]

local DataStoreService = game:GetService("DataStoreService")
local InsertService = game:GetService("InsertService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local SingletonBase = require(game:GetService("ServerScriptService"):WaitForChild("Common"):WaitForChild("SingletonBase"))
local TrailDb = require(game:GetService("ServerStorage"):WaitForChild("Items"):WaitForChild("Database"):WaitForChild("TrailDb"))

local TrailDataService = setmetatable({}, { __index = SingletonBase })
TrailDataService.__index = TrailDataService

local isStudio = RunService:IsStudio()
local DATASTORE_NAME = "TrailDataStore"
local DATA_KEY_PREFIX = "TrailData_"

function TrailDataService:Initialize()
	self.playerTrailData = {} -- UserId -> EquippedTrails
	self.trailAssetCache = {} -- TrailName -> Trail/ParticleEmitter 템플릿 캐시
	self.dataStore = nil

	-- DataStore 초기화
	if not isStudio then
		local success, result = pcall(function()
			return DataStoreService:GetDataStore(DATASTORE_NAME)
		end)
		if success then
			self.dataStore = result
			print("[TrailDataService] DataStore 연결 완료")
		else
			warn("[TrailDataService] DataStore 초기화 실패:", result)
		end
	else
		print("[TrailDataService] Studio 환경 - DataStore 미사용")
	end

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

	print("[TrailDataService] 초기화 완료")
end

function TrailDataService:OnPlayerJoined(player)
	-- 1순위: 텔레포트 데이터에서 Trail 정보 가져오기
	local joinData = player:GetJoinData()
	local teleportData = joinData and joinData.TeleportData

	if teleportData and teleportData.trailData and teleportData.trailData.EquippedTrails then
		self.playerTrailData[player.UserId] = teleportData.trailData.EquippedTrails
		print("[TrailDataService] 텔레포트 데이터에서 Trail 로드:", player.Name)
		return
	end

	-- 2순위: DataStore에서 직접 로드
	local data = self:LoadFromDataStore(player)
	if data and data.EquippedTrails then
		self.playerTrailData[player.UserId] = data.EquippedTrails
		print("[TrailDataService] DataStore에서 Trail 로드:", player.Name)
		return
	end

	-- 3순위: 기본값 사용
	self.playerTrailData[player.UserId] = table.clone(TrailDb.DefaultTrails)
	print("[TrailDataService] 기본 Trail 사용:", player.Name)
end

function TrailDataService:OnPlayerLeft(player)
	self.playerTrailData[player.UserId] = nil
end

function TrailDataService:LoadFromDataStore(player)
	if isStudio or not self.dataStore then
		return nil
	end

	local success, result = pcall(function()
		return self.dataStore:GetAsync(DATA_KEY_PREFIX .. player.UserId)
	end)

	if success and result then
		return result
	end

	if not success then
		warn("[TrailDataService] DataStore 로드 실패:", result)
	end

	return nil
end

-- 특정 플레이어의 특정 배럴에 장착된 Trail 이름 반환
function TrailDataService:GetEquippedTrail(player, barrelName)
	local data = self.playerTrailData[player.UserId]
	if data and data[barrelName] then
		return data[barrelName]
	end
	return TrailDb.DefaultTrails[barrelName] or "Trail"
end

-- 모든 장착된 Trail 반환
function TrailDataService:GetAllEquippedTrails(player)
	return self.playerTrailData[player.UserId] or table.clone(TrailDb.DefaultTrails)
end

-- Trail 정보 조회
function TrailDataService:GetTrailInfo(trailName)
	return TrailDb.GetTrailByName(trailName)
end

-- Trail 에셋 로드 (캐시 또는 동적 로드)
-- 우선순위: 캐시 -> AssetId -> ServerStorage
function TrailDataService:GetTrailAsset(trailName)
	-- 1. 캐시 확인
	if self.trailAssetCache[trailName] then
		return self.trailAssetCache[trailName]
	end

	local trailInfo = TrailDb.GetTrailByName(trailName)
	if not trailInfo then
		return nil
	end

	local trailTemplate = nil

	-- 2. AssetId가 있으면 InsertService로 로드
	if trailInfo.AssetId then
		local success, asset = pcall(function()
			return InsertService:LoadAsset(trailInfo.AssetId)
		end)

		if success and asset then
			-- 에셋에서 Trail 또는 ParticleEmitter 찾기
			trailTemplate = asset:FindFirstChildWhichIsA("Trail")
				or asset:FindFirstChildWhichIsA("ParticleEmitter")

			if trailTemplate then
				trailTemplate = trailTemplate:Clone()
				trailTemplate.Parent = nil -- 템플릿은 부모 없이 캐시
				asset:Destroy()
				print("[TrailDataService] AssetId에서 Trail 로드:", trailName)
			end
		else
			warn("[TrailDataService] AssetId 로드 실패:", trailName, success and "에셋 없음" or asset)
		end
	end

	-- 3. AssetId 로드 실패 시 ServerStorage fallback
	if not trailTemplate then
		local trailFolder = ServerStorage:FindFirstChild("Trail")
		if trailFolder then
			local localTrail = trailFolder:FindFirstChild(trailName)
			if localTrail then
				trailTemplate = localTrail
				print("[TrailDataService] ServerStorage에서 Trail 로드:", trailName)
			end
		end
	end

	-- 4. 캐시에 저장
	if trailTemplate then
		self.trailAssetCache[trailName] = trailTemplate
	end

	return trailTemplate
end

-- Trail을 배럴 파트에 적용
function TrailDataService:ApplyTrailToBarrel(barrelPart, trailName)
	local trailTemplate = self:GetTrailAsset(trailName)
	if not trailTemplate then
		return false
	end

	if trailTemplate:IsA("Trail") then
		-- Trail 객체: 두 개의 Attachment 필요
		local attachment0 = Instance.new("Attachment")
		attachment0.Name = "TrailAttachment0"
		attachment0.Position = Vector3.new(0, 0.5, 0)
		attachment0.Parent = barrelPart

		local attachment1 = Instance.new("Attachment")
		attachment1.Name = "TrailAttachment1"
		attachment1.Position = Vector3.new(0, -0.5, 0)
		attachment1.Parent = barrelPart

		local trail = trailTemplate:Clone()
		trail.Attachment0 = attachment0
		trail.Attachment1 = attachment1
		trail.Parent = barrelPart
	elseif trailTemplate:IsA("ParticleEmitter") then
		-- ParticleEmitter: Attachment 하나에 붙임
		local attachment = Instance.new("Attachment")
		attachment.Name = "TrailAttachment"
		attachment.Parent = barrelPart

		local trail = trailTemplate:Clone()
		trail.Parent = attachment
	end

	return true
end

return TrailDataService
