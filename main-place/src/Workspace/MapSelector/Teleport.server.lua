local clicker = script.Parent.Button.ClickDetector
local numOfPlayers = 0
local requiredPlayers = 1
local playerQueue = {}
local teleportService = game:GetService("TeleportService")

local function hasPlayer(tab, player)
	for i, v in pairs(tab) do
		if v == player then
			return true
		end
	end
	return false
end

local function joinQueue(player)
	if not hasPlayer(playerQueue, player) then
		print("player has joined the queue")
		numOfPlayers += 1
		playerQueue[numOfPlayers] = player
	end
end

local function queueLoop()
	while wait(1) do
		if numOfPlayers >= requiredPlayers then
			print("prepare to teleport")
			local code = teleportService:ReserveServer(8228271871)
			teleportService:TeleportToPrivateServer(8228271871, code, playerQueue)
			numOfPlayers = 0
			playerQueue = {}
		end
	end
end

spawn(queueLoop)
clicker.MouseClick:Connect(joinQueue)