local fire = Instance.new("Fire",script.Parent)
local smoke = Instance.new("Smoke", script.Parent)
smoke.Color = Color3.new(0,0,0)
smoke.Opacity = 0.2
smoke.RiseVelocity = 5
smoke.Size = 0.1
smoke.Parent = fire.Parent
fire.Size = math.abs(script.Parent.Size.X) + math.abs(script.Parent.Size.Y) + math.abs(script.Parent.Size.Z)
wait(0.15)
script.Parent.Material = Enum.Material.CorrodedMetal
script.Parent:BreakJoints()
local DummyPart = Instance.new("Part",workspace)
DummyPart.Size = Vector3.new(10,10,10)
DummyPart.Transparency = 1
DummyPart.Shape = Enum.PartType.Ball
DummyPart.Position = script.Parent.Position
for _,SpreadPart in pairs(DummyPart:GetTouchingParts()) do
	if SpreadPart.Name == "Baseplate" then
		continue
	end
	if SpreadPart:FindFirstChild("FireSpread") == nil then
		script:Clone().Parent = SpreadPart
	end
end
DummyPart:Destroy()
wait(5)
fire:Destroy()
smoke:Destroy()

local Debris = game:GetService("Debris")
if #(script.Parent.Parent:GetChildren()) == 1  then	
	Debris:AddItem(script.Parent.Parent, 0.2)
else
	script.Parent:Destroy()
end