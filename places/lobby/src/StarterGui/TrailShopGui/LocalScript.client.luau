--[[
	TrailShopGui: Trail 상점 UI (로비 클라이언트)

	기능:
	- Trail 구매 (통 구분 없이)
	- 소유한 Trail 표시
	- Trail 클릭 시 미리보기 (카메라 앞 3D 공간)
	- 장착은 해적맵에서 별도로 진행
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local camera = workspace.CurrentCamera
local trailGui = script.Parent

-- 코인 시스템 Remote
local coinSystem = ReplicatedStorage:WaitForChild("CoinSystem", 10)
local getCoinsFunc = coinSystem and coinSystem:WaitForChild("GetCoins", 5)
local coinUpdatedEvent = coinSystem and coinSystem:WaitForChild("CoinUpdated", 5)

-- 현재 코인
local currentCoins = 0

-- 해적 컨셉 색상
local COLORS = {
	woodDark = Color3.fromRGB(62, 39, 22),
	woodLight = Color3.fromRGB(101, 67, 33),
	gold = Color3.fromRGB(255, 200, 50),
	goldDark = Color3.fromRGB(180, 140, 30),
	parchment = Color3.fromRGB(210, 180, 140),
	rope = Color3.fromRGB(139, 119, 83),
	red = Color3.fromRGB(150, 40, 40),
	black = Color3.fromRGB(20, 15, 10),
	green = Color3.fromRGB(50, 150, 50),
}

-- 희귀도 색상
local rarityColors = {
	["일반"] = Color3.fromRGB(150, 150, 150),
	["레어"] = Color3.fromRGB(50, 150, 255),
	["에픽"] = Color3.fromRGB(180, 50, 255),
	["전설"] = Color3.fromRGB(255, 180, 0),
}

-- Remote 참조
local trailSystem = ReplicatedStorage:WaitForChild("TrailSystem", 10)
if not trailSystem then
	warn("[TrailShopGui] TrailSystem을 찾을 수 없습니다.")
	return
end

local getTrailsFunc = trailSystem:WaitForChild("GetTrails")
local purchaseTrailFunc = trailSystem:WaitForChild("PurchaseTrail")
local trailDataUpdated = trailSystem:WaitForChild("TrailDataUpdated")
local loadTrailAssetFunc = trailSystem:WaitForChild("LoadTrailAsset", 5)

-- 현재 상태
local currentData = nil
local trailFrames = {}
local selectedTrail = nil

-- 미리보기 관련 변수
local previewConnection = nil
local previewWorldPart = nil  -- 배럴 (회전함)
local previewTrailPart = nil  -- 잔상용 파트 (회전 안함, 위치만 따라감)
local previewWorldTrail = nil
local previewBackground = nil  -- 배경 파트
local trailAssetCache = {}
local animationTime = 0
local savedCameraType = nil  -- 카메라 타입 저장용
local savedWalkSpeed = nil  -- 이동 속도 저장용
local savedJumpPower = nil  -- 점프 파워 저장용

-- Trail 에셋 폴더 참조
local trailAssetsFolder = nil

-- 전체 화면 배경 (미리보기 영역 제외하고 불투명)
-- 미리보기 영역: Position(0.57, 0.1), Size(0.38, 0.7)
-- 5개의 프레임으로 미리보기 영역만 뚫고 나머지 완전히 덮음
local BG_COLOR = Color3.fromRGB(25, 20, 15)

-- 상단 바 (전체 너비, 미리보기 영역 위)
local topBg = Instance.new("Frame")
topBg.Name = "TopBackground"
topBg.Size = UDim2.new(1, 0, 0.1, 0)  -- 상단 10% (미리보기 Y시작 = 0.1)
topBg.Position = UDim2.new(0, 0, 0, 0)
topBg.BackgroundColor3 = BG_COLOR
topBg.BackgroundTransparency = 0
topBg.BorderSizePixel = 0
topBg.ZIndex = 0
topBg.Parent = trailGui

-- 좌측 (미리보기 영역 왼쪽 전체)
local leftBg = Instance.new("Frame")
leftBg.Name = "LeftBackground"
leftBg.Size = UDim2.new(0.57, 0, 0.7, 0)  -- 미리보기 X시작까지, 미리보기 높이만큼
leftBg.Position = UDim2.new(0, 0, 0.1, 0)  -- 미리보기 Y시작부터
leftBg.BackgroundColor3 = BG_COLOR
leftBg.BackgroundTransparency = 0
leftBg.BorderSizePixel = 0
leftBg.ZIndex = 0
leftBg.Parent = trailGui

-- 우측 (미리보기 영역 오른쪽)
local rightBg = Instance.new("Frame")
rightBg.Name = "RightBackground"
rightBg.Size = UDim2.new(0.05, 0, 0.7, 0)  -- 0.57+0.38=0.95, 나머지 5%
rightBg.Position = UDim2.new(0.95, 0, 0.1, 0)
rightBg.BackgroundColor3 = BG_COLOR
rightBg.BackgroundTransparency = 0
rightBg.BorderSizePixel = 0
rightBg.ZIndex = 0
rightBg.Parent = trailGui

-- 하단 바 (전체 너비, 미리보기 영역 아래)
local bottomBg = Instance.new("Frame")
bottomBg.Name = "BottomBackground"
bottomBg.Size = UDim2.new(1, 0, 0.2, 0)  -- 0.1+0.7=0.8, 나머지 20%
bottomBg.Position = UDim2.new(0, 0, 0.8, 0)
bottomBg.BackgroundColor3 = BG_COLOR
bottomBg.BackgroundTransparency = 0
bottomBg.BorderSizePixel = 0
bottomBg.ZIndex = 0
bottomBg.Parent = trailGui

-- 메인 프레임 생성 (좌측에만 배치 - 우측은 3D 미리보기 영역으로 비움)
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0.5, 0, 0.8, 0)  -- 좌측 50%만 사용
mainFrame.Position = UDim2.new(0.05, 0, 0.5, 0)  -- 좌측에 배치
mainFrame.AnchorPoint = Vector2.new(0, 0.5)
mainFrame.BackgroundColor3 = COLORS.woodDark
mainFrame.BorderSizePixel = 0
mainFrame.Parent = trailGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 12)
mainCorner.Parent = mainFrame

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = COLORS.goldDark
mainStroke.Thickness = 4
mainStroke.Parent = mainFrame

-- 우측 미리보기 영역 (완전 투명 - 3D가 보임!)
local previewArea = Instance.new("Frame")
previewArea.Name = "PreviewArea"
previewArea.Size = UDim2.new(0.38, 0, 0.7, 0)
previewArea.Position = UDim2.new(0.57, 0, 0.1, 0)
previewArea.BackgroundTransparency = 1  -- 완전 투명!
previewArea.BorderSizePixel = 0
previewArea.Parent = trailGui

-- 테두리만 표시 (배경 없음)
local previewAreaStroke = Instance.new("UIStroke")
previewAreaStroke.Color = COLORS.gold
previewAreaStroke.Thickness = 2
previewAreaStroke.Parent = previewArea

local previewAreaCorner = Instance.new("UICorner")
previewAreaCorner.CornerRadius = UDim.new(0, 8)
previewAreaCorner.Parent = previewArea

-- 하단 정보 프레임 (반투명 배경)
local previewInfoContainer = Instance.new("Frame")
previewInfoContainer.Name = "PreviewInfoContainer"
previewInfoContainer.Size = UDim2.new(1, 0, 0, 80)
previewInfoContainer.Position = UDim2.new(0, 0, 1, -80)
previewInfoContainer.BackgroundColor3 = COLORS.woodDark
previewInfoContainer.BackgroundTransparency = 0.3
previewInfoContainer.BorderSizePixel = 0
previewInfoContainer.Parent = previewArea

local infoContainerCorner = Instance.new("UICorner")
infoContainerCorner.CornerRadius = UDim.new(0, 8)
infoContainerCorner.Parent = previewInfoContainer

-- 상단 바
local topBar = Instance.new("Frame")
topBar.Name = "TopBar"
topBar.Size = UDim2.new(1, 0, 0, 50)
topBar.Position = UDim2.new(0, 0, 0, 0)
topBar.BackgroundColor3 = COLORS.woodLight
topBar.BorderSizePixel = 0
topBar.Parent = mainFrame

local topBarCorner = Instance.new("UICorner")
topBarCorner.CornerRadius = UDim.new(0, 12)
topBarCorner.Parent = topBar

-- 타이틀
local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "TitleLabel"
titleLabel.Size = UDim2.new(1, -100, 1, 0)
titleLabel.Position = UDim2.new(0, 20, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.TextColor3 = COLORS.gold
titleLabel.Text = "Trail 상점"
titleLabel.TextSize = 28
titleLabel.Font = Enum.Font.GothamBlack
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = topBar

-- 코인 표시
local coinLabel = Instance.new("TextLabel")
coinLabel.Name = "CoinLabel"
coinLabel.Size = UDim2.new(0, 120, 0, 30)
coinLabel.Position = UDim2.new(1, -180, 0.5, 0)
coinLabel.AnchorPoint = Vector2.new(0, 0.5)
coinLabel.BackgroundColor3 = COLORS.woodDark
coinLabel.TextColor3 = COLORS.gold
coinLabel.Text = "0"
coinLabel.TextSize = 16
coinLabel.Font = Enum.Font.GothamBold
coinLabel.Parent = topBar

local coinLabelCorner = Instance.new("UICorner")
coinLabelCorner.CornerRadius = UDim.new(0, 6)
coinLabelCorner.Parent = coinLabel

local coinLabelStroke = Instance.new("UIStroke")
coinLabelStroke.Color = COLORS.gold
coinLabelStroke.Thickness = 2
coinLabelStroke.Parent = coinLabel

-- 코인 업데이트 함수
local function updateCoinDisplay()
	if getCoinsFunc then
		task.spawn(function()
			local success, coins = pcall(function()
				return getCoinsFunc:InvokeServer()
			end)
			if success then
				currentCoins = coins
				coinLabel.Text = tostring(coins)
			end
		end)
	end
end

-- 코인 업데이트 이벤트 연결
if coinUpdatedEvent then
	coinUpdatedEvent.OnClientEvent:Connect(function(coins)
		currentCoins = coins
		coinLabel.Text = tostring(coins)
	end)
end

-- 닫기 버튼
local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.Size = UDim2.new(0, 36, 0, 36)
closeButton.Position = UDim2.new(1, -46, 0, 7)
closeButton.BackgroundColor3 = COLORS.red
closeButton.TextColor3 = COLORS.gold
closeButton.Text = "X"
closeButton.TextSize = 20
closeButton.Font = Enum.Font.GothamBlack
closeButton.Parent = topBar

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 8)
closeCorner.Parent = closeButton

closeButton.MouseButton1Click:Connect(function()
	trailGui.Enabled = false
end)

-- 좌측 패널 (Trail 목록) - 전체 너비 사용
local leftPanel = Instance.new("Frame")
leftPanel.Name = "LeftPanel"
leftPanel.Size = UDim2.new(1, -20, 1, -60)
leftPanel.Position = UDim2.new(0, 10, 0, 55)
leftPanel.BackgroundTransparency = 1
leftPanel.Parent = mainFrame


-- Trail 이름 표시 (previewInfoContainer에 배치)
local previewTrailName = Instance.new("TextLabel")
previewTrailName.Name = "TrailName"
previewTrailName.Size = UDim2.new(1, -10, 0, 22)
previewTrailName.Position = UDim2.new(0, 5, 0, 5)
previewTrailName.BackgroundTransparency = 1
previewTrailName.TextColor3 = COLORS.gold
previewTrailName.Text = "Trail을 선택하세요"
previewTrailName.TextSize = 14
previewTrailName.Font = Enum.Font.GothamBold
previewTrailName.TextXAlignment = Enum.TextXAlignment.Left
previewTrailName.Parent = previewInfoContainer

-- Trail 설명 표시
local previewTrailDesc = Instance.new("TextLabel")
previewTrailDesc.Name = "TrailDesc"
previewTrailDesc.Size = UDim2.new(1, -10, 0, 30)
previewTrailDesc.Position = UDim2.new(0, 5, 0, 28)
previewTrailDesc.BackgroundTransparency = 1
previewTrailDesc.TextColor3 = COLORS.parchment
previewTrailDesc.Text = ""
previewTrailDesc.TextSize = 11
previewTrailDesc.Font = Enum.Font.Gotham
previewTrailDesc.TextXAlignment = Enum.TextXAlignment.Left
previewTrailDesc.TextYAlignment = Enum.TextYAlignment.Top
previewTrailDesc.TextWrapped = true
previewTrailDesc.Parent = previewInfoContainer

-- 희귀도 표시
local previewRarity = Instance.new("TextLabel")
previewRarity.Name = "Rarity"
previewRarity.Size = UDim2.new(0.5, -5, 0, 18)
previewRarity.Position = UDim2.new(0, 5, 1, -22)
previewRarity.BackgroundTransparency = 1
previewRarity.TextColor3 = COLORS.parchment
previewRarity.Text = ""
previewRarity.TextSize = 11
previewRarity.Font = Enum.Font.GothamBold
previewRarity.TextXAlignment = Enum.TextXAlignment.Left
previewRarity.Parent = previewInfoContainer

-- 가격 표시
local previewPrice = Instance.new("TextLabel")
previewPrice.Name = "Price"
previewPrice.Size = UDim2.new(0.5, -5, 0, 18)
previewPrice.Position = UDim2.new(0.5, 0, 1, -22)
previewPrice.BackgroundTransparency = 1
previewPrice.TextColor3 = COLORS.gold
previewPrice.Text = ""
previewPrice.TextSize = 11
previewPrice.Font = Enum.Font.GothamBold
previewPrice.TextXAlignment = Enum.TextXAlignment.Right
previewPrice.Parent = previewInfoContainer

-- 안내 문구
local infoLabel = Instance.new("TextLabel")
infoLabel.Name = "InfoLabel"
infoLabel.Size = UDim2.new(1, 0, 0, 20)
infoLabel.Position = UDim2.new(0, 0, 0, 0)
infoLabel.BackgroundTransparency = 1
infoLabel.TextColor3 = COLORS.parchment
infoLabel.Text = "구매한 Trail은 게임에서 각 통에 장착할 수 있습니다"
infoLabel.TextSize = 12
infoLabel.Font = Enum.Font.Gotham
infoLabel.Parent = leftPanel

-- Trail 목록 스크롤 프레임
local trailList = Instance.new("ScrollingFrame")
trailList.Name = "TrailList"
trailList.Size = UDim2.new(1, 0, 1, -25)
trailList.Position = UDim2.new(0, 0, 0, 25)
trailList.BackgroundColor3 = COLORS.parchment
trailList.BorderSizePixel = 0
trailList.ScrollBarThickness = 8
trailList.ScrollBarImageColor3 = COLORS.woodDark
trailList.CanvasSize = UDim2.new(0, 0, 0, 0)
trailList.AutomaticCanvasSize = Enum.AutomaticSize.Y
trailList.Parent = leftPanel

local trailListCorner = Instance.new("UICorner")
trailListCorner.CornerRadius = UDim.new(0, 8)
trailListCorner.Parent = trailList

local trailGridLayout = Instance.new("UIGridLayout")
trailGridLayout.CellSize = UDim2.new(0, 130, 0, 150)
trailGridLayout.CellPadding = UDim2.new(0, 8, 0, 8)
trailGridLayout.SortOrder = Enum.SortOrder.LayoutOrder
trailGridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
trailGridLayout.Parent = trailList

local trailPadding = Instance.new("UIPadding")
trailPadding.PaddingTop = UDim.new(0, 8)
trailPadding.PaddingBottom = UDim.new(0, 8)
trailPadding.PaddingLeft = UDim.new(0, 8)
trailPadding.PaddingRight = UDim.new(0, 8)
trailPadding.Parent = trailList

-- 미리보기 정리 함수 (배경은 유지)
local function cleanupPreview()
	if previewWorldPart then
		previewWorldPart:Destroy()
		previewWorldPart = nil
	end
	if previewTrailPart then
		previewTrailPart:Destroy()
		previewTrailPart = nil
	end
	if previewWorldTrail then
		previewWorldTrail:Destroy()
		previewWorldTrail = nil
	end
end

-- 배경만 정리
local function cleanupBackground()
	if previewBackground then
		previewBackground:Destroy()
		previewBackground = nil
	end
end

-- Trail 에셋 로드 (비동기)
local function loadTrailAsset(trailName)
	print("[TrailShopGui] loadTrailAsset 호출:", trailName)

	-- 클라이언트 캐시 확인
	if trailAssetCache[trailName] then
		print("[TrailShopGui] 캐시에서 발견:", trailName)
		return trailAssetCache[trailName]:Clone()
	end

	-- ReplicatedStorage 폴더 확인
	if not trailAssetsFolder then
		trailAssetsFolder = ReplicatedStorage:FindFirstChild("TrailAssets")
		print("[TrailShopGui] TrailAssets 폴더:", trailAssetsFolder and "발견" or "없음")
	end

	-- 이미 로드된 에셋 확인
	if trailAssetsFolder then
		local existingAsset = trailAssetsFolder:FindFirstChild(trailName)
		if existingAsset then
			print("[TrailShopGui] ReplicatedStorage에서 발견:", trailName, existingAsset.ClassName)
			trailAssetCache[trailName] = existingAsset:Clone()
			return existingAsset:Clone()
		end
	end

	-- 서버에 로드 요청
	print("[TrailShopGui] 서버에 로드 요청:", trailName)
	if loadTrailAssetFunc then
		local success, assetName = pcall(function()
			return loadTrailAssetFunc:InvokeServer(trailName)
		end)

		print("[TrailShopGui] 서버 응답:", success, assetName)

		if success and assetName then
			-- 폴더 다시 확인
			if not trailAssetsFolder then
				trailAssetsFolder = ReplicatedStorage:WaitForChild("TrailAssets", 5)
			end

			if trailAssetsFolder then
				local trailAsset = trailAssetsFolder:WaitForChild(assetName, 5)
				if trailAsset then
					print("[TrailShopGui] 에셋 로드 성공:", trailName, trailAsset.ClassName)
					trailAssetCache[trailName] = trailAsset:Clone()
					return trailAsset:Clone()
				else
					warn("[TrailShopGui] 에셋 대기 실패:", assetName)
				end
			else
				warn("[TrailShopGui] TrailAssets 폴더 대기 실패")
			end
		end
	else
		warn("[TrailShopGui] loadTrailAssetFunc 없음")
	end

	warn("[TrailShopGui] 에셋 로드 실패:", trailName)
	return nil
end

-- 미리보기 영역 화면 좌표 계산 헬퍼
local function getPreviewScreenPosition()
	local absPos = previewArea.AbsolutePosition
	local absSize = previewArea.AbsoluteSize
	local centerX = absPos.X + absSize.X / 2
	local centerY = absPos.Y + absSize.Y * 0.4  -- 하단 정보 패널 고려해서 약간 위
	return centerX, centerY
end

-- 배경 생성 함수 (상점 열릴 때 호출)
local function createBackground()
	if previewBackground then return end  -- 이미 있으면 스킵

	local screenX, screenY = getPreviewScreenPosition()
	local ray = camera:ScreenPointToRay(screenX, screenY)
	local distanceFromCamera = 8
	local worldPosition = ray.Origin + ray.Direction * distanceFromCamera
	local bgPosition = worldPosition + camera.CFrame.LookVector * 2

	local bgPart = Instance.new("Part")
	bgPart.Name = "TrailPreviewBackground"
	bgPart.Shape = Enum.PartType.Block
	bgPart.Size = Vector3.new(20, 20, 0.1)
	bgPart.CFrame = CFrame.new(bgPosition, bgPosition + camera.CFrame.LookVector)
	bgPart.Color = Color3.fromRGB(25, 20, 15)
	bgPart.Material = Enum.Material.SmoothPlastic
	bgPart.Anchored = true
	bgPart.CanCollide = false
	bgPart.CastShadow = false
	bgPart.Parent = camera
	previewBackground = bgPart
end

-- 미리보기 생성 (우측 3D 영역에 배럴 표시)
local function createPreview(trailName)
	cleanupPreview()

	if not trailName then
		previewTrailName.Text = "Trail을 선택하세요"
		previewTrailDesc.Text = ""
		previewRarity.Text = ""
		previewPrice.Text = ""
		return
	end

	-- 우측 미리보기 영역 중앙 위치 계산
	local screenX, screenY = getPreviewScreenPosition()

	local ray = camera:ScreenPointToRay(screenX, screenY)
	local distanceFromCamera = 8
	local worldPosition = ray.Origin + ray.Direction * distanceFromCamera

	print("[TrailShopGui] 배럴 생성 위치:", worldPosition, "화면좌표:", screenX, screenY)

	-- 서버에서 로드한 배럴 모델 사용
	local barrel = nil
	local assetsFolder = ReplicatedStorage:FindFirstChild("TrailAssets")
	local previewBarrelTemplate = assetsFolder and assetsFolder:FindFirstChild("PreviewBarrel")

	if previewBarrelTemplate then
		-- 모델 복제
		local barrelClone = previewBarrelTemplate:Clone()
		barrelClone.Name = "TrailPreviewBarrel"

		if barrelClone:IsA("Model") then
			-- 스케일 전 확인
			local beforeScale = barrelClone:GetScale()
			print("[TrailShopGui] 스케일 전:", beforeScale)

			-- workspace에 넣고 스케일 적용
			barrelClone.Parent = workspace
			barrelClone:ScaleTo(0.15)

			-- 스케일 후 확인
			local afterScale = barrelClone:GetScale()
			print("[TrailShopGui] 스케일 후:", afterScale)

			-- 모델 내 파트 크기 확인
			for _, part in pairs(barrelClone:GetDescendants()) do
				if part:IsA("BasePart") then
					print("[TrailShopGui] 파트:", part.Name, "Size:", part.Size)
					part.Anchored = true
					part.CanCollide = false
					part.CastShadow = false
					if not barrel then
						barrel = part  -- Trail 부착용 메인 파트
					end
				end
			end

			barrelClone:PivotTo(CFrame.new(worldPosition))
			barrelClone.Parent = camera
			previewWorldPart = barrelClone
		elseif barrelClone:IsA("BasePart") then
			barrel = barrelClone
			-- BasePart는 Size를 직접 줄임
			print("[TrailShopGui] BasePart 스케일 전 Size:", barrel.Size)
			barrel.Size = barrel.Size * 0.15
			print("[TrailShopGui] BasePart 스케일 후 Size:", barrel.Size)
			barrel.CFrame = CFrame.new(worldPosition)
			barrel.Anchored = true
			barrel.CanCollide = false
			barrel.CastShadow = false
			barrel.Parent = camera
			previewWorldPart = barrel
		end
		print("[TrailShopGui] 커스텀 배럴 모델 사용")
	else
		-- 폴백: 기본 실린더
		warn("[TrailShopGui] PreviewBarrel 모델 없음, 기본 형태 사용")
		barrel = Instance.new("Part")
		barrel.Name = "TrailPreviewBarrel"
		barrel.Shape = Enum.PartType.Cylinder
		barrel.Size = Vector3.new(1.2, 0.8, 0.8)
		barrel.CFrame = CFrame.new(worldPosition) * CFrame.Angles(0, 0, math.rad(90))
		barrel.Color = Color3.fromRGB(139, 90, 43)
		barrel.Material = Enum.Material.Wood
		barrel.Anchored = true
		barrel.CanCollide = false
		barrel.CastShadow = false
		barrel.Parent = camera
		previewWorldPart = barrel
	end

	print("[TrailShopGui] 배럴 생성 완료")

	-- 잔상용 투명 파트 생성 (회전하지 않고 위치만 따라감)
	local trailPart = Instance.new("Part")
	trailPart.Name = "TrailEffectPart"
	trailPart.Size = Vector3.new(0.5, 0.5, 0.5)
	trailPart.CFrame = CFrame.new(worldPosition)
	trailPart.Transparency = 1  -- 완전 투명
	trailPart.Anchored = true
	trailPart.CanCollide = false
	trailPart.CastShadow = false
	trailPart.Parent = camera
	previewTrailPart = trailPart

	-- Trail 에셋 로드 (비동기)
	task.spawn(function()
		local trailAsset = loadTrailAsset(trailName)

		if not previewWorldPart then return end
		if not previewTrailPart then return end

		if trailAsset then
			print("[TrailShopGui] 에셋 적용:", trailName, trailAsset.ClassName)

			if trailAsset:IsA("Trail") then
				local attachment0 = Instance.new("Attachment")
				attachment0.Position = Vector3.new(-0.3, 0, 0)
				attachment0.Parent = previewTrailPart

				local attachment1 = Instance.new("Attachment")
				attachment1.Position = Vector3.new(0.3, 0, 0)
				attachment1.Parent = previewTrailPart

				trailAsset.Enabled = true
				trailAsset.Attachment0 = attachment0
				trailAsset.Attachment1 = attachment1
				trailAsset.Parent = previewTrailPart
				previewWorldTrail = trailAsset
				print("[TrailShopGui] Trail 적용 완료")

			elseif trailAsset:IsA("ParticleEmitter") then
				-- 크기 50% 축소
				local newSizeKeypoints = {}
				for _, kp in pairs(trailAsset.Size.Keypoints) do
					table.insert(newSizeKeypoints, NumberSequenceKeypoint.new(kp.Time, kp.Value * 0.5, kp.Envelope * 0.5))
				end
				trailAsset.Size = NumberSequence.new(newSizeKeypoints)
				trailAsset.EmissionDirection = Enum.NormalId.Back  -- 뒤쪽으로 방출 (잔상처럼)
				trailAsset.Enabled = true
				trailAsset.Parent = previewTrailPart
				previewWorldTrail = trailAsset
				print("[TrailShopGui] ParticleEmitter 적용 완료")

			elseif trailAsset:IsA("Fire") then
				trailAsset.Size = 2
				trailAsset.Heat = 3
				trailAsset.Enabled = true
				trailAsset.Parent = previewTrailPart
				previewWorldTrail = trailAsset
				print("[TrailShopGui] Fire 적용 완료")

			elseif trailAsset:IsA("Smoke") then
				trailAsset.Enabled = true
				trailAsset.Parent = previewTrailPart
				previewWorldTrail = trailAsset
				print("[TrailShopGui] Smoke 적용 완료")

			elseif trailAsset:IsA("Sparkles") then
				trailAsset.Enabled = true
				trailAsset.Parent = previewTrailPart
				previewWorldTrail = trailAsset
				print("[TrailShopGui] Sparkles 적용 완료")
			end
		else
			warn("[TrailShopGui] 에셋 로드 실패:", trailName)
		end
	end)
end

-- 미리보기 애니메이션 (우측 3D 영역에서 움직임)
local function updatePreviewAnimation(dt)
	animationTime = animationTime + dt

	if not previewWorldPart then return end
	if not trailGui.Enabled then return end

	-- 우측 미리보기 영역 중앙 위치 계산
	local screenX, screenY = getPreviewScreenPosition()

	local ray = camera:ScreenPointToRay(screenX, screenY)
	local distanceFromCamera = 8
	local camCFrame = camera.CFrame

	-- 빠른 좌->우 애니메이션 (1.5초에 한 번)
	local cycleDuration = 1.5
	local t = (animationTime % cycleDuration) / cycleDuration
	local offsetX = (t - 0.5) * 6  -- 좌측(-3)에서 우측(+3)
	local offsetY = math.sin(t * math.pi) * 0.3

	local basePosition = ray.Origin + ray.Direction * distanceFromCamera
	local worldOffset = camCFrame.RightVector * offsetX + camCFrame.UpVector * offsetY
	local worldPosition = basePosition + worldOffset

	-- 배럴이 화면 X축(좌->우)으로만 날아감
	local rotation = CFrame.Angles(0, 0, animationTime * 5)
	previewWorldPart.CFrame = CFrame.new(worldPosition) * CFrame.Angles(0, math.rad(-90), 0) * rotation

	-- 잔상용 파트는 위치 + 날아가는 방향만
	if previewTrailPart then
		previewTrailPart.CFrame = CFrame.new(worldPosition) * CFrame.Angles(0, math.rad(-90), 0)
	end

	-- 배경은 고정 위치
	if previewBackground then
		local bgPosition = ray.Origin + ray.Direction * (distanceFromCamera + 2)
		previewBackground.CFrame = CFrame.new(bgPosition, bgPosition + camCFrame.LookVector)
	end
end

-- 미리보기 정보 업데이트
local function updatePreviewInfo(trailName)
	if trailName and currentData and currentData.allTrails[trailName] then
		local trailInfo = currentData.allTrails[trailName]
		previewTrailName.Text = trailInfo.DisplayName
		previewTrailDesc.Text = trailInfo.Description
		previewRarity.Text = trailInfo.Rarity
		previewRarity.TextColor3 = rarityColors[trailInfo.Rarity] or COLORS.parchment

		local coinPrice = trailInfo.CoinPrice or 0
		if coinPrice > 0 then
			previewPrice.Text = coinPrice .. " 코인"
		else
			previewPrice.Text = "무료"
		end
	else
		previewTrailName.Text = "Trail 선택"
		previewTrailDesc.Text = "Trail을 클릭하면 미리보기가 표시됩니다."
		previewRarity.Text = ""
		previewPrice.Text = ""
	end
end

-- Trail 목록 업데이트
local function updateTrailList()
	-- 기존 Trail 아이템 제거
	for _, frame in pairs(trailFrames) do
		frame:Destroy()
	end
	trailFrames = {}

	if not currentData then
		return
	end

	-- Trail 목록 생성 (희귀도/가격 순으로 정렬)
	local sortedTrails = {}
	for trailName, trailInfo in pairs(currentData.allTrails) do
		-- 모든 Trail 표시 (무료 포함)
		table.insert(sortedTrails, { name = trailName, info = trailInfo })
	end
	table.sort(sortedTrails, function(a, b)
		local rarityA = currentData.rarities[a.info.Rarity] and currentData.rarities[a.info.Rarity].order or 0
		local rarityB = currentData.rarities[b.info.Rarity] and currentData.rarities[b.info.Rarity].order or 0
		if rarityA == rarityB then
			return (a.info.CoinPrice or 0) < (b.info.CoinPrice or 0)
		end
		return rarityA < rarityB
	end)

	for i, trailData in ipairs(sortedTrails) do
		local trailName = trailData.name
		local trailInfo = trailData.info
		local isOwned = table.find(currentData.ownedTrails, trailName) ~= nil

		local trailFrame = Instance.new("TextButton")
		trailFrame.Name = trailName
		trailFrame.BackgroundColor3 = COLORS.woodLight
		trailFrame.BorderSizePixel = 0
		trailFrame.LayoutOrder = i
		trailFrame.Text = ""
		trailFrame.AutoButtonColor = false
		trailFrame.Parent = trailList

		local frameCorner = Instance.new("UICorner")
		frameCorner.CornerRadius = UDim.new(0, 8)
		frameCorner.Parent = trailFrame

		local frameStroke = Instance.new("UIStroke")
		frameStroke.Color = isOwned and COLORS.green or (rarityColors[trailInfo.Rarity] or COLORS.rope)
		frameStroke.Thickness = isOwned and 3 or 2
		frameStroke.Parent = trailFrame

		-- 아이콘 영역
		local iconFrame = Instance.new("Frame")
		iconFrame.Size = UDim2.new(1, -10, 0, 55)
		iconFrame.Position = UDim2.new(0, 5, 0, 5)
		iconFrame.BackgroundColor3 = rarityColors[trailInfo.Rarity] or COLORS.woodDark
		iconFrame.BorderSizePixel = 0
		iconFrame.Parent = trailFrame

		local iconCorner = Instance.new("UICorner")
		iconCorner.CornerRadius = UDim.new(0, 6)
		iconCorner.Parent = iconFrame

		-- 소유 표시
		if isOwned then
			local ownedBadge = Instance.new("TextLabel")
			ownedBadge.Size = UDim2.new(0, 40, 0, 14)
			ownedBadge.Position = UDim2.new(1, -42, 0, 2)
			ownedBadge.BackgroundColor3 = COLORS.green
			ownedBadge.TextColor3 = Color3.new(1, 1, 1)
			ownedBadge.Text = "보유"
			ownedBadge.TextSize = 9
			ownedBadge.Font = Enum.Font.GothamBold
			ownedBadge.Parent = iconFrame

			local badgeCorner = Instance.new("UICorner")
			badgeCorner.CornerRadius = UDim.new(0, 4)
			badgeCorner.Parent = ownedBadge
		end

		-- 희귀도 표시
		local rarityLabel = Instance.new("TextLabel")
		rarityLabel.Size = UDim2.new(1, 0, 0, 12)
		rarityLabel.Position = UDim2.new(0, 0, 0, 63)
		rarityLabel.BackgroundTransparency = 1
		rarityLabel.TextColor3 = rarityColors[trailInfo.Rarity] or COLORS.parchment
		rarityLabel.Text = trailInfo.Rarity
		rarityLabel.TextSize = 9
		rarityLabel.Font = Enum.Font.GothamBold
		rarityLabel.Parent = trailFrame

		-- Trail 이름
		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(1, -6, 0, 16)
		nameLabel.Position = UDim2.new(0, 3, 0, 77)
		nameLabel.BackgroundTransparency = 1
		nameLabel.TextColor3 = COLORS.parchment
		nameLabel.Text = trailInfo.DisplayName
		nameLabel.TextSize = 11
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
		nameLabel.Parent = trailFrame

		-- 설명
		local descLabel = Instance.new("TextLabel")
		descLabel.Size = UDim2.new(1, -6, 0, 20)
		descLabel.Position = UDim2.new(0, 3, 0, 93)
		descLabel.BackgroundTransparency = 1
		descLabel.TextColor3 = COLORS.rope
		descLabel.Text = trailInfo.Description
		descLabel.TextSize = 8
		descLabel.Font = Enum.Font.Gotham
		descLabel.TextWrapped = true
		descLabel.TextYAlignment = Enum.TextYAlignment.Top
		descLabel.Parent = trailFrame

		-- 버튼 (구매/보유중)
		local actionButton = Instance.new("TextButton")
		actionButton.Size = UDim2.new(1, -10, 0, 22)
		actionButton.Position = UDim2.new(0, 5, 1, -27)
		actionButton.Font = Enum.Font.GothamBold
		actionButton.TextSize = 10
		actionButton.Parent = trailFrame

		local buttonCorner = Instance.new("UICorner")
		buttonCorner.CornerRadius = UDim.new(0, 6)
		buttonCorner.Parent = actionButton

		if isOwned then
			actionButton.BackgroundColor3 = COLORS.rope
			actionButton.TextColor3 = COLORS.parchment
			actionButton.Text = "보유중"
			actionButton.Active = false
		else
			local coinPrice = trailInfo.CoinPrice or 0
			actionButton.BackgroundColor3 = COLORS.gold
			actionButton.TextColor3 = COLORS.black
			if coinPrice > 0 then
				actionButton.Text = coinPrice .. " 코인"
			else
				actionButton.Text = "무료 획득"
				actionButton.BackgroundColor3 = COLORS.green
				actionButton.TextColor3 = Color3.new(1, 1, 1)
			end

			actionButton.MouseButton1Click:Connect(function()
				purchaseTrailFunc:InvokeServer(trailName)
			end)
		end

		-- 클릭 시 미리보기
		trailFrame.MouseButton1Click:Connect(function()
			selectedTrail = trailName

			-- 선택 표시 업데이트
			for name, frame in pairs(trailFrames) do
				local stroke = frame:FindFirstChildOfClass("UIStroke")
				if stroke then
					local info = currentData.allTrails[name]
					local owned = table.find(currentData.ownedTrails, name) ~= nil
					if name == trailName then
						stroke.Color = COLORS.gold
						stroke.Thickness = 3
					elseif owned then
						stroke.Color = COLORS.green
						stroke.Thickness = 3
					else
						stroke.Color = rarityColors[info.Rarity] or COLORS.rope
						stroke.Thickness = 2
					end
				end
			end

			-- 미리보기 업데이트 (비동기)
			updatePreviewInfo(trailName)
			task.spawn(function()
				createPreview(trailName)
			end)
		end)

		trailFrames[trailName] = trailFrame
	end
end

-- 데이터 로드
local function loadTrailData()
	local success, result = pcall(function()
		return getTrailsFunc:InvokeServer()
	end)

	if success and result then
		currentData = result
		updateTrailList()
	else
		warn("[TrailShopGui] Trail 데이터 로드 실패:", result)
	end
end

-- 서버에서 데이터 업데이트 수신
trailDataUpdated.OnClientEvent:Connect(function(data)
	if currentData then
		currentData.ownedTrails = data.ownedTrails
		currentData.equippedTrails = data.equippedTrails
		updateTrailList()
	end
end)

-- GUI 활성화/비활성화 처리
trailGui:GetPropertyChangedSignal("Enabled"):Connect(function()
	if trailGui.Enabled then
		-- 카메라 고정 (시점 변경 막기)
		savedCameraType = camera.CameraType
		camera.CameraType = Enum.CameraType.Scriptable

		-- 캐릭터 이동 잠금
		local humanoid = player.Character and player.Character:FindFirstChild("Humanoid")
		if humanoid then
			savedWalkSpeed = humanoid.WalkSpeed
			savedJumpPower = humanoid.JumpPower
			humanoid.WalkSpeed = 0
			humanoid.JumpPower = 0
		end

		loadTrailData()
		updateCoinDisplay()

		-- 배경 먼저 생성 (상점 열자마자 뚫린 부분 가림)
		createBackground()

		-- 미리보기 초기화
		previewTrailName.Text = "Trail을 선택하세요"
		previewTrailDesc.Text = ""
		previewRarity.Text = ""
		previewPrice.Text = ""
		-- 미리보기 애니메이션 시작
		if previewConnection then
			previewConnection:Disconnect()
		end
		previewConnection = RunService.RenderStepped:Connect(updatePreviewAnimation)
	else
		-- 카메라 복원
		if savedCameraType then
			camera.CameraType = savedCameraType
			savedCameraType = nil
		end

		-- 캐릭터 이동 복원
		local humanoid = player.Character and player.Character:FindFirstChild("Humanoid")
		if humanoid and savedWalkSpeed then
			humanoid.WalkSpeed = savedWalkSpeed
			humanoid.JumpPower = savedJumpPower
			savedWalkSpeed = nil
			savedJumpPower = nil
		end

		-- 미리보기 정리
		if previewConnection then
			previewConnection:Disconnect()
			previewConnection = nil
		end
		cleanupPreview()
		cleanupBackground()  -- 배경도 정리
		selectedTrail = nil
		updatePreviewInfo(nil)
	end
end)

-- 초기 상태: 비활성화
trailGui.Enabled = false
