local Debris = game:GetService("Debris");
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

-- Created by Quenty
wait(1)

local Configuration = {
	MaxSpeed               = 30;
	Acceleration           = 5; -- Will always be a little bit less than this because ROBLOX characters will add mass. Also, friction.
	MaxRotationCorrectionAcceleration = math.pi/10;  -- I wouldn't touch this. 
		-- math.pi/10 -- Correct for 18 degrees every.... second?
	PercentExtraCargo      = 0.005; -- Compared to boat's mass (weight), how much extra cargo can it support (irncludes characters) before it starts sinking. 
	
	TurnAccelerationFactor = 150; -- E_e No idea why this is 500.
	MaxTurnSpeed           = 2.5; -- RotVelocity will probably never get to this. 
	
	MaxShipTiltInRadians   = math.pi/8;
	TiltRatioFactor        = 0.01; -- Don't touch this. Used because the BodyAngularVelocity "can't even" when it comes to reaching desired velocity. 

	AmplitudeOfWaves       = 2.5; -- How far up/down the boat moves in the waves.  (Amplitude, so if you physics, you realize it can move this magnitude away from the starting point, either up, or down).
	MaxShipYawInRadians    = math.pi/120; -- Yaws in the waves
	AddedYawOnSpeed        = math.pi/80;
	
	WaterLevel = 39;
}

local function WaitForChild(Parent, Name, TimeLimit)
	-- Waits for a child to appear. Not efficient, but it shoudln't have to be. It helps with debugging. 
	-- Useful when ROBLOX lags out, and doesn't replicate quickly.
	-- @param TimeLimit If TimeLimit is given, then it will return after the timelimit, even if it hasn't found the child.

	assert(Parent ~= nil, "Parent is nil")
	assert(type(Name) == "string", "Name is not a string.")

	local Child     = Parent:FindFirstChild(Name)
	local StartTime = tick()
	local Warned    = false

	while not Child and Parent do
		wait(0)
		Child = Parent:FindFirstChild(Name)
		if not Warned and StartTime + (TimeLimit or 5) <= tick() then
			Warned = true
			warn("Infinite yield possible for WaitForChild(" .. Parent:GetFullName() .. ", " .. Name .. ")")
			if TimeLimit then
				return Parent:FindFirstChild(Name)
			end
		end
	end

	if not Parent then
		warn("Parent became nil.")
	end

	return Child
end


local function Modify(Instance, Values)
	-- Modifies an Instance by using a table.  

	for Index, Value in next, Values do
		if type(Index) == "number" then
			Value.Parent = Instance
		else
			Instance[Index] = Value
		end
	end
	return Instance
end

local function Make(ClassType, Properties)
	-- Using a syntax hack to create a nice way to Make new items.  

	return Modify(Instance.new(ClassType), Properties)
end

local Signal = {}

function Signal.new()
	local sig = {}
	
	local mSignaler = Instance.new('BindableEvent')
	
	local mArgData = nil
	local mArgDataCount = nil
	
	function sig:fire(...)
		mArgData = {...}
		mArgDataCount = select('#', ...)
		mSignaler:Fire()
	end
	
	function sig:connect(f)
		if not f then error("connect(nil)", 2) end
		return mSignaler.Event:connect(function()
			f(unpack(mArgData, 1, mArgDataCount))
		end)
	end
	
	function sig:wait()
		mSignaler.Event:wait()
		assert(mArgData, "Missing arg data, likely due to :TweenSize/Position corrupting threadrefs.")
		return unpack(mArgData, 1, mArgDataCount)
	end
	
	return sig
end


local function WeldTogether(Part0, Part1, JointType, WeldParent)
	--- Weld's 2 parts together
	-- @param Part0 The first part
	-- @param Part1 The second part (Dependent part most of the time).
	-- @param [JointType] The type of joint. Defaults to weld.
	-- @param [WeldParent] Parent of the weld, Defaults to Part0 (so GC is better).
	-- @return The weld created.

	JointType = JointType or "Weld"

	local NewWeld = Make(JointType, {
		Part0  = Part0;
		Part1  = Part1;
		C0     = CFrame.new();--Part0.CFrame:inverse();
		C1     = Part1.CFrame:toObjectSpace(Part0.CFrame); --Part1.CFrame:inverse() * Part0.CFrame;-- Part1.CFrame:inverse();
		Parent = WeldParent or Part0;
	})

	return NewWeld
end

local function WeldParts(Parts, MainPart, JointType, DoNotUnanchor)
	-- @param Parts The Parts to weld. Should be anchored to prevent really horrible results.
	-- @param MainPart The part to weld the model to (can be in the model).
	-- @param [JointType] The type of joint. Defaults to weld. 
	-- @parm DoNotUnanchor Boolean, if true, will not unachor the model after cmopletion.

	for _, Part in pairs(Parts) do
		WeldTogether(MainPart, Part, JointType, MainPart)
	end

	if not DoNotUnanchor then
		for _, Part in pairs(Parts) do
			Part.Anchored = false
		end
		MainPart.Anchored = false
	end
end

local function CallOnChildren(Instance, FunctionToCall)
	-- Calls a function on each of the children of a certain object, using recursion.  

	FunctionToCall(Instance)

	for _, Child in next, Instance:GetChildren() do
		CallOnChildren(Child, FunctionToCall)
	end
end

local function GetBricks(StartInstance)
	local List = {}

	-- if StartInstance:IsA("BasePart") then
	-- 	List[#List+1] = StartInstance
	-- end

	CallOnChildren(StartInstance, function(Item)
		if Item:IsA("BasePart") then
			List[#List+1] = Item;
		end
	end)

	return List;
end

local function GetBricksWithIgnoreFunction(StartInstance, DoIgnore)
	--- Get's the bricks in a model, but will not get a brick that is "NoInclude"

	local List = {}

	CallOnChildren(StartInstance, function(Item)
		if Item:IsA("BasePart") and not DoIgnore(Item) then
			List[#List+1] = Item
		end
	end)

	return List
end


local function GetCharacter(Descendant)
	-- Returns the Player and Charater that a descendent is part of, if it is part of one.
	-- @param Descendant A child of the potential character. 

	local Charater = Descendant
	local Player   = Players:GetPlayerFromCharacter(Charater)

	while not Player do
		if Charater.Parent then
			Charater = Charater.Parent
			Player   = Players:GetPlayerFromCharacter(Charater)
		else
			return nil
		end
	end

	return Charater, Player
end

local MakeMaid do
	local index = {
		GiveTask = function(self,task)
			local n = #self.Tasks+1
			self.Tasks[n] = task
			return n
		end;
		DoCleaning = function(self)
			local tasks = self.Tasks
			for name,task in pairs(tasks) do
				if type(task) == 'function' then
					task()
				else
					task:disconnect()
				end
				tasks[name] = nil
			end
			-- self.Tasks = {}
		end;
	};
	local mt = {
		__index = function(self,k)
			if index[k] then
				return index[k]
			else
				return self.Tasks[k]
			end
		end;
		__newindex = function(self,k,v)
			local tasks = self.Tasks
			if v == nil then
				-- disconnect if the task is an event
				if type(tasks[k]) ~= 'function' then
					tasks[k]:disconnect()
				end
			elseif tasks[k] then
				-- clear previous task
				self[k] = nil
			end
			tasks[k] = v
		end;
	}
	
	function MakeMaid()
		return setmetatable({Tasks={},Instances={}},mt)
	end
end


local function CheckPlayer(Player)
	--- Makes sure a player has all necessary components.
	-- @return Boolean If the player has all the right components

	return Player and Player:IsA("Player") 
end

local function CheckCharacter(Player)
	-- Makes sure a character has all the right "parts"
	
	if CheckPlayer(Player) then
		local Character = Player.Character;

		if Character then
			
			return Character.Parent
				and Character:FindFirstChild("Humanoid")
				and Character:FindFirstChild("HumanoidRootPart")
				and Character:FindFirstChild("Torso") 
				and Character:FindFirstChild("Head") 
				and Character.Humanoid:IsA("Humanoid")
				and Character.Head:IsA("BasePart")
				and Character.Torso:IsA("BasePart")
				and true
		end
	else
		print("[CheckCharacter] - Character Check failed!")
	end

	return nil
end

local function GetCenterOfMass(Parts)
	--- Return's the world vector center of mass.
	-- Lots of help from Hippalectryon :D

	local TotalMass = 0
	local SumOfMasses = Vector3.new(0, 0, 0)

	for _, Part in pairs(Parts) do
		-- Part.BrickColor = BrickColor.new("Bright yellow")
		TotalMass = TotalMass + Part:GetMass()
		SumOfMasses = SumOfMasses + Part:GetMass() * Part.Position
	end

	-- print("Sum of masses: " .. tostring(SumOfMasses))
	-- print("Total mass:    " .. tostring(TotalMass))

	return SumOfMasses/TotalMass, TotalMass
end

-- Moment of Inertia of any rectangular prism.
-- 1/12 * m * sum(deminsionlengths^2)

local function MomentOfInertia(Part, Axis, Origin)
	--- Calculates the moment of inertia of a cuboid.

	-- Part is part
	-- Axis is the axis
	-- Origin is the origin of the axis

	local PartSize = Part.Size

	local Mass  = Part:GetMass()
	local Radius  = (Part.Position - Origin):Cross(Axis)
	local r2 = Radius:Dot(Radius)
	local ip = Mass * r2--Inertia based on Position
	local s2 = PartSize*PartSize
	local sa = (Part.CFrame-Part.Position):inverse()*Axis
	local id = (Vector3.new(s2.y+s2.z, s2.z+s2.x, s2.x+s2.y)):Dot(sa*sa)*Mass/12 -- Inertia based on Direction
	return ip+id
end

local function BodyMomentOfInertia(Parts, Axis, Origin)
	--- Given a connected body of parts, returns the moment of inertia of these parts
	-- @param Parts The parts to use
	-- @param Axis the axis to use (Should be torque, or offset cross force)
	-- @param Origin The origin of the axis (should be center of mass of the parts)
	
	local TotalBodyInertia = 0

	for _, Part in pairs(Parts) do
		TotalBodyInertia = TotalBodyInertia + MomentOfInertia(Part, Axis, Origin)
	end

	return TotalBodyInertia
end

local function GetBackVector(CFrameValue)
	--- Get's the back vector of a CFrame Value
	-- @param CFrameValue A CFrame, of which the vector will be retrieved
	-- @return The back vector of the CFrame

	local _,_,_,_,_,r6,_,_,r9,_,_,r12 = CFrameValue:components()
	return Vector3.new(r6,r9,r12)
end

local function GetCFrameFromTopBack(CFrameAt, Top, Back)
	--- Get's the CFrame fromt he "top back" vector. or something

	local Right = Top:Cross(Back) -- Get's the "right" cframe lookvector.
	return CFrame.new(CFrameAt.x, CFrameAt.y, CFrameAt.z,
		Right.x, Top.x, Back.x,
		Right.y, Top.y, Back.y,
		Right.z, Top.z, Back.z
	)
end

local function GetRotationInXZPlane(CFrameValue)
	--- Get's the rotation in the XZ plane (global).

	local Back = GetBackVector(CFrameValue)
	return GetCFrameFromTopBack(CFrameValue.p, 
		Vector3.new(0,1,0), -- Top lookVector (straight up)
		Vector3.new(Back.x, 0, Back.z).unit -- Right facing direction (removed Y axis.)
	)
end

local function Sign(Number)
	-- Return's the mathetmatical sign of an object
	if Number == 0 then
		return 0
	elseif Number > 0 then
		return 1
	else
		return -1
	end
end

local EasyConfiguration = require(WaitForChild(script, "EasyConfiguration"))

----------------------------------

local PhysicsManager, SeatManager, ControlManager
local BoatModel = script.Parent
local Seat = WaitForChild(BoatModel, "qBoatSeat")
--local Rigging = WaitForChild(BoatModel, "Rigging")

local ShipData = EasyConfiguration.MakeEasyConfiguration(script)


ShipData.AddValue("IntValue", {
	Name = "MaxShipHealth";
	Value = 10000;
})

ShipData.AddValue("IntValue", {
	Name = "ShipHealth";
	Value = ShipData.MaxShipHealth;
})

local DamageShipFunction = WaitForChild(script, "DamageShip")
function DamageShipFunction.OnInvoke(Damage)
	if tonumber(Damage) then
		ShipData.ShipHealth = ShipData.ShipHealth - Damage
	else
		warn("[ShipScript] - Derp a herp give me a number you idiot")
	end
end

local ShipSinkingManager = {} do
	ShipSinkingManager.Sinking = false
	
	local FireList = {}
	
	local function DecomposeVector3(Vector)
		return Vector.X, Vector.Y, Vector.Z
	end
	
	local CannonSets = {}
	local function GetCannonSets(Model)
		for _, Item in pairs(Model:GetChildren()) do
			if Item:IsA("Model") then
				if Item:FindFirstChild("qCannonManager") then
					CannonSets[Item] = true
					--print("Cannon set found", Item)
				else
					GetCannonSets(Item)
				end
			end
		end
	end
	GetCannonSets(BoatModel)
	
	local function IsChildOfCannonSet(Child)
		for CannonSet, _ in pairs(CannonSets) do
			if Child:IsDescendantOf(CannonSet) then
				return true
			end
		end
		
		return false
	end
	
	function ShipSinkingManager:SetRandomPartsOnFire(PartList)
		local RelativeLookVector = Seat.CFrame.lookVector
		ShipSinkingManager.TallestPart = PartList[1]
		
		for _, Item in pairs(PartList) do
			local LargestSize = math.max(DecomposeVector3(Item.Size))
			local RelativeYHeight = Seat.CFrame:toObjectSpace(Item.CFrame).p.Y + 10
			
			if Item.Position.Y > ShipSinkingManager.TallestPart.Position.Y then
				ShipSinkingManager.TallestPart = Item
			end
			
			if LargestSize <= 30 and not Item:FindFirstChild("FlameFromSink") and Item.Transparency < 1 and not IsChildOfCannonSet(Item) and Item ~= PhysicsManager.CenterPart then
				if math.random() > 0.5 then
					delay(RelativeYHeight/15 + (math.random() - 0.5)*2, function()
						local Fire = Instance.new("Fire", Item)
						Fire.Size = LargestSize + 5
						Fire.Name = "FlameFromSink"
						Fire.Archivable = false
						Fire.Heat = 0
						
						local Index = #FireList+1
						local NewFire = {
							Fire = Fire;
							Part = Item;
						}
						if math.random() > 0.5 then
							local Smoke = Instance.new("Smoke", Item)
							Smoke.Name = "Smoke"
							Smoke.Archivable = false
							Smoke.RiseVelocity = 10;
							
							local SmokeColorPercent = 0.5 + math.random()*0.3
							Smoke.Color = Color3.new(SmokeColorPercent, SmokeColorPercent, SmokeColorPercent)
							Smoke.Size = LargestSize + 5
							Smoke.Opacity = 0.1
							
							NewFire.Smoke = Smoke
						end
						
						FireList[Index] = NewFire
					end)
				end
			end
		end
	end
	
	local function BreakOffPart(Part)
		Part:BreakJoints()
		Part.CanCollide = false
		
		local Mass = Part:getMass()
		local Floater = Make("BodyPosition", {
			Parent = Part;
			maxForce = Vector3.new(0, Mass * 9.81 * 20 * (1+Configuration.PercentExtraCargo), 0);
			position = Vector3.new(0, Configuration.WaterLevel, 0);
			Archivable = false;
		})
		
		PhysicsManager:ReduceGravity(Mass)
		Debris:AddItem(Floater, 5)
	end
	
	function ShipSinkingManager:StartManagingFire()
		spawn(function()
			while ShipSinkingManager.Sinking do
				local Index = 1
				while Index <= #FireList do
					local Fire = FireList[Index]
					--print(Index, Fire)
					if Fire.Part.Position.Y <= Configuration.WaterLevel then
						--print("Removing ", Index)
						Fire.Fire:Destroy()
						
						if Fire.Smoke then
							Fire.Smoke:Destroy()
						end
						
						table.remove(FireList, Index)
					else
						Index = Index + 1
						
						if math.random() <= 0.05 and Fire.Part.Material.Name ~= "Fabric" then
							BreakOffPart(Fire.Part)
						end
					end
				end
				wait(0.1)
				if ShipSinkingManager.TallestPart.Position.Y <= Configuration.WaterLevel - 25 then
					ShipSinkingManager:CleanUp()
				end
			end
		end)
	end
	
	function ShipSinkingManager:CleanUp()
		print("Cleaning")
		
		ShipSinkingManager.Sinking = false
		PhysicsManager:Destroy()
		ControlManager:Destroy()
		
		BoatModel:Destroy()
	end
	
	function ShipSinkingManager:Sink()
		if not ShipSinkingManager.Sinking then
			ShipSinkingManager.Sinking = true
			ShipSinkingManager:SetRandomPartsOnFire(PhysicsManager.Parts)
			PhysicsManager:Sink()
			ShipSinkingManager:StartManagingFire()
		end
	end
end

ShipData.Get("ShipHealth").Changed:connect(function()
	if ShipData.ShipHealth <= 0 then
		ShipSinkingManager:Sink()
	end
end)


PhysicsManager = {} do
	PhysicsManager.Active = true
	local Parts = {}
	PhysicsManager.Parts = Parts
	PhysicsManager.RotateGyro = CFrame.new() -- Used by sinking
	PhysicsManager.TotalForceReductionInBodyPosition = 1 -- Er... not a total, but a uh... running percentage? 
	
	CallOnChildren(BoatModel, function(Part)
		if Part:IsA("BasePart") then
			Parts[#Parts+1] = Part
		end
	end)
	 -- Force = Mass * Acceleration 
	
	local CenterOfMass, TotalMass = GetCenterOfMass(Parts)
	
	local CenterPart        = Instance.new("Part", BoatModel)
	CenterPart.Anchored     = true;
	CenterPart.Name         = "CenterPart";
	CenterPart.CanCollide   = false;
	CenterPart.Archivable   = false;
	CenterPart.FormFactor   = "Custom";
	CenterPart.Size         = Vector3.new(0.2, 0.2, 0.2)
	CenterPart.Transparency = 1
	CenterPart.CFrame       = GetRotationInXZPlane(Seat.CFrame - Seat.CFrame.p) + CenterOfMass
	PhysicsManager.CenterPart = CenterPart
	
	TotalMass = TotalMass + CenterPart:GetMass()
	
	local BodyPosition      = Instance.new("BodyPosition")
	BodyPosition.P          = 0 --10000000
	BodyPosition.D          = 0 --10000000
	BodyPosition.maxForce   = Vector3.new(0, 1 * TotalMass*(1+Configuration.PercentExtraCargo) * 9.81 * 20, 0) --Vector3.new(0, 100000000, 0)
	BodyPosition.Parent     = CenterPart
	BodyPosition.position   = CenterPart.Position--]]
	BodyPosition.Archivable = false
	
	local BodyGyro = Instance.new("BodyGyro")
	BodyGyro.D = 100
	BodyGyro.P = 1000
	BodyGyro.maxTorque = Vector3.new(1, 0, 1) * (Configuration.MaxRotationCorrectionAcceleration) --Vector3.new(8999999488, 0, 8999999488)
	BodyGyro.Parent = CenterPart
	BodyGyro.cframe = CenterPart.CFrame
	BodyGyro.Archivable = false
	
	local BodyVelocity = Instance.new("BodyVelocity")
	BodyVelocity.maxForce = Vector3.new(1, 0, 1) * (TotalMass * Configuration.Acceleration) --Vector3.new(1000000, 0, 1000000)
	BodyVelocity.P = 100
	BodyVelocity.Parent = CenterPart

	local BodyAngularVelocity = Instance.new("BodyAngularVelocity")
	BodyAngularVelocity.maxTorque = Vector3.new(0, 1*TotalMass * Configuration.TurnAccelerationFactor, 0)
	BodyAngularVelocity.P = 100
	BodyAngularVelocity.Parent = CenterPart
	BodyAngularVelocity.angularvelocity = Vector3.new()
	
	local TiltCoroutine = coroutine.create(function()
		local BasePosition = BodyPosition.position
		local Count = tick()%100000
		
		while PhysicsManager.Active do
			local Delta = coroutine.yield()
			Count = Count + 0.1*Delta
			
			local YRotation   = GetRotationInXZPlane(CenterPart.CFrame)
			local UndoctoredPercentTilt = CenterPart.RotVelocity.Y/Configuration.MaxSpeed/Configuration.TiltRatioFactor -- Because apparently bodyangularvelocity's never get close to the true value. 
			local UndoctoredPercentSpeed = CenterPart.Velocity.magnitude/Configuration.MaxSpeed
			
			local UndoctoredPercent = UndoctoredPercentTilt*UndoctoredPercentSpeed
			
			local PercentTilt = math.max(0, math.min(1, math.abs(UndoctoredPercent)))*Sign(UndoctoredPercent)
			
			
			local PercentSpeed = math.max(0, math.min(1, UndoctoredPercentSpeed))
			
			local AddedYaw = Configuration.AddedYawOnSpeed * PercentSpeed
			local NewYawAmount = math.sin(Count)*Configuration.MaxShipYawInRadians*(1-PercentSpeed)+AddedYaw
			local Yaw = CFrame.Angles(NewYawAmount, 0, 0)
			
			local Tilt = CFrame.Angles(0, 0, Configuration.MaxShipTiltInRadians * PercentTilt) 
			BodyGyro.cframe = YRotation * Tilt * Yaw * PhysicsManager.RotateGyro
		end
	end)
	
	local WaveCoroutine = coroutine.create(function()
		local BasePosition = BodyPosition.position
		local Count = tick()%100000
		
		while PhysicsManager.Active do
			local Delta = coroutine.yield()
			Count = Count + 0.1*Delta
			
			local UndoctoredPercentSpeed = CenterPart.Velocity.magnitude/Configuration.MaxSpeed
			local PercentSpeed = math.max(0, math.min(1, UndoctoredPercentSpeed))
			
			--print("PercentSpeed", PercentSpeed)
			
			local AddedHeightFromSpeed = Configuration.AmplitudeOfWaves * PercentSpeed
			local WaveHeight = math.sin(Count)*Configuration.AmplitudeOfWaves*(1-PercentSpeed) + AddedHeightFromSpeed -- waves don't effect ships moving fast. 
			
			BodyPosition.position = BasePosition + Vector3.new(0, WaveHeight, 0)
		end
	end)
	
	spawn(function()	
		local Delta = 0.1

		while PhysicsManager.Active do		
			assert(coroutine.resume(TiltCoroutine, Delta))
			assert(coroutine.resume(WaveCoroutine, Delta))
			
			Delta = wait(0.1)
		end
	end)
	
	function PhysicsManager:ReduceGravity(Mass)
		BodyPosition.maxForce = BodyPosition.maxForce - Vector3.new(0, 
			Mass*(1+Configuration.PercentExtraCargo) * 9.81 * 20 * PhysicsManager.TotalForceReductionInBodyPosition, 
			0)
	end
	
	function PhysicsManager:ControlUpdate(Forwards, Turn)
		Forwards = Forwards or 0
		Turn = Turn or 0
		
		BodyVelocity.velocity = CenterPart.CFrame.lookVector * Forwards * Configuration.MaxSpeed
		BodyAngularVelocity.angularvelocity = Vector3.new(0, Configuration.MaxTurnSpeed * Turn, 0)
	end
	
	function PhysicsManager:StopControlUpdate()
		BodyVelocity.velocity = Vector3.new()
		BodyAngularVelocity.angularvelocity = Vector3.new()
	end
	
	function PhysicsManager:Sink()
		
		spawn(function()
			local ChangeInRotationOnSinkX = math.random() * math.pi/720
			local ChangeInRotationOnSinkZ = math.random() * math.pi/720
			local ChangeInForce        = 0.999
			local ControlChangeInForce = 0.999
			
			while PhysicsManager.Active do
				PhysicsManager.TotalForceReductionInBodyPosition = PhysicsManager.TotalForceReductionInBodyPosition * ChangeInForce
				BodyPosition.maxForce = BodyPosition.maxForce * ChangeInForce
				ChangeInForce = 1-((1 - ChangeInForce)*0.95)
				
				BodyAngularVelocity.maxTorque = BodyAngularVelocity.maxTorque * ControlChangeInForce
				BodyVelocity.maxForce = BodyVelocity.maxForce * ControlChangeInForce
				
				
				BodyGyro.maxTorque = BodyGyro.maxTorque * ChangeInForce
				ChangeInRotationOnSinkX = ChangeInRotationOnSinkX * 0.99
				ChangeInRotationOnSinkZ = ChangeInRotationOnSinkZ * 0.99
				PhysicsManager.RotateGyro = PhysicsManager.RotateGyro * CFrame.Angles(ChangeInRotationOnSinkX, 0, ChangeInRotationOnSinkZ)
				wait()
			end
		end)
	end
	
	function PhysicsManager:Destroy()
		PhysicsManager.Active = false
		
		BodyAngularVelocity:Destroy()
		BodyGyro:Destroy()
		BodyVelocity:Destroy()
		BodyPosition:Destroy()
		CenterPart:Destroy()
	end
end

SeatManager = {} do
	SeatManager.PlayerChanged = Signal.new()
	
	local ControlEndedEvent = WaitForChild(script, "ControlEnded");
	local qShipManagerLocal = WaitForChild(script, "qShipManagerLocal")
	SeatManager.Seat = Seat
	
	local ActivePlayerData
	
	function SeatManager:GetActivePlayer()
		return ActivePlayerData and ActivePlayerData.Player or nil
	end
	
	local function DeactivateActivePlayer()
		if ActivePlayerData then
			ActivePlayerData:Destroy()
			ActivePlayerData = nil
		end
	end
	
	function SeatManager:GetActivePlayer()
		if ActivePlayerData then
			return ActivePlayerData.Player
		else
			return nil
		end
	end
	
	local function HandleNewPlayer(Weld, Player)
		BoatModel.Parent = workspace
		SeatManager.PlayerChanged:fire()
		DeactivateActivePlayer()
		
		local NewData = {}
		NewData.Player = Player
		NewData.Weld = Weld
		
		local Script = qShipManagerLocal:Clone()
		Script.Archivable = false;
		
		local Maid = MakeMaid()
		NewData.Maid = Maid


		Make("ObjectValue", {
			Name = "ParentScript";
			Value = script;
			Archivable = false;
			Parent = Script;
		})
		NewData.Script = Script
		
		Maid:GiveTask(function()
			if Player:IsDescendantOf(game) then
				ControlEndedEvent:FireClient(Player)
				Script.Name = "_DeadScript";--]]
			end
		end)--]]
		
		Script.Parent = Player.PlayerGui
		Script.Disabled = false
		
		print("New player -", Player)

		function NewData:Destroy()
			Maid:DoCleaning()
			Maid = nil
		end
		
		ActivePlayerData = NewData
	end
	
	Seat.ChildAdded:connect(function(Weld)
		if Weld:IsA("Weld") then
			local Torso = Weld.Part1
			
			if Torso then
				local Character, Player = GetCharacter(Torso)
				if Player and CheckCharacter(Player) and Character.Humanoid.Health > 0 then
					HandleNewPlayer(Weld, Player)
				end
			end
		end
	end)
	
	Seat.ChildRemoved:connect(function(Child)
		if ActivePlayerData and ActivePlayerData.Weld == Child then
			DeactivateActivePlayer()
			SeatManager.PlayerChanged:fire()
		end
	end)
end

ControlManager = {} do
	ControlManager.Active = true
	local MoveEvent = WaitForChild(script, "Move");
	local StopEvent = WaitForChild(script, "Stop");
	local Forwards
	local Turn
	
	local Updating = false
	local UpdateCoroutine = coroutine.create(function()
		while ControlManager.Active do
			local Delta = wait()
			while (Forwards or Turn) and SeatManager:GetActivePlayer() do
				--[[if Forwards then
					PhysicsManager:Forwards(Delta, Forwards)
				else
					PhysicsManager:Forwards(Delta, nil)
				end
				
				if Turn then
					PhysicsManager:Turn(Delta, Turn)
				else
					PhysicsManager:Turn(Delta, Turn)
				end--]]
				PhysicsManager:ControlUpdate(Forwards, Turn)
				
				Delta = wait()
			end
			
			PhysicsManager:StopControlUpdate()
			
			Updating = false
			coroutine.yield()
		end
	end)
	assert(coroutine.resume(UpdateCoroutine))
	
	local function StartUpdate()
		if not Updating and ControlManager.Active then
			Updating = true
			assert(coroutine.resume(UpdateCoroutine))
		end
	end
	
	MoveEvent.OnServerEvent:connect(function(Client, Type)
		if Client == SeatManager:GetActivePlayer() then
			if Type == "Forwards" then
				Forwards = 1
			elseif Type == "Backwards" then
				Forwards = -1
			elseif Type == "Left" then
				Turn = 1
			elseif Type == "Right" then
				Turn = -1
			else
				warn("Unable to handle move event with type `" .. tostring(Type) .. "`")
			end
		else
			warn("Invalid client, cannot move")
		end
	end)
	
	StopEvent.OnServerEvent:connect(function(Client, Type)
		if Client == SeatManager:GetActivePlayer() then
			if Type == "Forwards" or Type == "Backwards" then
				Forwards = nil
			elseif Type == "Left" or Type == "Right" then
				Turn = nil
			else
				warn("Unable to handle move event with type `" .. tostring(Type) .. "`")
			end
		else
			warn("Invalid client, cannot move")
		end
	end)
	
	function ControlManager:Destroy()
		ControlManager.Active = false
	end
end

local WeldManager = {} do
	local Parts = GetBricks(BoatModel)
	WeldParts(Parts, PhysicsManager.CenterPart, "ManualWeld")
end

-- Created by Quenty

