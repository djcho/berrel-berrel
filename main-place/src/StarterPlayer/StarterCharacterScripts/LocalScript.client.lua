local player = game.Players.LocalPlayer --the local player
local mouse = player:GetMouse() --his mouse
local target = workspace.Part--this variable will hold the part that's being currently dragged
local ReplicatedStorage = game:WaitForChild("ReplicatedStorage")
local SurfaceTarget = require(ReplicatedStorage:WaitForChild("SurfaceTarget"))
local SurfaceTarget2 = require(ReplicatedStorage:WaitForChild("SurfaceTarget2"))
SurfaceTarget:DrawSurfaceTarget()

local test = Instance.new("Part", workspace)
test.Anchored=true
test.BrickColor = BrickColor.Black()

function GetPositionFromSubjectUsingYRaycast(subjectPosition)
	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = {test}
	raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
	return workspace:Raycast(subjectPosition, Vector3.new(0, -1000, 0), raycastParams)
end


local RootPart = player.Character:FindFirstChild("HumanoidRootPart")
local MAX_DISTANCE = 120
local RAYCAST_OFFSET = 800

mouse.Move:Connect(function()
	if target ~= nil then --this event will be always firing, but we wanna change the target's position only when clicking, that's why we check if down is true
		local correctionValue = 5	
		local distance = 0
		if not SurfaceTarget:CheckMaxDistance(mouse.Hit.Position) then
			distance =  (MAX_DISTANCE+correctionValue)
		else
			distance = (RootPart.Position - mouse.Hit.Position).magnitude + correctionValue
		end
		
		local correctionPosition = (( mouse.Hit.Position - RootPart.Position).Unit * distance) + RootPart.Position
		local raycastPosition = Vector3.new(correctionPosition.X, correctionPosition.Y + RAYCAST_OFFSET, correctionPosition.Z)
		local raycastResult = GetPositionFromSubjectUsingYRaycast(raycastPosition)
		test.Position = Vector3.new(correctionPosition.X, raycastResult.Position.Y, correctionPosition.Z)
		
	--	local raycastResult = GetPositionFromSubjectUsingYRaycast(correctionPosition)
		--test.Position  = Vector3.new(correctionPosition.X, raycastResult.Position.Y, correctionPosition.Z)
		--print(target.Position)
	end 
end) 

--mouse.Button1Up:connect(function()
--	mouse.TargetFilter = nil 
--	target = nil
--end)