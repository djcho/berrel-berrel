local MAX_DISTANCE = 120
local RAYCAST_OFFSET = 4000
local DEFAULT_HIT_DAMAGE = 10
local MAX_BARREL_LEVEL = 4
local DEFAULT_LEVEL = 1

local PhysicsService = game:GetService("PhysicsService")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local throwingBarrelEvent = ReplicatedStorage:WaitForChild("ThrowingBarrelEvent")
local RunS = game:GetService('RunService')
local Debris = game:GetService("Debris")
local RenderStepped = RunS.RenderStepped
local Heartbeat = RunS.Heartbeat

local BaseBarrel = {}
BaseBarrel.__index = BaseBarrel

function BaseBarrel.new(player, barrelPart, level)
	local self = setmetatable({}, BaseBarrel)

	if barrelPart then
		
		self.Player = player
		self.onTouchedBarrelCooldown = false	
		self.BarrelPart = barrelPart:Clone()	
		self.BarrelPart.CanTouch = true
		self.BarrelPart.CanCollide = true
		self.BarrelPart.Parent = workspace				
		self.BarrelPart:SetNetworkOwner(nil) -- 서버 소유로 설정
		
		self.BarrelPart.Touched:Connect(function(touchedPart)
			if self.BarrelPart:CanCollideWith(touchedPart) then
				self:OnTouchingBarrel(touchedPart)
			end
		end)
	end

	self.Level = level or DEFAULT_LEVEL
	return self
end

-----------------------public method----------------------------

function BaseBarrel:Throw(targetPosition)
	local player = self.Player
	local handle = self.Part
	
	local x0 = player.Character.HumanoidRootPart.Position + Vector3.new(0, 2, -2)
	local distance = (targetPosition - x0).magnitude
	local MAX_DISTANCE = 200
	local TIME_DIVISOR = 100
	local GRAVITY_SCALE = 0.5

	if distance > MAX_DISTANCE then
		distance = MAX_DISTANCE
		targetPosition = x0 + (targetPosition - x0).unit * MAX_DISTANCE
	end

	local t = distance / TIME_DIVISOR
	local g = Vector3.new(0, -game.Workspace.Gravity * GRAVITY_SCALE, 0)
	local v0 = (targetPosition - x0 - 0.5 * g * t * t) / t

	-- 클라이언트로 투사체 정보 전송
	print(self.BarrelPart, x0, v0, g, t)
	throwingBarrelEvent:FireAllClients(self.BarrelPart, x0, v0, g, t)
end

function BaseBarrel:Explode(hitPart, hitPosition)

end

function BaseBarrel:UpgradeLevel()
	if self.Level == MAX_BARREL_LEVEL  then
		return
	end
	
	local CommonUtil = require(ServerStorage.Classes.CommonUtil)
	local commonUtil = CommonUtil.new()
	
	self.Level += 1
	local barrelScale = 1
	barrelScale += 0.5
	commonUtil:ScaleModel(self.BarrelPart, barrelScale)
end

-----------------------private method----------------------------
function BaseBarrel:GetPositionFromSubjectUsingYRaycast(subjectPosition)
	local oilTable = {}
	table.insert(oilTable, self.BarrelPart)
	for _, v in pairs(workspace:GetChildren()) do
		if v.Name:match("Oil") or v.Name:match("SlowPart") then		
			table.insert(oilTable, v)
		end
	end

	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = {oilTable}
	raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
	
	local raycastPosition = Vector3.new(subjectPosition.X, subjectPosition.Y + RAYCAST_OFFSET, subjectPosition.Z)
	return workspace:Raycast(raycastPosition, Vector3.new(0, -5000, 0), raycastParams)
end

function BaseBarrel:OnTouched(hitPart)
end

function BaseBarrel:OnTouchingBarrel(hitPart)


	self.onTouchedBarrelCooldown = true
	self.BarrelPart:Destroy()

	local raycastResult = self:GetPositionFromSubjectUsingYRaycast(self.BarrelPart.Position)
	if raycastResult then
		self:OnTouched(hitPart)
		self:Explode(hitPart, raycastResult.Position)
	end
		
	self.onTouchedBarrelCooldown = false
end

function BaseBarrel:CalculateProjectil(mousePosition)
	local RootPart = self.Player.Character:FindFirstChild("HumanoidRootPart")
	print(mousePosition)

	local correctionValue = 7
	local distance = (RootPart.Position - mousePosition).magnitude + correctionValue
	if distance > MAX_DISTANCE then
		distance =  (MAX_DISTANCE + correctionValue)	
	end
	
	local correctionPosition = ((mousePosition - RootPart.Position).Unit * distance) + RootPart.Position
	local raycastResult = self:GetPositionFromSubjectUsingYRaycast(correctionPosition)
	mousePosition = Vector3.new(correctionPosition.X, raycastResult.Position.Y, correctionPosition.Z)
	print(mousePosition)
	
	
	---- 캐릭터의 시야각 판단	
	--local projectedVector = RootPart.CFrame:PointToObjectSpace(mousePosition) * Vector3.new(1, 0, 1)	
	--local angle = math.atan2(projectedVector.Z, projectedVector.X)
	--local degree = math.deg(angle)
	--if degree >= -30 or degree <= -150 then
	--	--return
	--end

	local T = distance/50 --throwingTime
	-- calculate the v0 needed to reach mouse.Hit.p
	local X0 = ((mousePosition - RootPart.Position).Unit * 5) + Vector3.new(RootPart.Position.X, RootPart.Position.Y+5, RootPart.Position.Z)
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
end

return BaseBarrel
