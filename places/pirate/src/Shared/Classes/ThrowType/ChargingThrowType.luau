-- ChargingThrowType Class
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local BaseThrowType = require(ReplicatedStorage:WaitForChild("Classes"):WaitForChild("ThrowType"):WaitForChild("BaseThrowType"))
local ChargingThrowType = setmetatable({}, BaseThrowType)
ChargingThrowType.__index = ChargingThrowType

function ChargingThrowType.new(barrelInfo)
	local self = setmetatable(BaseThrowType.new(barrelInfo), ChargingThrowType)
	self.MouseDownTime = 0
	self.IsMouseDown = false
	self.IsCanceled = false	
	return self
end

function ChargingThrowType:getTargetPosition()
	local currentTime = tick()
	local duration = (currentTime - self.MouseDownTime) * self.ToolInfo.ChargingSpeed

	local x0 = self:getLaunchPosition()
	local mousePosition = self.MyMouse and self.MyMouse.Hit.p or self.TargetPart.Position
	local maxMouseDistance = (mousePosition - x0).magnitude

	local distance = math.min(duration * BaseThrowType.TIME_DIVISOR, maxMouseDistance, self.ToolInfo.MaxRange)
	local targetPosition = x0 + (mousePosition - x0).unit * distance

	return targetPosition
end

function ChargingThrowType:onMouseDown()
	self.MouseDownTime = tick()
	local currentTime = tick()
	if currentTime - self.LastThrowTime >= self.ToolInfo.Cooldown then
		self.Beam.Enabled = true
		self.TargetPart.Transparency = 0.8
	end

	self.IsMouseDown = true
	self.IsCanceled = false
end

function ChargingThrowType:onMouseUp()
	if self.IsCanceled then
		self.IsCanceled = false
		return
	end
	self.IsMouseDown = false
	local currentTime = self.MouseDownTime	
	if currentTime - self.LastThrowTime >= self.ToolInfo.Cooldown then
		self.LastThrowTime = currentTime
		self:fireProjectile(self:getTargetPosition())
	else
		warn("Cooldown in effect. Please wait " .. (self.ToolInfo.Cooldown - (currentTime - self.LastThrowTime)) .. " seconds.")
	end
end

function ChargingThrowType:cancelCharging()
	self.IsMouseDown = false
	self.IsCanceled = true
	self.Beam.Enabled = false
	self.TargetPart.Transparency = 1	
end

function ChargingThrowType:renderBeam()
	local currentTime = tick()
	if currentTime - self.LastThrowTime < self.ToolInfo.Cooldown then	
		return
	end

	local g = Vector3.new(0, -game.Workspace.Gravity * BaseThrowType.GRAVITY_SCALE, 0)
	local x0 = self:getLaunchPosition()
	local targetPosition = self:getTargetPosition()
	local t = (targetPosition - x0).magnitude / BaseThrowType.TIME_DIVISOR
	local v0 = (targetPosition - x0 - 0.5 * g * t * t) / t

	local curve0, curve1, cf1, cf2 = self:calculateBeamPath(g, v0, x0, t)
	self.Beam.CurveSize0 = curve0
	self.Beam.CurveSize1 = curve1
	self.Attach0.CFrame = self.Attach0.Parent.CFrame:inverse() * cf1
	self.Attach1.CFrame = self.Attach1.Parent.CFrame:inverse() * cf2

	self.TargetPart.Position = targetPosition
end

function ChargingThrowType:initialize(tool)
	BaseThrowType.initialize(self, tool)
	self.Tool.Equipped:Connect(function(mouse)
		self:onEquipped(mouse)
		mouse.Button1Down:Connect(function() self:onMouseDown() end)
		mouse.Button1Up:Connect(function() self:onMouseUp() end)
		mouse.Button2Down:Connect(function() self:cancelCharging() end)
	end)

	UserInputService.TouchStarted:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		if input.UserInputType == Enum.UserInputType.Touch then
			self:onMouseDown()
		end
	end)

	UserInputService.TouchEnded:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		if input.UserInputType == Enum.UserInputType.Touch then
			self:onMouseUp()
		end
	end)

	self.Tool.Unequipped:Connect(function() self:onUnequipped() end)
end

function ChargingThrowType:onEquipped(mouse)
	BaseThrowType.onEquipped(self, mouse)
	self.MouseDownTime = 0
	self.IsMouseDown = false
	self.IsCanceled = false
	self.Beam.Enabled = false
	self.TargetPart.Transparency = 1
end

return ChargingThrowType