local target = script.Parent

local debouns = false
target.Touched:Connect(function(hitPart)
	if not hitPart.Parent then
		return 
	end
	local humanoid = hitPart.Parent:FindFirstChild("Humanoid")
	if not humanoid then
		return
	end

	if debouns  then
		return
	end

	debouns = true
	spawn(function() 
		humanoid.WalkSpeed = 5
	end)	

	wait(0.5)
	spawn(function() 
		humanoid.WalkSpeed = 16
	end)	
	debouns = false
end)
