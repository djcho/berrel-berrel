local ServerStorage = game:GetService("ServerStorage")
local Inventory = require(ServerStorage.Classes.Inventory)

local function SetupLeaderstats(player)
	local folder = Instance.new("Folder", player)
	folder.Name = "leaderstats"
	local intValue = Instance.new("IntValue", folder)
	intValue.Name = "Kill"
	intValue.Value = 0
	
	intValue = Instance.new("IntValue", folder)
	intValue.Name = "Death"
	intValue.Value = 0
	
	intValue = Instance.new("IntValue", folder)
	intValue.Name = "Coins"
	intValue.Value = 0
end

local UserData = require(game.ServerStorage.Classes.UserData)
local Players = game:GetService("Players")

local Replicated_Storage = game:GetService("ReplicatedStorage")
--local Event = Replicated_Storage:WaitForChild("RemoteEvent")


function CharacterJoined(character)
	local humanoid = character:WaitForChild("Humanoid")
	humanoid.NameOcclusion = Enum.NameOcclusion.NoOcclusion
	humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOn
	
	local boolValue = Instance.new("BoolValue", humanoid)
	boolValue.Name = "burnable"
	boolValue.Value = true
end

function PlayerJoined(player)
	
	SetupLeaderstats(player)
	
	local Data = {inventory = Inventory.new(player)}
	UserData.AddPlayer(player, Data)
	
	player.CharacterAdded:Connect(CharacterJoined)	
end

function PlayerLeft(player)
	UserData.RemovePlayer(player) 
end
function Example(player)	
	local Data = UserData.ReturnData(player)
end

function RetrieveData(player)
--	Event:FireClient(player, DataModule.ReturnData(player))
end

Players.PlayerAdded:Connect(PlayerJoined)
Players.PlayerRemoving:Connect(PlayerLeft)

--Event.OnServerEvent:Connect(RetrieveData)