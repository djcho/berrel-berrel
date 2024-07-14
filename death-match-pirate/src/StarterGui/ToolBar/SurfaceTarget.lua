local SurfaceTarget = {}

local player = game.Players.LocalPlayer
local mouse = player:GetMouse()
local connection = nil
local surfacePart = nil
local MAX_DISTANCE = 120

function SurfaceTarget:CreateTargetPart()
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

function SurfaceTarget:GetPositionFromSubjectUsingYRaycast(subjectPosition, blackList)
	local raycastParams = RaycastParams.new()	
	raycastParams.FilterDescendantsInstances = {blackList}
	raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
	return workspace:Raycast(subjectPosition, Vector3.new(0, -1000, 0), raycastParams)
end

function SurfaceTarget:GetMaxMousePosition(mousePosition)
	local Self = require(script)
	
	local RootPart = player.Character:FindFirstChild("HumanoidRootPart")
	local maxDistancePosition = ((mousePosition - RootPart.Position).Unit * MAX_DISTANCE) + RootPart.Position
	
	local blackList = {}
	for _, v in pairs(workspace:GetChildren()) do
		if v.Name:match("Oil") or v.Name:match("SlowPart") then		
			table.insert(blackList, v)
		end
	end
	
	local raycastResult = Self:GetPositionFromSubjectUsingYRaycast(maxDistancePosition, blackList)
	mousePosition = Vector3.new(maxDistancePosition.X, raycastResult.Position.Y, maxDistancePosition.Z)

	return mousePosition
end

function SurfaceTarget:GetMousePosition(mousePosition)
	local Self = require(script)

	local blackList = {}
	for _, v in pairs(workspace:GetChildren()) do
		if v.Name:match("Oil") or v.Name:match("SlowPart") then		
			table.insert(blackList, v)
		end
	end

	local raycastResult = Self:GetPositionFromSubjectUsingYRaycast(mousePosition, blackList)
	mousePosition = Vector3.new(mousePosition.X, raycastResult.Position.Y, mousePosition.Z)

	return mousePosition
end


function SurfaceTarget:CheckMaxDistance(mousePosition)
	local RootPart = player.Character:FindFirstChild("HumanoidRootPart")
	local distancePosition = RootPart.Position - mousePosition
	local distance = distancePosition.magnitude

	if distance > MAX_DISTANCE then
		return false
	end
	return true
end


function SurfaceTarget:DrawSurfaceTarget()	
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
			end
			surfacePart.Position = Self:GetMousePosition(mousePosition)
		end 
	end) 
end

function SurfaceTarget:RemoveSurfaceTarget()
	if surfacePart and connection then
		mouse.TargetFilter = nil
		surfacePart:Destroy()	
		surfacePart = nil
		connection:Disconnect()
		connection = nil		
	end	
end


return SurfaceTarget
