--[[
	ItemDb: 모든 아이템의 메타정보를 중앙에서 관리

	아이템 추가 시:
	1. 해당 카테고리(General/Consumption/Tool)에 정보 추가
	2. 필요시 Items 폴더에 아이템 클래스 생성 (BaseItem 상속)
	3. Tool의 경우:
	   - ServerStorage/Parts에 투사체 파츠 추가 (PartName)
	   - ServerStorage/Effect에 폭발 이펙트 추가 (ExplodeEffects)
	   - ServerStorage/Trail에 잔상 파티클 추가 (TrailParticle)

	Tool 객체는 코드로 동적 생성됨 (ServerStorage/Tool 폴더 불필요)
]]

local ItemDb = {}

--============================================================
-- 일반 아이템 (General)
--============================================================
ItemDb.General = {
	["UpgradeNormalBarrel"] = {
		Id = 1000,
		Category = "General",
		Name = "UpgradeNormalBarrel",
		DisplayName = "기본통 업그레이드",
		Description = "기본통의 성능을 업그레이드합니다.",
		Price = 5,
		IconId = "rbxassetid://8309081025",
		MaxStack = 99,
	},
}

--============================================================
-- 소비 아이템 (Consumption)
--============================================================
ItemDb.Consumption = {
	["HealthPotion"] = {
		Id = 2000,
		Category = "Consumption",
		Name = "HealthPotion",
		DisplayName = "체력 포션",
		Description = "체력을 50 회복합니다.",
		Price = 5,
		IconId = "",
		MaxStack = 99,
		-- 소비 아이템 전용 설정
		HealAmount = 50,
		UseSound = "DrinkPotion",
		UseEffect = "HealEffect",
	},
	["SpeedPotion"] = {
		Id = 2001,
		Category = "Consumption",
		Name = "SpeedPotion",
		DisplayName = "신속 포션",
		Description = "5초간 이동속도가 증가합니다.",
		Price = 10,
		IconId = "",
		MaxStack = 99,
		SpeedBoost = 1.5,
		Duration = 5,
		UseSound = "DrinkPotion",
		UseEffect = "SpeedEffect",
	},
}

--============================================================
-- 도구 아이템 (Tool) - 배럴 종류
--============================================================
ItemDb.Tool = {
	["NormalBarrel"] = {
		-- 기본 정보
		Id = 3000,
		Category = "Tool",
		Name = "NormalBarrel",
		DisplayName = "기본통",
		Description = "가장 기본적인 통입니다.",
		Price = 2,
		IconId = "rbxassetid://18946314209",
		MaxStack = 1,

		-- 전투 스탯
		Damage = 15,
		DotDamage = 0,
		Cooldown = 1,
		ThrowType = "ChargingThrowType",
		MaxRange = 100,
		ChargingSpeed = 10,
		ExplosionRadius = 5,
		MaxShots = 1,
		ReloadTime = 4,

		-- 시각/효과 설정
		PartName = "NormalBarrel",           -- ServerStorage/Parts/[PartName]
		ExplodeEffects = {"BrokenWood"},     -- ServerStorage/Effect/[EffectName]
		ExplodeSound = "NormalBarrelExplode", -- 폭발 사운드 이름
		TrailParticle = "Trail",             -- 잔상 파티클

		-- 상점 설정
		UnlockPrice = 0,  -- 0 = 기본 해금
	},

	["OilBarrel"] = {
		Id = 3001,
		Category = "Tool",
		Name = "OilBarrel",
		DisplayName = "기름통",
		Description = "바닥에 기름을 뿌려 적의 이동속도를 늦춥니다.",
		Price = 5,
		IconId = "rbxassetid://18946313733",
		MaxStack = 1,

		Damage = 5,
		DotDamage = 0,
		Cooldown = 1,
		ThrowType = "ChargingThrowType",
		MaxRange = 200,
		ChargingSpeed = 10,
		ExplosionRadius = 6,
		MaxShots = 1,
		ReloadTime = 2,

		PartName = "OilBarrel",
		ExplodeEffects = {"BrokenWood", "SplashOil"},
		ExplodeSound = "NormalBarrelExplode",
		TrailParticle = "Oil",

		-- 기름 전용 설정
		OilModels = {"Oil1", "Oil2", "Oil3"},  -- 랜덤 선택될 기름 모델
		OilDuration = 15,

		UnlockPrice = 100,
	},

	["FireBarrel"] = {
		Id = 3002,
		Category = "Tool",
		Name = "FireBarrel",
		DisplayName = "화염통",
		Description = "기름이나 독에 불을 붙여 강력한 데미지를 줍니다.",
		Price = 10,
		IconId = "rbxassetid://18946314613",
		MaxStack = 1,

		Damage = 15,
		DotDamage = 10,
		Cooldown = 1,
		ThrowType = "ChargingThrowType",
		MaxRange = 200,
		ChargingSpeed = 10,
		ExplosionRadius = 10,
		MaxShots = 1,
		ReloadTime = 3,

		PartName = "FireBarrel",
		ExplodeEffects = {"BrokenWood", "SplashSpark"},
		ExplodeSound = "FireBarrelExplode",
		TrailParticle = "Fire",

		-- 불 전용 설정
		FireDuration = 10,
		ToxicFireDuration = 12,

		UnlockPrice = 200,
	},

	["PoisonBarrel"] = {
		Id = 3003,
		Category = "Tool",
		Name = "PoisonBarrel",
		DisplayName = "독구름통",
		Description = "독 구름을 생성하여 지속 피해를 줍니다. 기름과 조합하면 독성 슬라임!",
		Price = 10,
		IconId = "rbxassetid://18946313398",
		MaxStack = 1,

		Damage = 15,
		DotDamage = 10,
		Cooldown = 1,
		ThrowType = "ChargingThrowType",
		MaxRange = 200,
		ChargingSpeed = 10,
		ExplosionRadius = 10,
		MaxShots = 1,
		ReloadTime = 3,

		PartName = "PoisonBarrel",
		ExplodeEffects = {"BrokenWood", "SplashPoison"},
		ExplodeSound = "NormalBarrelExplode",
		TrailParticle = "Gas",

		-- 독 전용 설정
		PoisonModel = "PoisonFog",
		PoisonDuration = 15,
		ToxicSlimeDuration = 20,
		ToxicSlimeDamageMultiplier = 1.5,

		UnlockPrice = 250,
	},

	["WindBarrel"] = {
		Id = 3004,
		Category = "Tool",
		Name = "WindBarrel",
		DisplayName = "바람통",
		Description = "강력한 바람으로 적을 밀어내고, 기름/독 구름을 확산시킵니다.",
		Price = 8,
		IconId = "rbxassetid://18946312844",
		MaxStack = 1,

		Damage = 5,
		DotDamage = 0,
		Cooldown = 1,
		ThrowType = "ChargingThrowType",
		MaxRange = 150,
		ChargingSpeed = 10,
		ExplosionRadius = 15,
		KnockbackForce = 80,
		MaxShots = 1,
		ReloadTime = 2.5,

		PartName = "WindBarrel",
		FallbackPartName = "NormalBarrel",  -- PartName이 없으면 이걸 사용
		ExplodeEffects = {"BrokenWood", "WindBurst"},
		ExplodeSound = "WindBarrelExplode",
		TrailParticle = "Trail",

		-- 바람 전용 설정
		WindSpreadRadius = 20,
		GasPushDistance = 25,
		OilPushDistance = 15,

		UnlockPrice = 150,
	},
}

--============================================================
-- 헬퍼 함수
--============================================================

-- ID로 아이템 찾기
function ItemDb.GetItemById(id)
	for _, category in pairs({ItemDb.General, ItemDb.Consumption, ItemDb.Tool}) do
		for name, item in pairs(category) do
			if item.Id == id then
				return name, item
			end
		end
	end
	return nil, nil
end

-- 이름으로 아이템 찾기 (모든 카테고리에서)
function ItemDb.GetItem(itemName)
	if ItemDb.General[itemName] then
		return ItemDb.General[itemName]
	elseif ItemDb.Consumption[itemName] then
		return ItemDb.Consumption[itemName]
	elseif ItemDb.Tool[itemName] then
		return ItemDb.Tool[itemName]
	end
	return nil
end

-- 모든 Tool 이름 목록
function ItemDb.GetToolNames()
	local names = {}
	for name, _ in pairs(ItemDb.Tool) do
		table.insert(names, name)
	end
	return names
end

-- 해금 가격으로 정렬된 Tool 목록
function ItemDb.GetToolsSortedByUnlockPrice()
	local tools = {}
	for name, info in pairs(ItemDb.Tool) do
		table.insert(tools, {name = name, info = info})
	end
	table.sort(tools, function(a, b)
		return (a.info.UnlockPrice or 0) < (b.info.UnlockPrice or 0)
	end)
	return tools
end

return ItemDb
