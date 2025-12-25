local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local loudSpeakerEvent = ReplicatedStorage:WaitForChild("LoudSpeakerEvent")
local alretMessageEvent = ReplicatedStorage:WaitForChild("AlretMessageEvent")
local playerGui = player:WaitForChild("PlayerGui")
local SoundService = game:GetService("SoundService")
local alertMessageSound = SoundService:WaitForChild("AlertMessage")

local function Alert(message, textColor)
	local alertGui = playerGui.ScreenGui.Frame.AlertMessage
	alertGui.Text = message
	if textColor  then
		alertGui.TextColor3 = textColor
	end
	while alertGui.TextTransparency >= 0 do
		alertGui.TextTransparency -= 0.1
		wait(0.01)
	end
	alertMessageSound:Play()
	wait(2)
	while alertGui.TextTransparency <= 1 do
		alertGui.TextTransparency += 0.1
		wait(0.01)
	end
end

local function OnListen(receivedContent)
	if receivedContent == nil then
		return
	end
	
	if typeof(receivedContent) == "string"  then
		Alert(receivedContent)
	elseif receivedContent:IsA("Sound") then
		receivedContent:Play()
	end
end

loudSpeakerEvent.OnClientEvent:Connect(OnListen)
alretMessageEvent.Event:Connect(Alert)