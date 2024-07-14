local SurfaceTarget2 = {}

local player = game.Players.LocalPlayer
local mouse = player:GetMouse()
local connection = nil
local surfacePart = nil
local MAX_DISTANCE = 120

function SurfaceTarget2:CreateTargetPart()
	local part = Instance.new("Part", workspace)
	part.Name = "SurfacePart"
	part.Transparency = 1
	part.Size = Vector3.new(12, 0.001, 12)
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.Locked = true
	part.CastShadow = false
	
	local decal = Instance.new("Decal", part)		
	decal.Face = Enum.NormalId.Top
	decal.Texture = "http://www.roblox.com/asset/?id=6230538181"
	
	return part
end

function SurfaceTarget2:GetPositionFromSubjectUsingYRaycast(subjectPosition)
	local raycastParams = RaycastParams.new()	
	raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
	return workspace:Raycast(subjectPosition, Vector3.new(0, -1000, 0), raycastParams)
end

function SurfaceTarget2:GetMaxMousePosition(mousePosition)
	local Self = require(script)
	
	local RootPart = player.Character:FindFirstChild("HumanoidRootPart")	
	local maxDistancePosition = ((mousePosition - RootPart.Position).Unit * (120+5)) + RootPart.Position
	maxDistancePosition = Vector3.new(maxDistancePosition.X, 500, maxDistancePosition.Z)
	local raycastResult = Self:GetPositionFromSubjectUsingYRaycast(maxDistancePosition)
	mousePosition = Vector3.new(maxDistancePosition.X, raycastResult.Position.Y, maxDistancePosition.Z)

	--local correctionValue = 5		
	--local distance = (RootPart.Position - mouse.Hit.Position).magnitude + correctionValue
	--print(distance)
	--mousePosition = (( mouse.Hit.Position - RootPart.Position).Unit * distance) + RootPart.Position 	


	return mousePosition
end

function SurfaceTarget2:GetMousePosition(mousePosition)
	local Self = require(script)

	local RootPart = player.Character:FindFirstChild("HumanoidRootPart")	
	print((mousePosition - RootPart.Position).magnitude)
	local maxDistancePosition = ((mousePosition - RootPart.Position).Unit * (mousePosition - RootPart.Position).magnitude) + RootPart.Position
	maxDistancePosition = Vector3.new(maxDistancePosition.X, 500, maxDistancePosition.Z)
	local raycastResult = Self:GetPositionFromSubjectUsingYRaycast(maxDistancePosition)
	mousePosition = Vector3.new(maxDistancePosition.X, raycastResult.Position.Y, maxDistancePosition.Z)

	--local correctionValue = 5		
	--local distance = (RootPart.Position - mouse.Hit.Position).magnitude + correctionValue
	--print(distance)
	--mousePosition = (( mouse.Hit.Position - RootPart.Position).Unit * distance) + RootPart.Position 	


	return mousePosition
end

function SurfaceTarget2:CheckMaxDistance(mousePosition)
	local RootPart = player.Character:FindFirstChild("HumanoidRootPart")
	local distancePosition = RootPart.Position - mousePosition
	local distance = distancePosition.magnitude

	if distance > MAX_DISTANCE then
		return false
	end
	return true
end


function SurfaceTarget2:DrawSurfaceTarget()	
	local Self = require(script)
	
	Self:RemoveSurfaceTarget()	
	surfacePart = Self:CreateTargetPart()
	mouse.TargetFilter = surfacePart	
	if connection  then
		return
	end
	connection = mouse.Move:Connect(function()		
		if surfacePart then
			local mousePosition = mouse.Hit.Position
			if not Self:CheckMaxDistance(mousePosition) then
				mousePosition = Self:GetMaxMousePosition(mousePosition)
			else
				mousePosition = Self:GetMousePosition(mousePosition)
			end
			surfacePart.Position = mousePosition
		end 
	end) 
end

function SurfaceTarget2:RemoveSurfaceTarget()
	if surfacePart and connection then
		mouse.TargetFilter = nil
		surfacePart:Destroy()	
		surfacePart = nil
		connection:Disconnect()
		connection = nil		
	end	
end


return SurfaceTarget2