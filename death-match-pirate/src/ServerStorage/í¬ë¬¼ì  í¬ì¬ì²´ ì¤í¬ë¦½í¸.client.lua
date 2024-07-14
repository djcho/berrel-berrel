-- 상수
local DAMAGE = 18
local FIRE_RATE = 1 / 5.5
local RANGE = 350
local MAX_SPREAD = 0.07
local CLIP_SIZE = 7
local RELOAD_TIME = 2.1
local MAX_DISTANCE = 200

-- 추가 상수
local GRAVITY_SCALE = 0.5  -- 중력 스케일
local TIME_DIVISOR = 100  -- 시간 계산을 위한 나눗셈 값

-- 변수
local Tool = script.Parent
local IsShooting = false
local MyPlayer, MyCharacter, MyHumanoid, MyTorso, MyMouse, hrp = nil

-- 서비스
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local throwingBarrelEvent = ReplicatedStorage:WaitForChild("ThrowingBarrelEvent")

-- 부착물 및 빔
local attach0 = Instance.new("Attachment", game.Workspace.Terrain)
local attach1 = Instance.new("Attachment", game.Workspace.Terrain)
local beam = Instance.new("Beam", game.Workspace.Terrain)
beam.Attachment0 = attach0
beam.Attachment1 = attach1

-- 함수
local function calculateBeamPath(g, v0, x0, t1)
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

local function renderBeam(dt)
	local g = Vector3.new(0, -game.Workspace.Gravity * GRAVITY_SCALE, 0)  -- 수정된 중력
	local x0 = hrp.CFrame * Vector3.new(0, 2, -2)
	local targetPosition = MyMouse.Hit.p
	local distance = (targetPosition - x0).magnitude

	if distance > MAX_DISTANCE then
		distance = MAX_DISTANCE
		targetPosition = x0 + (MyMouse.Hit.p - x0).unit * MAX_DISTANCE
	end

	local t = distance / TIME_DIVISOR  -- 수정된 시간 계산
	local v0 = (targetPosition - x0 - 0.5 * g * t * t) / t

	local curve0, curve1, cf1, cf2 = calculateBeamPath(g, v0, x0, t)
	beam.CurveSize0 = curve0
	beam.CurveSize1 = curve1
	attach0.CFrame = attach0.Parent.CFrame:inverse() * cf1
	attach1.CFrame = attach1.Parent.CFrame:inverse() * cf2
end

local function fireProjectile()
	if IsShooting then return end
	if MyHumanoid and MyHumanoid.Health > 0 then
		if not MyCharacter then return end

		local bball = script.Parent:WaitForChild("Handle")
		local g = Vector3.new(0, -game.Workspace.Gravity * GRAVITY_SCALE, 0)  -- 수정된 중력
		local x0 = hrp.CFrame * Vector3.new(0, 2, -2)
		local targetPosition = MyMouse.Hit.p
		local distance = (targetPosition - x0).magnitude

		if distance > MAX_DISTANCE then
			distance = MAX_DISTANCE
			targetPosition = x0 + (MyMouse.Hit.p - x0).unit * MAX_DISTANCE
		end

		local t = distance / TIME_DIVISOR  -- 수정된 시간 계산
		local v0 = (targetPosition - x0 - 0.5 * g * t * t) / t
		local c = bball:Clone()
		c.CanCollide = true
		c.Anchored = true
		c.Parent = game.Workspace

		local rotationAngleX, rotationAngleY, rotationAngleZ = 0, 0, 0
		local random = math.random(0, 1)
		local randomRotationPower = Random.new():NextNumber(0, 0.2)
		local randomRotationPowerZ = Random.new():NextNumber(0, 0.2)

		local nt = 0
		while (nt < t * 2) do
			if random == 0 then
				rotationAngleX += randomRotationPower
				rotationAngleZ += randomRotationPowerZ
			else
				rotationAngleY += randomRotationPower
				rotationAngleZ += randomRotationPowerZ
			end
			c.CFrame = CFrame.new(0.5 * g * nt * nt + v0 * nt + x0) * CFrame.Angles(rotationAngleX, rotationAngleY, rotationAngleZ)
			nt = nt + RunService.RenderStepped:Wait()
		end
	end
end

local function onMouseDown()
	LeftButtonDown = true
	fireProjectile()
end

local function onMouseUp()
	LeftButtonDown = false
end

local function onEquipped(mouse)
	print("OnEquipped")
	MyCharacter = Tool.Parent
	MyPlayer = game:GetService('Players'):GetPlayerFromCharacter(MyCharacter)
	MyHumanoid = MyCharacter:FindFirstChild('Humanoid')
	hrp = MyCharacter:WaitForChild("HumanoidRootPart")
	MyTorso = MyCharacter:FindFirstChild('Torso')
	MyMouse = mouse

	if MyMouse then
		MyMouse.Button1Down:Connect(onMouseDown)
		MyMouse.Button1Up:Connect(onMouseUp)
		RunService.RenderStepped:Connect(renderBeam)
	end
end

local function onUnequipped()
	-- 도구가 해제될 때 실행할 코드 추가
end

-- 이벤트 연결
Tool.Equipped:Connect(onEquipped)
Tool.Unequipped:Connect(onUnequipped)
