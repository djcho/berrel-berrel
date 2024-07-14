local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local loudSpeakerEvent = ReplicatedStorage:WaitForChild("LoudSpeakerEvent")
local playerGui = player:WaitForChild("PlayerGui")


local function OnListen(receivedContent)
	if receivedContent == nil then
		return
	end
	
	if receivedContent:IsA("Sound") then
		receivedContent:Play()
	elseif receivedContent:IsA("StringValue") then
		
	end
end

loudSpeakerEvent.OnClientEvent:Connect(OnListen)