--[[
	NormalBarrel: 기본통
	가장 기본적인 배럴로, 폭발 시 데미지만 줍니다.
]]

local BaseBarrel = require(script.Parent.BaseBarrel)

local NormalBarrel = setmetatable({}, BaseBarrel)
NormalBarrel.__index = NormalBarrel

function NormalBarrel.new(player, toolInfo, level)
	local self = BaseBarrel.new(player, toolInfo, level)
	setmetatable(self, NormalBarrel)
	return self
end

function NormalBarrel:OnTouched(hitPart)
	self:DealDamageToTarget(hitPart, self.HitDamage)
end

function NormalBarrel:Throw(targetPosition)
	BaseBarrel.Throw(self, targetPosition)
end

function NormalBarrel:Explode(hitPart, hitPosition)
	if BaseBarrel.Explode(self, hitPart, hitPosition) == false then
		return
	end
	-- NormalBarrel은 추가 효과 없음 (기본 폭발만)
end

return NormalBarrel
