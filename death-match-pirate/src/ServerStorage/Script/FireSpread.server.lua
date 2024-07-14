local ServerStorage = game:GetService("ServerStorage")
local CommonUtil = require(ServerStorage.Classes.CommonUtil)

local burningEndFlag = false
local function Burning()
	while not burningEndFlag do	
		local DummyPart = Instance.new("Part",workspace)
		DummyPart.Size = Vector3.new(10,10,10)
		DummyPart.Transparency = 0
		DummyPart.Shape = Enum.PartType.Ball
		DummyPart.Position = script.Parent.Position

		for _,SpreadPart in pairs(DummyPart:GetTouchingParts()) do
			if CommonUtil:IsPartIncludedCharacter(SpreadPart) then
				if not SpreadPart.Parent:FindFirstChild("FireSpread", true) then
					script:Clone().Parent = SpreadPart
				end
			end
			if SpreadPart:FindFirstChild("burnable") then
				if SpreadPart:FindFirstChild("FireSpread") then
					continue
				end
				script:Clone().Parent = SpreadPart
			end
		end
		
		DummyPart:Destroy()
		wait()
	end
end

local function TakeDotDamage(humanoid, tickDamage)
	if not humanoid then
		return
	end

	if tickDamage == nil or tickDamage <= 0  then
		tickDamage = 3
	end

	for i = 1, 4 do
		humanoid:TakeDamage(tickDamage)
		wait(1)
	end
end

local fire = Instance.new("Fire",script.Parent)
local smoke = Instance.new("Smoke", script.Parent)
smoke.Color = Color3.new(0,0,0)
smoke.Opacity = 0.2
smoke.RiseVelocity = 5
smoke.Size = 0.1
smoke.Parent = fire.Parent
if CommonUtil:IsPartIncludedCharacter(script.Parent) then
	fire.Size = 5
else
	fire.Size = math.abs(script.Parent.Size.X) + math.abs(script.Parent.Size.Y) + math.abs(script.Parent.Size.Z)
end

wait(0.15)

spawn(Burning)

if script.Parent.Parent.Name:match("Oil") then
	wait(5)
	fire:Destroy()
	smoke:Destroy()

	script.Parent.Material = Enum.Material.CorrodedMetal
	script.Parent:BreakJoints()
	
	local Debris = game:GetService("Debris")

	local oilPartCount = 0
	for _, v in pairs(script.Parent.Parent:GetChildren()) do
		if v.Name == "OilPart" then
			oilPartCount += 1
		end
	end

	if oilPartCount == 1  then
		Debris:AddItem(script.Parent.Parent, 0.2)
	else
		script.Parent:Destroy()
	end
	burningEndFlag = true
elseif CommonUtil:IsPartIncludedCharacter(script) then
	local humanoid = CommonUtil:GetHumanoidByPart(script)
	spawn(function()
		TakeDotDamage(humanoid, 5)
	end)
	wait(4)
	burningEndFlag = true
	fire:Destroy()
	smoke:Destroy()
	script:Destroy()
	return
end




--local ServerStorage = game:GetService("ServerStorage")
--local CommonUtil = require(ServerStorage.Classes.CommonUtil)


--local function TakeDotDamage(humanoid, tickDamage)
--	if not humanoid then
--		return
--	end
	
--	if tickDamage == nil or tickDamage <= 0  then
--		tickDamage = 3
--	end
	
--	for i = 1, 4 do
--		humanoid:TakeDamage(tickDamage)
--	end
--end

--local fire = Instance.new("Fire",script.Parent)
--local smoke = Instance.new("Smoke", script.Parent)
--smoke.Color = Color3.new(0,0,0)
--smoke.Opacity = 0.2
--smoke.RiseVelocity = 5
--smoke.Size = 0.1
--smoke.Parent = fire.Parent
--fire.Size = math.abs(script.Parent.Size.X) + math.abs(script.Parent.Size.Y) + math.abs(script.Parent.Size.Z)

--wait(5)

--local DummyPart = Instance.new("Part",workspace)
--DummyPart.Size = Vector3.new(10,10,10)
--DummyPart.Transparency = 1
--DummyPart.Shape = Enum.PartType.Ball
--DummyPart.Position = script.Parent.Position
--for _,SpreadPart in pairs(DummyPart:GetTouchingParts()) do
--	if (CommonUtil:IsPartIncludedCharacter(SpreadPart) or (SpreadPart.Parent and SpreadPart.Parent.Name:match("Oil"))) and SpreadPart:FindFirstChild("FireSpread") == nil then
--		script:Clone().Parent = SpreadPart
--	end
--end
--DummyPart:Destroy()



--if CommonUtil:IsPartIncludedCharacter(script) then
--	local humanoid = CommonUtil:GetHumanoidByPart(script)
--	spawn(function()
--		TakeDotDamage(humanoid, 3)
--	end)
--	fire:Destroy()
--	script:Destroy()
--else
--	script.Parent.Material = Enum.Material.CorrodedMetal
--	script.Parent:BreakJoints()	

--	fire:Destroy()
--	smoke:Destroy()

--	local Debris = game:GetService("Debris")
--	if #(script.Parent.Parent:GetChildren()) == 1  then	
--		Debris:AddItem(script.Parent.Parent, 0.2)
--	else
--		script.Parent:Destroy()
--	end
--end


