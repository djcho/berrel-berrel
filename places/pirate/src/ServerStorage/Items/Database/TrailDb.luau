--[[
	TrailDb: Trail 이펙트 아이템 데이터베이스

	Trail 추가 시:
	1. 이 파일에 Trail 정보 추가
	2. Trail 에셋을 Roblox에 업로드하고 AssetId 입력
	   - 또는 로컬 테스트용으로 ServerStorage/Trail에 에셋 배치
	3. CoinPrice 설정 (인게임 코인 가격)
	4. (선택) ProductId 설정 (로벅스 직접 구매용)

	AssetId 방식:
	- 프리미엄 Trail은 AssetId로 동적 로드 (InsertService:LoadAsset)
	- 기본 Trail은 ServerStorage/Trail에서 로드 (기존 방식)
	- AssetId가 있으면 우선 사용, 없으면 ServerStorage fallback

	가격 체계:
	- CoinPrice: 인게임 코인으로 구매 (기본)
	- ProductId: 로벅스로 직접 구매 (선택)
]]

local TrailDb = {}

-- Trail 카테고리 (필터링용)
TrailDb.Categories = {
	"기본", -- 무료/기본 Trail
	"프리미엄", -- 유료 Trail
	"특별", -- 이벤트/한정 Trail
}

-- 희귀도 정의
TrailDb.Rarities = {
	["일반"] = { order = 1, color = Color3.fromRGB(150, 150, 150) },
	["레어"] = { order = 2, color = Color3.fromRGB(50, 150, 255) },
	["에픽"] = { order = 3, color = Color3.fromRGB(180, 50, 255) },
	["전설"] = { order = 4, color = Color3.fromRGB(255, 180, 0) },
}

-- 배럴별 기본 Trail 매핑
TrailDb.DefaultTrails = {
	NormalBarrel = "Trail",
	OilBarrel = "Oil",
	FireBarrel = "Fire",
	PoisonBarrel = "Gas",
	WindBarrel = "Trail",
}

-- Trail 아이템 목록
TrailDb.Trails = {
	-- ============================================
	-- 기본 Trail (배럴별 기본값, 구매 불필요)
	-- ============================================
	["Trail"] = {
		Id = 1,
		Name = "Trail",
		DisplayName = "기본 잔상",
		Description = "기본 투사체 잔상입니다.",
		Category = "기본",
		CoinPrice = 0, -- 무료
		ProductId = nil,
		AssetId = 131293260336056,
		IconId = "rbxassetid://18946314209",
		Rarity = "일반",
		TrailType = "Trail",
	},
	["Oil"] = {
		Id = 2,
		Name = "Oil",
		DisplayName = "기름 잔상",
		Description = "기름통의 기본 잔상입니다.",
		Category = "기본",
		CoinPrice = 0,
		ProductId = nil,
		AssetId = 137127799791840,
		IconId = "rbxassetid://18946313733",
		Rarity = "일반",
		TrailType = "ParticleEmitter",
	},
	["Fire"] = {
		Id = 3,
		Name = "Fire",
		DisplayName = "불꽃 잔상",
		Description = "화염통의 기본 잔상입니다.",
		Category = "기본",
		CoinPrice = 0,
		ProductId = nil,
		AssetId = 115629137430316,
		IconId = "rbxassetid://18946314613",
		Rarity = "일반",
		TrailType = "ParticleEmitter",
	},
	["Gas"] = {
		Id = 4,
		Name = "Gas",
		DisplayName = "독가스 잔상",
		Description = "독구름통의 기본 잔상입니다.",
		Category = "기본",
		CoinPrice = 0,
		ProductId = nil,
		AssetId = 109552946149272,
		IconId = "rbxassetid://18946313398",
		Rarity = "일반",
		TrailType = "ParticleEmitter",
	},

	-- ============================================
	-- 프리미엄 Trail (코인 구매)
	-- ============================================
	["Rainbow"] = {
		Id = 100,
		Name = "Rainbow",
		DisplayName = "무지개 잔상",
		Description = "화려한 무지개 빛 잔상!",
		Category = "프리미엄",
		CoinPrice = 500, -- 코인
		ProductId = nil,
		AssetId = nil, -- TODO: Roblox에 업로드 후 에셋 ID 입력
		IconId = "rbxassetid://18946314209",
		Rarity = "레어",
		TrailType = "Trail",
	},
	["Starlight"] = {
		Id = 101,
		Name = "Starlight",
		DisplayName = "별빛 잔상",
		Description = "반짝이는 별빛 잔상!",
		Category = "프리미엄",
		CoinPrice = 750,
		ProductId = nil,
		AssetId = nil, -- TODO: Roblox에 업로드 후 에셋 ID 입력
		IconId = "rbxassetid://18946314209",
		Rarity = "레어",
		TrailType = "ParticleEmitter",
	},
	["GhostFlame"] = {
		Id = 102,
		Name = "GhostFlame",
		DisplayName = "유령불 잔상",
		Description = "으스스한 유령불 잔상!",
		Category = "프리미엄",
		CoinPrice = 1000,
		ProductId = nil,
		AssetId = nil, -- TODO: Roblox에 업로드 후 에셋 ID 입력
		IconId = "rbxassetid://18946314613",
		Rarity = "에픽",
		TrailType = "ParticleEmitter",
	},
	["GoldenAura"] = {
		Id = 103,
		Name = "GoldenAura",
		DisplayName = "황금 오라",
		Description = "찬란한 황금빛 오라!",
		Category = "프리미엄",
		CoinPrice = 1500,
		ProductId = nil,
		AssetId = nil, -- TODO: Roblox에 업로드 후 에셋 ID 입력
		IconId = "rbxassetid://18946314209",
		Rarity = "전설",
		TrailType = "Trail",
	},
}

--============================================================
-- 헬퍼 함수
--============================================================

-- ID로 Trail 찾기
function TrailDb.GetTrailById(id)
	for name, trail in pairs(TrailDb.Trails) do
		if trail.Id == id then
			return name, trail
		end
	end
	return nil, nil
end

-- ProductId로 Trail 찾기
function TrailDb.GetTrailByProductId(productId)
	for name, trail in pairs(TrailDb.Trails) do
		if trail.ProductId == productId then
			return name, trail
		end
	end
	return nil, nil
end

-- 이름으로 Trail 찾기
function TrailDb.GetTrailByName(trailName)
	return TrailDb.Trails[trailName]
end

-- 카테고리별 Trail 목록
function TrailDb.GetTrailsByCategory(category)
	local trails = {}
	for name, trail in pairs(TrailDb.Trails) do
		if trail.Category == category then
			table.insert(trails, { name = name, info = trail })
		end
	end
	return trails
end

-- 구매 가능한 Trail 목록 (가격순 정렬)
function TrailDb.GetPurchasableTrails()
	local trails = {}
	for name, trail in pairs(TrailDb.Trails) do
		if trail.CoinPrice and trail.CoinPrice > 0 then
			table.insert(trails, { name = name, info = trail })
		end
	end
	table.sort(trails, function(a, b)
		return (a.info.CoinPrice or 0) < (b.info.CoinPrice or 0)
	end)
	return trails
end

-- 모든 Trail 목록 (희귀도 순 정렬)
function TrailDb.GetAllTrailsSorted()
	local trails = {}
	for name, trail in pairs(TrailDb.Trails) do
		table.insert(trails, { name = name, info = trail })
	end
	table.sort(trails, function(a, b)
		local orderA = TrailDb.Rarities[a.info.Rarity] and TrailDb.Rarities[a.info.Rarity].order or 0
		local orderB = TrailDb.Rarities[b.info.Rarity] and TrailDb.Rarities[b.info.Rarity].order or 0
		if orderA == orderB then
			return (a.info.CoinPrice or 0) < (b.info.CoinPrice or 0)
		end
		return orderA < orderB
	end)
	return trails
end

-- 배럴의 기본 Trail 가져오기
function TrailDb.GetDefaultTrail(barrelName)
	return TrailDb.DefaultTrails[barrelName] or "Trail"
end

-- 기본 Trail 목록 (모든 플레이어 기본 소유) - 빈 배열 (모든 Trail 구매 필요)
function TrailDb.GetDefaultOwnedTrails()
	return {}
end

return TrailDb
