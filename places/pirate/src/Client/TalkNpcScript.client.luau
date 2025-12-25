local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RequestNpcInfo = ReplicatedStorage:WaitForChild("RequestNpcInfo")
local PlayerGui = game.Players.LocalPlayer.PlayerGui

function GetGuiByGuiId(guiId)
	for _, v in pairs(PlayerGui:GetChildren()) do
		if not v:FindFirstChild("GuiId") then
			continue
		end
		
		if v.GuiId.Value == guiId then
			return v
		end
	end	
	
	return nil
end


function OnOpenGui(npcId)
	local npcInfo = RequestNpcInfo:InvokeServer(npcId)
	if not npcInfo then
		return
	end
	
	local gui = GetGuiByGuiId(npcInfo.GuiId)
	gui.OpenGuiEvent:Fire(npcInfo)
end	

for _, v in pairs (game.workspace:GetDescendants())do
	if v.Name == 'InvasionHelper' then -- change part to the name you want to look for
		local proximityPrompt = v:WaitForChild("ProximityPrompt")
		proximityPrompt.Triggered:Connect(function()
			local npcId = proximityPrompt.Parent:FindFirstChild("NpcId")
			if not npcId  then
				return
			end
			
			OnOpenGui(npcId.Value)
		end)

	end
end