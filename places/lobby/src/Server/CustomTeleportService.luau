local CustomTeleportService = {}
CustomTeleportService.__index = CustomTeleportService

-- 생성자
function CustomTeleportService.new()
	local self = setmetatable({}, CustomTeleportService)
	-- 필요한 초기화 작업
	return self
end

-- 플레이어를 지정된 장소로 텔레포트하는 메서드
-- @param player 텔레포트할 플레이어 객체
-- @param placeId 텔레포트할 대상 장소 ID
-- @param teleportData 추가 텔레포트 데이터 (옵션), serverId 포함
function CustomTeleportService:TeleportPlayer(player, placeId, teleportData)
	assert(player and placeId and teleportData, "Player, Place ID, and Teleport Data는 필수입니다.")

	local teleportOptions = Instance.new("TeleportOptions")
	teleportOptions:SetTeleportData(teleportData)

	local success, errorMessage = pcall(function()
		game:GetService("TeleportService"):TeleportAsync(placeId, {player}, teleportOptions)
	end)

	if not success then
		warn("플레이어 텔레포트 실패: " .. errorMessage)
	end
end

-- 여러 플레이어를 지정된 장소로 텔레포트하는 메서드
-- @param players 텔레포트할 플레이어 객체 리스트
-- @param placeId 텔레포트할 대상 장소 ID
-- @param teleportData 추가 텔레포트 데이터 (옵션), serverId 포함
function CustomTeleportService:TeleportPlayers(players, placeId, teleportData)
	assert(players and placeId and teleportData, "Players, Place ID, and Teleport Data는 필수입니다.")

	local teleportOptions = Instance.new("TeleportOptions")
	teleportOptions:SetTeleportData(teleportData)

	local success, errorMessage = pcall(function()
		game:GetService("TeleportService"):TeleportAsync(placeId, players, teleportOptions)
	end)

	if not success then
		warn("플레이어 텔레포트 실패: " .. errorMessage)
	end
end

-- 플레이어 캐릭터를 지정된 좌표로 이동시키는 메서드
-- @param player 위치를 이동시킬 플레이어 객체
-- @param position 목표 위치 벡터3 (Vector3)
function CustomTeleportService:TeleportPlayerToPosition(player, position)
	assert(player and position, "Player와 Position은 필수입니다.")

	local character = player.Character
	if character and character:FindFirstChild("HumanoidRootPart") then
		character.HumanoidRootPart.CFrame = CFrame.new(position)
	else
		warn("플레이어의 캐릭터나 HumanoidRootPart를 찾을 수 없습니다.")
	end
end

return CustomTeleportService
