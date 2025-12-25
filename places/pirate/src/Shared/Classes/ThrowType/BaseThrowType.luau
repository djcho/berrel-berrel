-- BaseThrowType Class
local BaseThrowType = {}
BaseThrowType.__index = BaseThrowType

-- Constants
BaseThrowType.GRAVITY_SCALE = 0.5
BaseThrowType.TIME_DIVISOR = 100
BaseThrowType.LAUNCH_DISTANCE = 2

function BaseThrowType.new(toolInfo)
	local self = setmetatable({}, BaseThrowType)
	self.Tool = nil
	self.MyPlayer = nil
	self.MyCharacter = nil
	self.MyHumanoid = nil
	self.MyMouse = nil
	self.Hrp = nil
	self.RenderConnection = nil
	self.ToolInfo = toolInfo
	self.LastThrowTime = 0
	self.TargetPart = nil
	return self
end

function BaseThrowType:initialize(tool)
	self.Tool = tool
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	self.ThrowingBarrelEvent = ReplicatedStorage:WaitForChild("ThrowingBarrelEvent")

	-- Beam setup
	self.Attach0 = Instance.new("Attachment", game.Workspace.Terrain)
	self.Attach1 = Instance.new("Attachment", game.Workspace.Terrain)
	self.Beam = Instance.new("Beam", game.Workspace.Terrain)
	self.Beam.Attachment0 = self.Attach0
	self.Beam.Attachment1 = self.Attach1

	-- Target Part setup
	self.TargetPart = Instance.new("Part")
	self.TargetPart.Anchored = true
	self.TargetPart.CanCollide = false
	self.TargetPart.CanQuery = false
	self.TargetPart.CanTouch = false
	self.TargetPart.Shape = Enum.PartType.Ball
	self.TargetPart.Size = Vector3.new(self.ToolInfo.ExplosionRadius, self.ToolInfo.ExplosionRadius, self.ToolInfo.ExplosionRadius)
	self.TargetPart.Transparency = 1
	self.TargetPart.Material = Enum.Material.Plastic
	self.TargetPart.BrickColor = BrickColor.new("White")
	self.TargetPart.TopSurface = "Smooth"
	self.TargetPart.Parent = game.Workspace
end

function BaseThrowType:calculateBeamPath(g, v0, x0, t1)
	local c = 0.5 * 0.5 * 0.5
	local p3 = 0.5 * g * t1 * t1 + v0 * t1 + x0
	local p2 = p3 - (g * t1 * t1 + v0 * t1) / 3
	local p1 = (c * g * t1 * t1 + 0.5 * v0 * t1 + x0 - c * (x0 + p3)) / (3 * c) - p2

	local curve0 = (p1 - x0).magnitude
	local curve1 = (p2 - p3).magnitude

	local b = (x0 - p3).unit
	local r1 = (p1 - x0).unit
	local u1 = r1:Cross(b).unit
	local r2 = (p2 - p3).unit
	local u2 = r2:Cross(b).unit
	b = u1:Cross(r1).unit

	local cf1 = CFrame.new(x0.x, x0.y, x0.z, r1.x, u1.x, b.x, r1.y, u1.y, b.y, r1.z, u1.z, b.z)
	local cf2 = CFrame.new(p3.x, p3.y, p3.z, r2.x, u2.x, b.x, r2.y, u2.y, b.y, r2.z, u2.z, b.z)

	return curve0, -curve1, cf1, cf2
end

function BaseThrowType:getLaunchPosition()
	local x0 = self.Hrp.Position + Vector3.new(0, 2, 0)
	local mousePosition = self.MyMouse and self.MyMouse.Hit.p or self.TargetPart.Position

	local direction = (mousePosition - x0).unit
	local launchPosition = x0 + direction * BaseThrowType.LAUNCH_DISTANCE

	return launchPosition
end

function BaseThrowType:renderBeam()
	local currentTime = tick()
	if currentTime - self.LastThrowTime < self.ToolInfo.Cooldown then
		return
	end

	self.Beam.Enabled = true

	local g = Vector3.new(0, -game.Workspace.Gravity * BaseThrowType.GRAVITY_SCALE, 0)
	local x0 = self:getLaunchPosition()
	local targetPosition = self.MyMouse and self.MyMouse.Hit.p or self.TargetPart.Position
	local distance = (targetPosition - x0).magnitude

	if distance > self.ToolInfo.MaxRange then
		distance = self.ToolInfo.MaxRange
		targetPosition = x0 + (targetPosition - x0).unit * self.ToolInfo.MaxRange
	end

	local t = distance / BaseThrowType.TIME_DIVISOR
	local v0 = (targetPosition - x0 - 0.5 * g * t * t) / t

	local curve0, curve1, cf1, cf2 = self:calculateBeamPath(g, v0, x0, t)
	self.Beam.CurveSize0 = curve0
	self.Beam.CurveSize1 = curve1
	self.Attach0.CFrame = self.Attach0.Parent.CFrame:inverse() * cf1
	self.Attach1.CFrame = self.Attach1.Parent.CFrame:inverse() * cf2

	self.TargetPart.Transparency = 0.8
	self.TargetPart.Position = targetPosition
end

function BaseThrowType:fireProjectile(targetPosition)
	if self.MyHumanoid and self.MyHumanoid.Health > 0 then
		if not self.MyCharacter then return end

		local x0 = self:getLaunchPosition()
		self.ThrowingBarrelEvent:FireServer(self.Tool.Name, targetPosition)
		self.Beam.Enabled = false
		self.TargetPart.Transparency = 1
	end
end

function BaseThrowType:onEquipped(mouse)
	self.MyCharacter = self.Tool.Parent
	self.MyPlayer = game:GetService('Players'):GetPlayerFromCharacter(self.MyCharacter)
	self.MyHumanoid = self.MyCharacter:FindFirstChild('Humanoid')
	self.Hrp = self.MyCharacter:WaitForChild("HumanoidRootPart")
	self.MyMouse = mouse

	if not self.RenderConnection then	
		self.RenderConnection = game:GetService("RunService").RenderStepped:Connect(function()
			if self.MyMouse then
				self:renderBeam()
			end
		end)
	end
end

function BaseThrowType:onUnequipped()
	self.Beam.Enabled = false
	self.TargetPart.Transparency = 1
	if self.RenderConnection then
		self.RenderConnection:Disconnect()
		self.RenderConnection = nil
	end
end

function BaseThrowType:onMouseDown()
	local currentTime = tick()
	if currentTime - self.LastThrowTime >= self.ToolInfo.Cooldown then
		self.LastThrowTime = currentTime
		self:fireProjectile(self.MyMouse and self.MyMouse.Hit.p or self.TargetPart.Position)
	else
		warn("Cooldown in effect. Please wait " .. (self.ToolInfo.Cooldown - (currentTime - self.LastThrowTime)) .. " seconds.")
	end
end

return BaseThrowType