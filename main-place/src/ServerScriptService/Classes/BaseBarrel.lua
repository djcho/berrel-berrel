local MAX_DISTANCE = 120
local DEFAULT_LEVEL = 1

local ServerStorage = game:GetService("ServerStorage")
local RunS = game:GetService('RunService')
local RenderStepped = RunS.RenderStepped
local Heartbeat = RunS.Heartbeat

local BaseBarrel = {}
BaseBarrel.__index = BaseBarrel


function BaseBarrel.new(barrelPart, name, hitDamage, level, throwingDistance)
	local self = setmetatable({}, BaseBarrel)

	if barrelPart then

		self.onTouchedBarrelCooldown = false	
		self.BarrelPart = barrelPart:Clone()	
		self.BarrelPart.CanTouch = true
		self.BarrelPart.CanCollide = true
		self.BarrelPart.Parent = workspace
		
		self.BarrelPart:SetNetworkOwner()
		self.BarrelPart.Touched:Connect(function(touchedPart)
			self:onTouchedBarrel(touchedPart)
		end)		
		--self.BarrelPart = barrelPartClone
	end

	self.Name = name
	self.HitDamage = hitDamage
	self.Level = level or DEFAULT_LEVEL
	self.ThrowingDistance = throwingDistance or MAX_DISTANCE	
	self.ThrowingGravity = Vector3.new(0, -workspace.Gravity, 0)

	return self
end

-----------------------public method----------------------------

function BaseBarrel:Throw(player, mousePosition)
	self:CalculateProjectil(player, mousePosition)
end

function BaseBarrel:Explode(hitPart, hitPosition)

end

function BaseBarrel:UpgradeLevel()
	self.Level += 1

end

-----------------------private method----------------------------
function BaseBarrel:onTouchedBarrel(hitPart)
	if not hitPart.Parent or hitPart.Parent:FindFirstChild("Humanoid") or
		hitPart.Parent.Parent:FindFirstChild("Humanoid") then
		return
	end

	self.onTouchedBarrelCooldown = true
	self.BarrelPart:Destroy()


	local rayOrigin = self.BarrelPart.Position
	local rayDirection = Vector3.new(0, -100, 0)

	-- Build a "RaycastParams" object and cast the ray

	local oilTable = {}
	table.insert(oilTable, self.BarrelPart)
	for _, v in pairs(workspace:GetChildren()) do
		if not v.Name:match("Oil") then
			continue
		end
		table.insert(oilTable, v)
	end

	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = oilTable
	raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
	local raycastResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
	if raycastResult then
		self:Explode(hitPart, raycastResult.Position)
	end

	self.onTouchedBarrelCooldown = false
end


function BaseBarrel:GetMaxPosition(RootPart, mousePosition)
	return ((mousePosition - RootPart.Position).Unit * MAX_DISTANCE) + RootPart.Position
end

function BaseBarrel:CalculateProjectil(player, mousePosition)
	local RootPart = player.Character:FindFirstChild("HumanoidRootPart")

	local X0 = RootPart.CFrame * Vector3.new(0, 2, -2)
	local distancePosition = RootPart.Position - Vector3.new(mousePosition.X,0, mousePosition.Z) 	
	local distance = distancePosition.magnitude

	if distance > MAX_DISTANCE then
		mousePosition = self:GetMaxPosition(RootPart, mousePosition)
		distancePosition = RootPart.Position - Vector3.new(mousePosition.X,0, mousePosition.Z)
		distance = distancePosition.magnitude
	end

	local projectedVector = RootPart.CFrame:PointToObjectSpace(mousePosition) * Vector3.new(1, 0, 1)	
	local angle = math.atan2(projectedVector.Z, projectedVector.X)
	local degree = math.deg(angle)

	-- 캐릭터의 시야각 판단
	if degree >= -30 or degree <= -150 then
		--return
	end

	local T = distance/50 --throwingTime
	-- calculate the v0 needed to reach mouse.Hit.p
	local V0 = (mousePosition - X0 - 0.1 * self.ThrowingGravity * T * T) / T;

	-- have the ball travel that path
	local NT = 0;
	local rotationAngleX = 0
	local rotationAngleY = 0
	local rotationAngleZ = 0
	local rotationPower = 0

	local random = math.random(0,1)
	local randomRotationPower = Random.new():NextNumber(0,0.2)
	local randomRotationPowerZ = Random.new():NextNumber(0,0.2)

	while (NT < T) do
		if random == 0 then
			rotationAngleX += randomRotationPower
			rotationAngleZ += randomRotationPowerZ
		else
			rotationAngleY += randomRotationPower
			rotationAngleZ += randomRotationPowerZ
		end

		self.BarrelPart.CFrame = CFrame.new(0.1 * self.ThrowingGravity * NT * NT + V0 * NT + X0) * CFrame.Angles(rotationAngleX,rotationAngleY,rotationAngleZ)
		NT = NT + Heartbeat:Wait();
	end

	self.BarrelPart:Destroy()
end

return BaseBarrel