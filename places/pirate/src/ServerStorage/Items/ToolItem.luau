--[[
	ToolItem: 모든 도구(배럴) 아이템의 기본 클래스
	BaseItem을 상속하고 Equipable 인터페이스를 구현

	개별 배럴 아이템 클래스에서 중복되는 코드를 제거
]]

local BaseItem = require(script.Parent.BaseItem)
local Equipable = require(script.Parent.Equipable)
local ItemDb = require(script.Parent.Database.ItemDb)

local ToolItem = {}
ToolItem.__index = ToolItem
setmetatable(ToolItem, BaseItem)

-- Equipable 인터페이스 상속
for k, v in pairs(Equipable) do
	if ToolItem[k] == nil then
		ToolItem[k] = v
	end
end

-- 새 ToolItem 객체 생성 (toolName으로 ItemDb에서 정보 조회)
function ToolItem.new(toolName)
	local itemInfo = ItemDb.Tool[toolName]
	if not itemInfo then
		error("ToolItem: Unknown tool name: " .. tostring(toolName))
	end

	local self = BaseItem.new(
		itemInfo.Id,
		itemInfo.Category,
		itemInfo.Name,
		itemInfo.DisplayName,
		itemInfo.IconId,
		itemInfo.MaxStack
	)
	setmetatable(self, ToolItem)

	-- 도구 스탯 복사
	self.Price = itemInfo.Price
	self.Damage = itemInfo.Damage
	self.DotDamage = itemInfo.DotDamage or 0
	self.Cooldown = itemInfo.Cooldown
	self.ThrowType = itemInfo.ThrowType
	self.MaxRange = itemInfo.MaxRange
	self.ChargingSpeed = itemInfo.ChargingSpeed
	self.ExplosionRadius = itemInfo.ExplosionRadius
	self.MaxShots = itemInfo.MaxShots
	self.ReloadTime = itemInfo.ReloadTime
	self.KnockbackForce = itemInfo.KnockbackForce
	self.FallbackPartName = itemInfo.FallbackPartName

	-- 시각/효과 설정 (ItemDb에서 가져옴)
	self.PartName = itemInfo.PartName
	self.ExplodeEffects = itemInfo.ExplodeEffects
	self.ExplodeSound = itemInfo.ExplodeSound
	self.TrailParticle = itemInfo.TrailParticle

	-- 상점 설정
	self.UnlockPrice = itemInfo.UnlockPrice or 0
	self.Description = itemInfo.Description

	return self
end

function ToolItem:Activate(player)
	-- 하위 클래스에서 구현
end

function ToolItem:Equip(player)
	-- 하위 클래스에서 오버라이드 가능
end

function ToolItem:Unequip(player)
	-- 하위 클래스에서 오버라이드 가능
end

return ToolItem
