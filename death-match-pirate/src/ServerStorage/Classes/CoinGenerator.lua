local DEFAULT_GEN_TIME = 1
local DEFAULT_MAX_COIN_COUNT = 20

local CoinGenerator = {}
CoinGenerator.__index = CoinGenerator

function CoinGenerator.new(position1, position2, position3, position4, genTime, maxCoin, coinPart)
	local self = setmetatable({}, CoinGenerator)
	
	self.Position1 = position1
	self.Position2 = position2
	self.Position3 = position3
	self.Position4 = position4
	self.GenTime = genTime or DEFAULT_GEN_TIME
	self.MaxCoin = maxCoin or DEFAULT_MAX_COIN_COUNT	
	self.Coin = coinPart
	
	return self
end

function CoinGenerator:CreateCoinArea(position1, position2, position3, position4)
	local area = Instance.new("Model")
	
	local pin1 = Instance.new("Part")
	pin1.Transparency = 1
	pin1.Anchored = true
	pin1.Size = Vector3.new(1,1,1)
	pin1.Position = self.Position1
	pin1.Parent = area
	
	local pin2 = Instance.new("Part")
	pin2.Transparency = 1
	pin2.Anchored = true
	pin2.Size = Vector3.new(1,1,1)
	pin2.Position = self.Position2
	pin2.Parent = area
	
	local pin3 = Instance.new("Part")
	pin3.Transparency = 1
	pin3.Anchored = true
	pin3.Size = Vector3.new(1,1,1)
	pin3.Position = self.Position3
	pin3.Parent = area
	
	local pin4 = Instance.new("Part")
	pin4.Transparency = 1
	pin4.Anchored = true
	pin4.Size = Vector3.new(1,1,1)
	pin4.Position = self.Position4
	pin4.Parent = area
	
	area.Parent = workspace
	
	return area
end

function CoinGenerator:GetCoinCount(area)	
	return #(area:GetChildren()) - 4 
end

function CoinGenerator:Generate()
	local coinCounter = 0	
	local area = self:CreateCoinArea()
	while task.wait(self.GenTime) do		
		if self:GetCoinCount(area) >= self.MaxCoin then
			continue
		end
		
		local randomsXmin = math.min(self.Position1.X, self.Position2.X, self.Position3.X, self.Position4.X)
		local randomsXmax = math.max(self.Position1.X, self.Position2.X, self.Position3.X, self.Position4.X)
		local randomsZmin = math.min(self.Position1.Z, self.Position2.Z, self.Position3.Z, self.Position4.Z)
		local randomsZmax = math.max(self.Position1.Z, self.Position2.Z, self.Position3.Z, self.Position4.Z)
		
		local coinclone = self.Coin:Clone()
		local randomsX = math.random(randomsXmin, randomsXmax)
		local randomsZ = math.random(randomsZmin, randomsZmax)	
		
		local offsetY = 3
		coinclone.Position = Vector3.new(randomsX, ((self.Position1.Y + self.Position2.Y)/2) + offsetY , randomsZ)
		coinclone.Parent = area
	end
end

return CoinGenerator
