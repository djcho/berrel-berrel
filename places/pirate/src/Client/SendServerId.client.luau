local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local isStudio = RunService:IsStudio()

-- 텔레포트 데이터 초기화
local teleportData = TeleportService:GetLocalPlayerTeleportData()
local serverId, roomId, placeId

if isStudio then
	-- 스튜디오 환경에서는 Mock 데이터 사용
	print("[Studio Mode] 텔레포트 데이터 Mock 사용")
	local jobId = game.JobId
	serverId = "mock_server_id_" .. (jobId ~= "" and jobId or "studio")
	roomId = "mock_room_id_studio"
	placeId = game.PlaceId
else
	-- 프로덕션 환경에서는 실제 텔레포트 데이터 사용
	serverId = teleportData.serverId
	roomId = teleportData.roomId
	placeId = teleportData.placeId
end

-- 서버 ID, roomId, placeId 출력하여 확인
print("서버 ID:", serverId)
print("게임방 ID:", roomId)
print("장소 ID:", placeId)

-- 서버로 서버 ID, roomId, placeId 전달
ReplicatedStorage:WaitForChild("ServerIdEvent"):FireServer(serverId, roomId, placeId)
