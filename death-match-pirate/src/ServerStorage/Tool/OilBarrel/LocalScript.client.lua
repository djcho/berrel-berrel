local Damage = 18
local FireRate = 1 / 5.5
local Range = 350
local MaxSpread = 0.07
local ClipSize = 7
local ReloadTime = 2.1


local Tool = script.Parent
local IsShooting = false

local MyPlayer = nil
local MyCharacter = nil
local MyHumanoid = nil
local MyTorso = nil
local MyMouse = nil

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local throwingBarrelEvent = ReplicatedStorage:WaitForChild("ThrowingBarrelEvent")

local player = game.Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalUserData = require(game.ReplicatedStorage.Classes.LocalUserData)
local localUserData = LocalUserData.ReturnData(player)

function OnFire()
	if IsShooting then return end
	if MyHumanoid and MyHumanoid.Health > 0 then
		if not MyCharacter then
			return
		end

		throwingBarrelEvent:FireServer(Tool.Name, MyMouse.Hit.p)
	end
end

function OnMouseDown()
	if localUserData.Shopping  then
		return
	end
	LeftButtonDown = true
	OnFire()
end

function OnMouseUp()
	if localUserData.Shopping  then
		return
	end
	
	LeftButtonDown = false
end


function OnEquipped(mouse)
	print("OnEquipped")
	MyCharacter = Tool.Parent
	MyPlayer = game:GetService('Players'):GetPlayerFromCharacter(MyCharacter)
	MyHumanoid = MyCharacter:FindFirstChild('Humanoid')
	MyTorso = MyCharacter:FindFirstChild('Torso')
	MyMouse = mouse

	if MyMouse then
		
		MyMouse.Button1Down:connect(OnMouseDown)
		MyMouse.Button1Up:connect(OnMouseUp)
	end
end


function OnUnequipped()

end


Tool.Equipped:connect(OnEquipped)
Tool.Unequipped:connect(OnUnequipped)