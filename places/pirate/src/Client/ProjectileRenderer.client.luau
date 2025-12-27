-- ProjectileRenderer: 클라이언트에서 투사체를 부드럽게 렌더링
-- 서버는 판정만 담당하고, 시각적 렌더링은 클라이언트에서 처리

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local throwingBarrelEvent = ReplicatedStorage:WaitForChild("ThrowingBarrelEvent")

-- 투사체 렌더링 함수
local function renderProjectile(barrelPart, x0, v0, g, flightTime)
	-- 서버에서 보낸 barrelPart를 복제하여 클라이언트 전용 시각 효과 생성
	if not barrelPart or not barrelPart:IsA("BasePart") then
		return
	end

	-- 클라이언트 전용 투사체 생성
	local visualProjectile = barrelPart:Clone()
	visualProjectile.Name = "ClientProjectile"
	visualProjectile.CanCollide = false
	visualProjectile.CanTouch = false
	visualProjectile.CanQuery = false
	visualProjectile.Anchored = true
	visualProjectile.Transparency = 0  -- 서버에서 투명 처리된 것을 복원
	visualProjectile.Position = x0
	visualProjectile.Parent = workspace

	-- 회전 애니메이션 변수
	local rotationAngleX, rotationAngleY, rotationAngleZ = 0, 0, 0
	local random = math.random(0, 1)
	local randomRotationPower = Random.new():NextNumber(0.05, 0.15)
	local randomRotationPowerZ = Random.new():NextNumber(0.05, 0.15)

	local startTime = tick()
	local maxTime = flightTime * 2  -- 최대 비행 시간

	-- RenderStepped으로 부드러운 렌더링
	local connection
	connection = RunService.RenderStepped:Connect(function(deltaTime)
		local elapsedTime = tick() - startTime

		-- 시간 초과 또는 투사체 제거됨
		if elapsedTime > maxTime or not barrelPart or not barrelPart.Parent then
			if visualProjectile and visualProjectile.Parent then
				visualProjectile:Destroy()
			end
			connection:Disconnect()
			return
		end

		-- 포물선 위치 계산
		local position = 0.5 * g * elapsedTime * elapsedTime + v0 * elapsedTime + x0

		-- 회전 애니메이션
		if random == 0 then
			rotationAngleX = rotationAngleX + randomRotationPower
			rotationAngleZ = rotationAngleZ + randomRotationPowerZ
		else
			rotationAngleY = rotationAngleY + randomRotationPower
			rotationAngleZ = rotationAngleZ + randomRotationPowerZ
		end

		-- CFrame 업데이트 (위치 + 회전)
		visualProjectile.CFrame = CFrame.new(position) * CFrame.Angles(rotationAngleX, rotationAngleY, rotationAngleZ)
	end)
end

-- 서버에서 투사체 이벤트 수신
throwingBarrelEvent.OnClientEvent:Connect(function(barrelPart, x0, v0, g, flightTime)
	renderProjectile(barrelPart, x0, v0, g, flightTime)
end)
