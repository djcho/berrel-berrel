-- FireProjectileHandler (ServerScript)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local fireProjectileEvent = ReplicatedStorage:WaitForChild("FireProjectileEvent")

-- 이벤트 처리 함수
local function onFireProjectile(player, handle, targetPosition)
	local x0 = player.Character.HumanoidRootPart.Position + Vector3.new(0, 2, -2)
	local distance = (targetPosition - x0).magnitude
	local MAX_DISTANCE = 200
	local TIME_DIVISOR = 100
	local GRAVITY_SCALE = 0.5

	if distance > MAX_DISTANCE then
		distance = MAX_DISTANCE
		targetPosition = x0 + (targetPosition - x0).unit * MAX_DISTANCE
	end

	local t = distance / TIME_DIVISOR
	local g = Vector3.new(0, -game.Workspace.Gravity * GRAVITY_SCALE, 0)
	local v0 = (targetPosition - x0 - 0.5 * g * t * t) / t

	local bball = handle:Clone()  -- 기존 Handle 파트를 복제하여 사용
	bball.CanCollide = true
	bball.Anchored = false  -- 물리 이동을 가능하게 함
	bball.Parent = game.Workspace

	-- 클라이언트로 투사체 정보 전송
	fireProjectileEvent:FireAllClients(bball, x0, v0, g, t)
end

-- 리모트 이벤트 연결
fireProjectileEvent.OnServerEvent:Connect(onFireProjectile)
