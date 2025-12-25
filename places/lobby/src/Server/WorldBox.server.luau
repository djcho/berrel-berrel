local baseSize = Vector3.new(2048, 16, 2048)
local wallHeight = 500
local basePosition = Vector3.new(0, -8, 0)

-- Create walls
local function createWall(position, size)
	local wall = Instance.new("Part")
	wall.Size = size
	wall.Position = position
	wall.Anchored = true
	wall.Transparency = 1
	wall.CanCollide = true
	wall.Parent = game.Workspace
end

-- Bottom wall
createWall(basePosition + Vector3.new(0, wallHeight / 2, -baseSize.Z / 2), Vector3.new(baseSize.X, wallHeight, 1))

-- Top wall
createWall(basePosition + Vector3.new(0, wallHeight / 2, baseSize.Z / 2), Vector3.new(baseSize.X, wallHeight, 1))

-- Left wall
createWall(basePosition + Vector3.new(-baseSize.X / 2, wallHeight / 2, 0), Vector3.new(1, wallHeight, baseSize.Z))

-- Right wall
createWall(basePosition + Vector3.new(baseSize.X / 2, wallHeight / 2, 0), Vector3.new(1, wallHeight, baseSize.Z))
