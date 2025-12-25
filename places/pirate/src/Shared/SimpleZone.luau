--[[
	SimpleZone: Zone 라이브러리의 경량화 버전

	사용법:
	local SimpleZone = require(path.to.SimpleZone)
	local zone = SimpleZone.fromRegion(cframe, size)
	zone.playerEntered:Connect(function(player) ... end)
	zone.playerExited:Connect(function(player) ... end)
	zone:destroy()
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- 간단한 Signal 구현
local Signal = {}
Signal.__index = Signal

function Signal.new()
	local self = setmetatable({}, Signal)
	self._connections = {}
	return self
end

function Signal:Connect(callback)
	local connection = {
		_callback = callback,
		_connected = true,
		Disconnect = function(conn)
			conn._connected = false
			for i, c in ipairs(self._connections) do
				if c == conn then
					table.remove(self._connections, i)
					break
				end
			end
		end
	}
	table.insert(self._connections, connection)
	return connection
end

function Signal:Fire(...)
	for _, connection in ipairs(self._connections) do
		if connection._connected then
			task.spawn(connection._callback, ...)
		end
	end
end

function Signal:Destroy()
	self._connections = {}
end

-- SimpleZone 클래스
local SimpleZone = {}
SimpleZone.__index = SimpleZone

function SimpleZone.fromRegion(cframe: CFrame, size: Vector3)
	local self = setmetatable({}, SimpleZone)

	self._cframe = cframe
	self._size = size
	self._halfSize = size / 2
	self._playersInZone = {}
	self._destroyed = false

	-- 이벤트
	self.playerEntered = Signal.new()
	self.playerExited = Signal.new()

	-- 체크 루프 시작
	self._heartbeatConnection = RunService.Heartbeat:Connect(function()
		self:_checkPlayers()
	end)

	return self
end

function SimpleZone:_isPointInZone(point: Vector3): boolean
	-- CFrame 기준 로컬 좌표로 변환
	local localPoint = self._cframe:PointToObjectSpace(point)

	-- 박스 내부인지 체크
	return math.abs(localPoint.X) <= self._halfSize.X
		and math.abs(localPoint.Y) <= self._halfSize.Y
		and math.abs(localPoint.Z) <= self._halfSize.Z
end

function SimpleZone:_checkPlayers()
	if self._destroyed then return end

	local currentPlayers = {}

	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		if character then
			local hrp = character:FindFirstChild("HumanoidRootPart")
			if hrp then
				local inZone = self:_isPointInZone(hrp.Position)
				currentPlayers[player] = inZone

				if inZone and not self._playersInZone[player] then
					-- 새로 들어옴
					self._playersInZone[player] = true
					self.playerEntered:Fire(player)
				elseif not inZone and self._playersInZone[player] then
					-- 나감
					self._playersInZone[player] = nil
					self.playerExited:Fire(player)
				end
			end
		end
	end

	-- 나간 플레이어 처리 (캐릭터가 없어진 경우)
	for player in pairs(self._playersInZone) do
		if not currentPlayers[player] then
			self._playersInZone[player] = nil
			self.playerExited:Fire(player)
		end
	end
end

function SimpleZone:destroy()
	self._destroyed = true
	if self._heartbeatConnection then
		self._heartbeatConnection:Disconnect()
		self._heartbeatConnection = nil
	end
	self.playerEntered:Destroy()
	self.playerExited:Destroy()
	self._playersInZone = {}
end

return SimpleZone
