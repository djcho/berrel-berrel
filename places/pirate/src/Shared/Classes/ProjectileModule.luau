-- ReplicatedStorage/ProjectileModule
local ProjectileModule = {}

-- 상수
ProjectileModule.DAMAGE = 18
ProjectileModule.FIRE_RATE = 1 / 5.5
ProjectileModule.RANGE = 350
ProjectileModule.MAX_SPREAD = 0.07
ProjectileModule.CLIP_SIZE = 7
ProjectileModule.RELOAD_TIME = 2.1
ProjectileModule.MAX_DISTANCE = 200
ProjectileModule.GRAVITY_SCALE = 0.5
ProjectileModule.TIME_DIVISOR = 100
ProjectileModule.LAUNCH_DISTANCE = 2

local ReplicatedStorage = game:GetService("ReplicatedStorage")
ProjectileModule.throwingBarrelEvent = ReplicatedStorage:WaitForChild("ThrowingBarrelEvent")

-- 부착물 및 빔 생성 함수
function ProjectileModule.createBeam()
	local attach0 = Instance.new("Attachment", game.Workspace.Terrain)
	local attach1 = Instance.new("Attachment", game.Workspace.Terrain)
	local beam = Instance.new("Beam", game.Workspace.Terrain)
	beam.Attachment0 = attach0
	beam.Attachment1 = attach1
	return beam, attach0, attach1
end

-- 포물선 경로 계산 함수
function ProjectileModule.calculateBeamPath(g, v0, x0, t1)
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

-- 발사 위치 계산 함수
function ProjectileModule.getLaunchPosition(hrp, mousePosition)
	local x0 = hrp.Position + Vector3.new(0, 2, 0)
	local direction = (mousePosition - x0).unit
	return x0 + direction * ProjectileModule.LAUNCH_DISTANCE
end

-- 투사체 회전 애니메이션 함수
function ProjectileModule.handleProjectileRotation(projectile, x0, v0, g, t)
	local rotationAngleX, rotationAngleY, rotationAngleZ = 0, 0, 0
	local random = math.random(0, 1)
	local randomRotationPower = Random.new():NextNumber(0, 0.2)
	local randomRotationPowerZ = Random.new():NextNumber(0, 0.2)

	local nt = 0
	local connection
	connection = game:GetService("RunService").RenderStepped:Connect(function()
		if nt > t * 2 then
			projectile:Destroy()
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
		projectile.CFrame = projectile.CFrame * CFrame.Angles(rotationAngleX, rotationAngleY, rotationAngleZ)
		nt = nt + game:GetService("RunService").RenderStepped:Wait()
	end)
end

return ProjectileModule
