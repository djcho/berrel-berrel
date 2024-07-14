local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

-- Created by Quenty


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

local ParentScriptValue = WaitForChild(script, "ParentScript");
local ShipManager = ParentScriptValue.Value

local LocalPlayer = Players.LocalPlayer

while not ShipManager do
	warn("Looking for ship manager")
	ShipManager = ParentScriptValue.Value
	wait()
end

local ControlEndedEvent = WaitForChild(ShipManager, "ControlEnded");
local MoveEvent = WaitForChild(ShipManager, "Move");
local StopEvent = WaitForChild(ShipManager, "Stop");

local KeysDown = {}

UserInputService.InputBegan:connect(function(Input)
	local KeyCodeName = Input.KeyCode.Name
	
	if KeyCodeName == "W" then
		MoveEvent:FireServer("Forwards")
	elseif KeyCodeName == "S" then
		MoveEvent:FireServer("Backwards")
	elseif KeyCodeName == "A" then
		MoveEvent:FireServer("Left")
	elseif KeyCodeName == "D" then
		MoveEvent:FireServer("Right")
	end
	
	if KeyCodeName ~= "Unknown" then
		KeysDown[KeyCodeName] = true
	end
end)

UserInputService.InputEnded:connect(function(Input)
	local KeyCodeName = Input.KeyCode.Name	
	
	if KeyCodeName == "W" then
		if KeysDown["S"] then
			MoveEvent:FireServer("Backwards")
		else
			StopEvent:FireServer("Forwards")
		end
	elseif KeyCodeName == "S" then
		if KeysDown["W"] then
			MoveEvent:FireServer("Forwards")
		else
			StopEvent:FireServer("Backwards")
		end
	elseif KeyCodeName == "A" then
		if KeysDown["D"] then
			MoveEvent:FireServer("Right")
		else
			StopEvent:FireServer("Left")
		end
	elseif KeyCodeName == "D" then
		if KeysDown["A"] then
			MoveEvent:FireServer("Left")
		else
			StopEvent:FireServer("Right")
		end
	end
	
	if KeyCodeName ~= "Unknown" then
		KeysDown[KeyCodeName] = nil
	end
end)