if(script.Parent.Name == "Part") then
	return
end

local ServerStorage = game:GetService("ServerStorage")
local CommonUtil = require(ServerStorage.Scripts.CommonUtil)

local burningEndFlag = false
local function Burning()
	while not burningEndFlag do			
		local DummyPart = Instance.new("Part", workspace)		
		DummyPart.Size = Vector3.new(20, 20, 20)
		DummyPart.Transparency = 1
		DummyPart.Shape = Enum.PartType.Ball
		DummyPart.Position = script.Parent.Position

		for _, SpreadPart in pairs(DummyPart:GetTouchingParts()) do
			if CommonUtil:IsPartIncludedCharacter(SpreadPart) then
				if not SpreadPart.Parent:FindFirstChild("FireSpread", true) then
					local newScript = script:Clone()
					newScript.Parent = SpreadPart
					newScript.Disabled = false

					-- 사라지는 시간을 초기화하는 처리 추가
					local modelDestroyer = SpreadPart.Parent:FindFirstChild("ModelDestroyer")
					if modelDestroyer and modelDestroyer.Configuration and modelDestroyer.Configuration.WaitTime then
						modelDestroyer.Configuration.WaitTime.Value = 10 -- 사라지는 시간을 10초로 초기화
					end
				end
			end
			if SpreadPart:FindFirstChild("burnable") then				
				if not SpreadPart:FindFirstChild("FireSpread") then
					
					local newScript = script:Clone()
					newScript.Parent = SpreadPart
					newScript.Disabled = false

					-- 사라지는 시간을 초기화하는 처리 추가
					local modelDestroyer = SpreadPart.Parent:FindFirstChild("ModelDestroyer")
					if modelDestroyer and modelDestroyer.Configuration and modelDestroyer.Configuration.WaitTime then
						modelDestroyer.Configuration.WaitTime.Value = 10 -- 사라지는 시간을 10초로 초기화
					end
				end
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

	if tickDamage == nil or tickDamage <= 0 then
		tickDamage = 3
	end

	for i = 1, 4 do
		humanoid:TakeDamage(tickDamage)
		wait(1)
	end
end

local fire = Instance.new("Fire", script.Parent)
local smoke = Instance.new("Smoke", script.Parent)
smoke.Color = Color3.new(0, 0, 0)
smoke.Opacity = 0.03
smoke.RiseVelocity = 5
smoke.Size = 0.1
smoke.Parent = fire.Parent
if CommonUtil:IsPartIncludedCharacter(script.Parent) then
	fire.Size = 5
else
	local originalSize = script.Parent:GetAttribute("OriginalSize");
	fire.Size = math.abs(originalSize.X) + math.abs(originalSize.Y) + math.abs(originalSize.Z)
end

wait(0.15)

spawn(Burning)

if script.Parent.Parent.Name:match("Oil") then
	-- 사라지는 시간을 초기화하는 처리 추가
	local modelDestroyer = script.Parent.Parent:FindFirstChild("ModelDestroyer")
	if modelDestroyer and modelDestroyer.Configuration and modelDestroyer.Configuration.WaitTime then
		modelDestroyer.Configuration.WaitTime.Value = 10 -- 사라지는 시간을 10초로 초기화
	end

	wait(10)
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

	if oilPartCount == 1 then
		Debris:AddItem(script.Parent.Parent, 0.2)
	else
		script.Parent:Destroy()
	end
	burningEndFlag = true
elseif CommonUtil:IsPartIncludedCharacter(script) then
	local humanoid = CommonUtil:GetHumanoidByPart(script)
	spawn(function()
		local ItemDbTools = require(ServerStorage.Items.Database.ItemDb).Tool
		local ItemInfo = ItemDbTools["FireBarrel"]
		
		
		TakeDotDamage(humanoid, ItemInfo.DotDamage)
	end)
	wait(4)
	burningEndFlag = true
	fire:Destroy()
	smoke:Destroy()
	script:Destroy()
	return
end
