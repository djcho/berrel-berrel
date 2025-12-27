local ServerStorage = game:GetService("ServerStorage")

local ItemDb = {}

ItemDb.General = {
	["UpgradeNoremalBarrel"] = {
		Id = 1000,
		Name = "UpgradeNoremalBarrel",
		DisplayName = "기본통 업그레이드",
		Price = 5,
		IconId = "rbxassetid://8309081025",
		MaxStack = 99
	},
}
ItemDb.Consumption = {
	["HealthPosion"] = {
		Id = 2000,
		Name = "HealthPosion",
		DisplayName = "체력 포션",
		Price = 5,
		IconId = "",
		MaxStack = 99
	},
}
ItemDb.Tool = {
	["NormalBarrel"] = {
		Id = 3000,
		Category = "Tool",
		Name = "NormalBarrel",
		DisplayName = "기본통",
		Price = 2,
		Damage = 15,
		DotDamage = 0,
		Cooldown = 1,
		ThrowType = "ChargingThrowType",
		MaxRange = 100,
		ChargingSpeed = 10,
		ExplosionRadius = 5,
		MaxShots = 4,
		ReloadTime = 4,
		IconId = "rbxassetid://18946314209",
		Model = ServerStorage.Tool.NormalBarrel,
		MaxStack = 1
	},
	["OilBarrel"] = {
		Id = 3001,
		Category = "Tool",
		Name = "OilBarrel",
		DisplayName = "기름통",
		Price = 5,
		Damage = 5,
		DotDamage = 0,
		Cooldown = 1,
		ThrowType = "ChargingThrowType",
		MaxRange = 200,
		ChargingSpeed = 10,
		ExplosionRadius = 6,
		MaxShots = 3,
		ReloadTime = 2,
		IconId = "rbxassetid://18946313733",
		Model = ServerStorage.Tool.OilBarrel,
		MaxStack = 1
	},
	["FireBarrel"] = {
		Id = 3002,
		Category = "Tool",
		Name = "FireBarrel",
		DisplayName = "화염통",
		Price = 10,
		Damage = 15,
		DotDamage = 10,
		Cooldown = 1,
		ThrowType = "ChargingThrowType",
		MaxRange = 200,
		ChargingSpeed = 10,
		ExplosionRadius = 10,
		MaxShots = 2,
		ReloadTime = 3,
		IconId = "rbxassetid://18946314613",
		Model = ServerStorage.Tool.FireBarrel,
		MaxStack = 1
	},
	["PoisonBarrel"] = {
		Id = 3003,
		Category = "Tool",
		Name = "PoisonBarrel",
		DisplayName = "독구름통",
		Price = 10,
		Damage = 15,
		DotDamage = 10,
		Cooldown = 1,
		ThrowType = "ChargingThrowType",
		MaxRange = 200,
		ChargingSpeed = 10,
		ExplosionRadius = 10,
		MaxShots = 2,
		ReloadTime = 3,
		IconId = "rbxassetid://18946313398",
		Model = ServerStorage.Tool.PoisonBarrel,
		MaxStack = 1
	},
	["WindBarrel"] = {
		Id = 3004,
		Category = "Tool",
		Name = "WindBarrel",
		DisplayName = "바람통",
		Price = 8,
		Damage = 5,
		DotDamage = 0,
		Cooldown = 1,
		ThrowType = "ChargingThrowType",
		MaxRange = 150,
		ChargingSpeed = 10,
		ExplosionRadius = 15,
		KnockbackForce = 80,
		MaxShots = 3,
		ReloadTime = 2.5,
		IconId = "rbxassetid://18946312844",
		Model = ServerStorage.Tool.WindBarrel,
		MaxStack = 1
	}
}

return ItemDb
