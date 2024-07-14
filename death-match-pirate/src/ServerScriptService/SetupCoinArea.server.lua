local ServerStorage = game:GetService("ServerStorage")
local coinPart = ServerStorage.Parts.Coin
local CoinGenerator = require(ServerStorage.Classes:WaitForChild("CoinGenerator"))

spawn(function()
	local coinGenerator = CoinGenerator.new(
		Vector3.new(96.506, 45.994, -79.648), 
		Vector3.new(116.391, 45.994, -79.631),
		Vector3.new(96.609, 45.994, 60.133), 
		Vector3.new(117.997, 45.994, 60.289), math.random(5,10), 6, coinPart)
	coinGenerator:Generate()
end)

spawn(function()
	local coinGenerator2 = CoinGenerator.new(
		Vector3.new(121.482, 45.994, 60.216), 
		Vector3.new(121.337, 45.994, 39.081),
		Vector3.new(267.025, 45.994, 40.288), 
		Vector3.new(265.35, 45.994, 60.498), math.random(5,10), 10, coinPart)
	coinGenerator2:Generate()
end)	

spawn(function()
	local coinGenerator3 = CoinGenerator.new(
		Vector3.new(245.519, 45.994, 35.384), 
		Vector3.new(266.931, 45.994, 35.973),
		Vector3.new(245.188, 45.994, -31.269), 
		Vector3.new(265.507, 45.994, -8.509), math.random(5,10), 3, coinPart)
	coinGenerator3:Generate()
end)

---------------------------------------------------

spawn(function()
	local coinGenerator = CoinGenerator.new(
		Vector3.new(190.104, 45.994, -27.889), 
		Vector3.new(169.617, 45.994, -27.842),
		Vector3.new(168.229, 45.994, -168.272), 
		Vector3.new(189.914, 45.994, -167.833), math.random(5,10), 6, coinPart)
	coinGenerator:Generate()
end)

spawn(function()
	local coinGenerator2 = CoinGenerator.new(
		Vector3.new(164.786, 45.994, -146.497), 
		Vector3.new(164.743, 45.994, -167.719),
		Vector3.new(19.448, 45.994, -146.284), 
		Vector3.new(21.222, 45.994, -167.937), math.random(5,10), 10, coinPart)
	coinGenerator2:Generate()
end)	

spawn(function()
	local coinGenerator3 = CoinGenerator.new(
		Vector3.new(41.481, 45.994, -143.13), 
		Vector3.new(19.23, 45.994, -143.213),
		Vector3.new(41.463, 45.994, -76.903), 
		Vector3.new(21.443, 45.994, -101.357), math.random(5,10), 3, coinPart)
	coinGenerator3:Generate()
end)



