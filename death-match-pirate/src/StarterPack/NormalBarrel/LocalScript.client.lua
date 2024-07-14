-- FireProjectile (LocalScript)
-- 상수
local MAX_DISTANCE = 200

-- 추가 상수
local GRAVITY_SCALE = 0.5  -- 중력 스케일
local TIME_DIVISOR = 100  -- 시간 계산을 위한 나눗셈 값

-- 변수
local Tool = script.Parent
local IsShooting = false
local MyPlayer, MyCharacter, MyHumanoid, MyTorso, MyMouse, hrp = nil
local mouseDownTime = 0  -- 마우스 누른 시작 시간
local isMouseDown = false  -- 마우스가 눌린 상태인지 여부
local isCanceled = false  -- 차징 취소 상태

-- 서비스
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local fireProjectileEvent = ReplicatedStorage:WaitForChild("FireProjectileEvent")

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

local function renderBeam()
	if not isMouseDown then
		beam.Enabled = false  -- 빔 비활성화
		return
	end  -- 마우스가 눌린 상태일 때만 실행
	local currentTime = tick()
	local duration = currentTime - mouseDownTime
	local distance = math.min(duration * TIME_DIVISOR, MAX_DISTANCE)

	local g = Vector3.new(0, -game.Workspace.Gravity * GRAVITY_SCALE, 0)  -- 수정된 중력
	local x0 = hrp.CFrame.Position + Vector3.new(0, 2, -2)
	local targetPosition = x0 + (MyMouse.Hit.p - x0).unit * distance
	local t = distance / TIME_DIVISOR  -- 수정된 시간 계산
	local v0 = (targetPosition - x0 - 0.5 * g * t * t) / t

	local curve0, curve1, cf1, cf2 = calculateBeamPath(g, v0, x0, t)
	beam.CurveSize0 = curve0
	beam.CurveSize1 = curve1
	attach0.CFrame = attach0.Parent.CFrame:inverse() * cf1
	attach1.CFrame = attach1.Parent.CFrame:inverse() * cf2
	beam.Enabled = true  -- 빔 활성화
end

local function fireProjectile()
	if IsShooting or isCanceled then return end
	if MyHumanoid and MyHumanoid.Health > 0 then
		if not MyCharacter then return end

		local handle = Tool:WaitForChild("Handle")
		local currentTime = tick()
		local duration = currentTime - mouseDownTime
		local distance = math.min(duration * TIME_DIVISOR, MAX_DISTANCE)

		local x0 = hrp.CFrame.Position + Vector3.new(0, 2, -2)
		local targetPosition = x0 + (MyMouse.Hit.p - x0).unit * distance

		-- 서버로 이벤트 전송
		fireProjectileEvent:FireServer(handle, targetPosition)
		beam.Enabled = false  -- 발사 후 빔 비활성화
	end
end

local function cancelCharging()
	isMouseDown = false  -- 마우스가 떼어진 상태로 설정
	isCanceled = true  -- 차징 취소 상태로 설정
	beam.Enabled = false  -- 빔 비활성화
	print("Charging canceled")
end

local function onMouseDown()
	mouseDownTime = tick()  -- 마우스 누른 시작 시간 기록
	isMouseDown = true  -- 마우스가 눌린 상태로 설정
	isCanceled = false  -- 차징 취소 상태 초기화
end

local function onMouseUp()
	if isCanceled then
		isCanceled = false  -- 차징 취소 상태 초기화
		return
	end
	isMouseDown = false  -- 마우스가 떼어진 상태로 설정
	fireProjectile()
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
		MyMouse.Button2Down:Connect(cancelCharging)  -- 우클릭 이벤트 처리
		RunService.RenderStepped:Connect(renderBeam)
	end
end

local function onUnequipped()
	-- 도구가 해제될 때 실행할 코드 추가
end

-- 리모트 이벤트 수신 및 투사체 렌더링
fireProjectileEvent.OnClientEvent:Connect(function(bball, x0, v0, g, t)
	local rotationAngleX, rotationAngleY, rotationAngleZ = 0, 0, 0
	local random = math.random(0, 1)
	local randomRotationPower = Random.new():NextNumber(0, 0.2)
	local randomRotationPowerZ = Random.new():NextNumber(0, 0.2)

	local nt = 0
	local connection
	connection = RunService.RenderStepped:Connect(function()
		if nt > t * 2 then
			bball:Destroy()
			connection:Disconnect()
			return
		end
		if random == 0 then
			rotationAngleX = rotationAngleX + randomRotationPower
			rotationAngleZ = rotationAngleZ + randomRotationPowerZ
		else
			rotationAngleY = rotationAngleY + randomRotationPower
			rotationAngleZ = rotationAngleZ + randomRotationPowerZ
		end
		bball.CFrame = CFrame.new(0.5 * g * nt * nt + v0 * nt + x0) * CFrame.Angles(rotationAngleX, rotationAngleY, rotationAngleZ)
		nt = nt + RunService.RenderStepped:Wait()
	end)
end)

Tool.Equipped:Connect(onEquipped)
Tool.Unequipped:Connect(onUnequipped)
