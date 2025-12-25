-- ServerStorage/Classes/Items/Equipable.lua
local Equipable = {}
Equipable.__index = Equipable

function Equipable:Equip(player)
	error("Equip method not implemented")
end

function Equipable:Unequip(player)
	error("Unequip method not implemented")
end

return Equipable
