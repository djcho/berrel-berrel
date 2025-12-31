--[[
	TrailShopGui: Trail 상점 UI (로비 클라이언트)

	기능:
	- 배럴별 Trail 장착 설정
	- 소유한 Trail 표시
	- Developer Product 구매 (로벅스)
	- 배럴 + Trail 조합 미리보기 (ViewportFrame)
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local trailGui = script.Parent

-- 해적 컨셉 색상 (ShopGui와 동일)
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
	blue = Color3.fromRGB(50, 100, 200),
}

-- 희귀도 색상
local rarityColors = {
	["일반"] = Color3.fromRGB(150, 150, 150),
	["레어"] = Color3.fromRGB(50, 150, 255),
	["에픽"] = Color3.fromRGB(180, 50, 255),
	["전설"] = Color3.fromRGB(255, 180, 0),
}

-- 배럴 표시 이름
local barrelDisplayNames = {
	NormalBarrel = "기본통",
	OilBarrel = "기름통",
	FireBarrel = "화염통",
	PoisonBarrel = "독구름통",
	WindBarrel = "바람통",
}

-- 배럴 색상 (미리보기용)
local barrelColors = {
	NormalBarrel = Color3.fromRGB(139, 90, 43),
	OilBarrel = Color3.fromRGB(30, 30, 30),
	FireBarrel = Color3.fromRGB(200, 80, 30),
	PoisonBarrel = Color3.fromRGB(80, 180, 80),
	WindBarrel = Color3.fromRGB(180, 220, 255),
}

-- Trail 색상 (미리보기용)
local trailColors = {
	Trail = Color3.fromRGB(200, 200, 200),
	Oil = Color3.fromRGB(50, 50, 50),
	Fire = Color3.fromRGB(255, 120, 30),
	Gas = Color3.fromRGB(100, 200, 100),
	Rainbow = Color3.fromRGB(255, 100, 100), -- 무지개는 애니메이션으로 처리
	Starlight = Color3.fromRGB(255, 255, 150),
	GhostFlame = Color3.fromRGB(100, 200, 255),
	GoldenAura = Color3.fromRGB(255, 200, 50),
}

-- Remote 참조 (서버 준비될 때까지 대기)
local trailSystem = ReplicatedStorage:WaitForChild("TrailSystem", 10)
if not trailSystem then
	warn("[TrailShopGui] TrailSystem을 찾을 수 없습니다.")
	return
end

local getTrailsFunc = trailSystem:WaitForChild("GetTrails")
local equipTrailFunc = trailSystem:WaitForChild("EquipTrail")
local purchaseTrailFunc = trailSystem:WaitForChild("PurchaseTrail")
local trailDataUpdated = trailSystem:WaitForChild("TrailDataUpdated")

-- 현재 상태
local currentData = nil
local selectedBarrel = "NormalBarrel"
local selectedTrailForPreview = nil
local barrelButtons = {}
local trailFrames = {}

-- 미리보기 관련 변수
local previewConnection = nil
local previewBarrelModel = nil
local previewTrailParts = {}

-- 메인 프레임 생성
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0.85, 0, 0.85, 0)
mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
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

-- 타이틀 그림자
local titleShadow = Instance.new("TextLabel")
titleShadow.Size = titleLabel.Size
titleShadow.Position = UDim2.new(0, 22, 0, 2)
titleShadow.BackgroundTransparency = 1
titleShadow.TextColor3 = COLORS.black
titleShadow.Text = titleLabel.Text
titleShadow.TextSize = 28
titleShadow.Font = Enum.Font.GothamBlack
titleShadow.TextXAlignment = Enum.TextXAlignment.Left
titleShadow.ZIndex = 0
titleShadow.Parent = topBar

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

local closeStroke = Instance.new("UIStroke")
closeStroke.Color = COLORS.goldDark
closeStroke.Thickness = 2
closeStroke.Parent = closeButton

closeButton.MouseButton1Click:Connect(function()
	trailGui.Enabled = false
end)

-- 좌측 패널 (Trail 목록)
local leftPanel = Instance.new("Frame")
leftPanel.Name = "LeftPanel"
leftPanel.Size = UDim2.new(0.6, -15, 1, -60)
leftPanel.Position = UDim2.new(0, 10, 0, 55)
leftPanel.BackgroundTransparency = 1
leftPanel.Parent = mainFrame

-- 우측 패널 (미리보기)
local rightPanel = Instance.new("Frame")
rightPanel.Name = "RightPanel"
rightPanel.Size = UDim2.new(0.4, -15, 1, -60)
rightPanel.Position = UDim2.new(0.6, 5, 0, 55)
rightPanel.BackgroundColor3 = COLORS.woodLight
rightPanel.BorderSizePixel = 0
rightPanel.Parent = mainFrame

local rightPanelCorner = Instance.new("UICorner")
rightPanelCorner.CornerRadius = UDim.new(0, 8)
rightPanelCorner.Parent = rightPanel

local rightPanelStroke = Instance.new("UIStroke")
rightPanelStroke.Color = COLORS.goldDark
rightPanelStroke.Thickness = 2
rightPanelStroke.Parent = rightPanel

-- 미리보기 타이틀
local previewTitle = Instance.new("TextLabel")
previewTitle.Name = "PreviewTitle"
previewTitle.Size = UDim2.new(1, 0, 0, 30)
previewTitle.Position = UDim2.new(0, 0, 0, 5)
previewTitle.BackgroundTransparency = 1
previewTitle.TextColor3 = COLORS.gold
previewTitle.Text = "미리보기"
previewTitle.TextSize = 18
previewTitle.Font = Enum.Font.GothamBold
previewTitle.Parent = rightPanel

-- ViewportFrame (3D 미리보기)
local viewportFrame = Instance.new("ViewportFrame")
viewportFrame.Name = "PreviewViewport"
viewportFrame.Size = UDim2.new(1, -20, 0.6, -40)
viewportFrame.Position = UDim2.new(0, 10, 0, 40)
viewportFrame.BackgroundColor3 = Color3.fromRGB(40, 60, 80)
viewportFrame.BorderSizePixel = 0
viewportFrame.Parent = rightPanel

local viewportCorner = Instance.new("UICorner")
viewportCorner.CornerRadius = UDim.new(0, 8)
viewportCorner.Parent = viewportFrame

-- ViewportFrame 카메라
local previewCamera = Instance.new("Camera")
previewCamera.CFrame = CFrame.new(Vector3.new(5, 3, 5), Vector3.new(0, 0, 0))
previewCamera.Parent = viewportFrame
viewportFrame.CurrentCamera = previewCamera

-- WorldModel (ViewportFrame 내 오브젝트 컨테이너)
local worldModel = Instance.new("WorldModel")
worldModel.Parent = viewportFrame

-- 미리보기 정보 표시
local previewInfoFrame = Instance.new("Frame")
previewInfoFrame.Name = "PreviewInfo"
previewInfoFrame.Size = UDim2.new(1, -20, 0.4, -50)
previewInfoFrame.Position = UDim2.new(0, 10, 0.6, 10)
previewInfoFrame.BackgroundColor3 = COLORS.woodDark
previewInfoFrame.BorderSizePixel = 0
previewInfoFrame.Parent = rightPanel

local previewInfoCorner = Instance.new("UICorner")
previewInfoCorner.CornerRadius = UDim.new(0, 6)
previewInfoCorner.Parent = previewInfoFrame

-- Trail 이름 표시
local previewTrailName = Instance.new("TextLabel")
previewTrailName.Name = "TrailName"
previewTrailName.Size = UDim2.new(1, -10, 0, 25)
previewTrailName.Position = UDim2.new(0, 5, 0, 10)
previewTrailName.BackgroundTransparency = 1
previewTrailName.TextColor3 = COLORS.gold
previewTrailName.Text = "Trail 선택"
previewTrailName.TextSize = 16
previewTrailName.Font = Enum.Font.GothamBold
previewTrailName.TextXAlignment = Enum.TextXAlignment.Left
previewTrailName.Parent = previewInfoFrame

-- Trail 설명 표시
local previewTrailDesc = Instance.new("TextLabel")
previewTrailDesc.Name = "TrailDesc"
previewTrailDesc.Size = UDim2.new(1, -10, 0, 40)
previewTrailDesc.Position = UDim2.new(0, 5, 0, 38)
previewTrailDesc.BackgroundTransparency = 1
previewTrailDesc.TextColor3 = COLORS.parchment
previewTrailDesc.Text = "Trail을 선택하면 미리보기가 표시됩니다."
previewTrailDesc.TextSize = 12
previewTrailDesc.Font = Enum.Font.Gotham
previewTrailDesc.TextXAlignment = Enum.TextXAlignment.Left
previewTrailDesc.TextYAlignment = Enum.TextYAlignment.Top
previewTrailDesc.TextWrapped = true
previewTrailDesc.Parent = previewInfoFrame

-- 희귀도 표시
local previewRarity = Instance.new("TextLabel")
previewRarity.Name = "Rarity"
previewRarity.Size = UDim2.new(0.5, -5, 0, 20)
previewRarity.Position = UDim2.new(0, 5, 0, 82)
previewRarity.BackgroundTransparency = 1
previewRarity.TextColor3 = COLORS.parchment
previewRarity.Text = ""
previewRarity.TextSize = 12
previewRarity.Font = Enum.Font.GothamBold
previewRarity.TextXAlignment = Enum.TextXAlignment.Left
previewRarity.Parent = previewInfoFrame

-- 가격 표시
local previewPrice = Instance.new("TextLabel")
previewPrice.Name = "Price"
previewPrice.Size = UDim2.new(0.5, -5, 0, 20)
previewPrice.Position = UDim2.new(0.5, 0, 0, 82)
previewPrice.BackgroundTransparency = 1
previewPrice.TextColor3 = COLORS.gold
previewPrice.Text = ""
previewPrice.TextSize = 12
previewPrice.Font = Enum.Font.GothamBold
previewPrice.TextXAlignment = Enum.TextXAlignment.Right
previewPrice.Parent = previewInfoFrame

-- 배럴 선택 탭 영역
local barrelTabFrame = Instance.new("Frame")
barrelTabFrame.Name = "BarrelTabFrame"
barrelTabFrame.Size = UDim2.new(1, 0, 0, 40)
barrelTabFrame.Position = UDim2.new(0, 0, 0, 0)
barrelTabFrame.BackgroundTransparency = 1
barrelTabFrame.Parent = leftPanel

local barrelTabLayout = Instance.new("UIListLayout")
barrelTabLayout.FillDirection = Enum.FillDirection.Horizontal
barrelTabLayout.SortOrder = Enum.SortOrder.LayoutOrder
barrelTabLayout.Padding = UDim.new(0, 6)
barrelTabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
barrelTabLayout.Parent = barrelTabFrame

-- 배럴 탭 버튼 생성
local barrelOrder = {"NormalBarrel", "OilBarrel", "FireBarrel", "PoisonBarrel", "WindBarrel"}
for i, barrelName in ipairs(barrelOrder) do
	local barrelButton = Instance.new("TextButton")
	barrelButton.Name = barrelName
	barrelButton.Size = UDim2.new(0, 75, 0, 32)
	barrelButton.BackgroundColor3 = barrelName == selectedBarrel and COLORS.gold or COLORS.woodLight
	barrelButton.TextColor3 = barrelName == selectedBarrel and COLORS.black or COLORS.parchment
	barrelButton.Text = barrelDisplayNames[barrelName]
	barrelButton.TextSize = 11
	barrelButton.Font = Enum.Font.GothamBold
	barrelButton.LayoutOrder = i
	barrelButton.Parent = barrelTabFrame

	local barrelCorner = Instance.new("UICorner")
	barrelCorner.CornerRadius = UDim.new(0, 6)
	barrelCorner.Parent = barrelButton

	barrelButtons[barrelName] = barrelButton

	barrelButton.MouseButton1Click:Connect(function()
		selectedBarrel = barrelName
		updateBarrelTabs()
		updateTrailList()
		updatePreview()
	end)
end

-- 현재 장착 정보 표시
local equippedLabel = Instance.new("TextLabel")
equippedLabel.Name = "EquippedLabel"
equippedLabel.Size = UDim2.new(1, 0, 0, 22)
equippedLabel.Position = UDim2.new(0, 0, 0, 45)
equippedLabel.BackgroundTransparency = 1
equippedLabel.TextColor3 = COLORS.gold
equippedLabel.Text = "현재 장착: 기본 잔상"
equippedLabel.TextSize = 14
equippedLabel.Font = Enum.Font.GothamBold
equippedLabel.TextXAlignment = Enum.TextXAlignment.Left
equippedLabel.Parent = leftPanel

-- Trail 목록 스크롤 프레임
local trailList = Instance.new("ScrollingFrame")
trailList.Name = "TrailList"
trailList.Size = UDim2.new(1, 0, 1, -75)
trailList.Position = UDim2.new(0, 0, 0, 72)
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

local trailListStroke = Instance.new("UIStroke")
trailListStroke.Color = COLORS.woodLight
trailListStroke.Thickness = 3
trailListStroke.Parent = trailList

local trailGridLayout = Instance.new("UIGridLayout")
trailGridLayout.CellSize = UDim2.new(0, 120, 0, 145)
trailGridLayout.CellPadding = UDim2.new(0, 10, 0, 10)
trailGridLayout.SortOrder = Enum.SortOrder.LayoutOrder
trailGridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
trailGridLayout.Parent = trailList

local trailPadding = Instance.new("UIPadding")
trailPadding.PaddingTop = UDim.new(0, 10)
trailPadding.PaddingBottom = UDim.new(0, 10)
trailPadding.PaddingLeft = UDim.new(0, 10)
trailPadding.PaddingRight = UDim.new(0, 10)
trailPadding.Parent = trailList

-- 미리보기 생성 함수
local function createPreviewBarrel()
	-- 기존 미리보기 정리
	for _, part in pairs(previewTrailParts) do
		part:Destroy()
	end
	previewTrailParts = {}

	if previewBarrelModel then
		previewBarrelModel:Destroy()
	end

	-- 배럴 모델 생성 (간단한 원통)
	local barrel = Instance.new("Part")
	barrel.Name = "PreviewBarrel"
	barrel.Shape = Enum.PartType.Cylinder
	barrel.Size = Vector3.new(1.5, 1, 1)
	barrel.CFrame = CFrame.new(0, 0, 0) * CFrame.Angles(0, 0, math.rad(90))
	barrel.Color = barrelColors[selectedBarrel] or Color3.fromRGB(139, 90, 43)
	barrel.Material = Enum.Material.Wood
	barrel.Anchored = true
	barrel.CanCollide = false
	barrel.Parent = worldModel

	previewBarrelModel = barrel

	-- Trail 이펙트 생성 (미리보기용 파티클)
	local trailName = selectedTrailForPreview
	if not trailName and currentData then
		trailName = currentData.equippedTrails[selectedBarrel]
	end

	if trailName then
		local trailColor = trailColors[trailName] or Color3.fromRGB(200, 200, 200)

		-- Trail 파티클들 생성 (포물선 경로)
		for i = 1, 15 do
			local trailPart = Instance.new("Part")
			trailPart.Name = "TrailPart" .. i
			trailPart.Shape = Enum.PartType.Ball
			trailPart.Size = Vector3.new(0.15, 0.15, 0.15)
			trailPart.Material = Enum.Material.Neon
			trailPart.Anchored = true
			trailPart.CanCollide = false
			trailPart.Transparency = i / 20

			-- 무지개 Trail은 색상 변경
			if trailName == "Rainbow" then
				local hue = (i / 15) % 1
				trailPart.Color = Color3.fromHSV(hue, 1, 1)
			else
				trailPart.Color = trailColor
			end

			trailPart.Parent = worldModel
			table.insert(previewTrailParts, trailPart)
		end
	end

	return barrel
end

-- 미리보기 애니메이션 업데이트
local animationTime = 0
local function updatePreviewAnimation(dt)
	animationTime = animationTime + dt

	if not previewBarrelModel then return end

	-- 배럴 포물선 운동 (반복)
	local t = (animationTime % 2) / 2 -- 0~1 반복
	local x = t * 6 - 3 -- -3 ~ 3
	local y = -2 * (t - 0.5)^2 + 1.5 -- 포물선
	local z = 0

	previewBarrelModel.CFrame = CFrame.new(x, y, z) * CFrame.Angles(animationTime * 5, 0, math.rad(90))

	-- Trail 파티클 위치 업데이트
	for i, trailPart in ipairs(previewTrailParts) do
		local trailT = math.max(0, t - (i * 0.03))
		local trailX = trailT * 6 - 3
		local trailY = -2 * (trailT - 0.5)^2 + 1.5
		trailPart.CFrame = CFrame.new(trailX, trailY, z)

		-- 무지개 Trail 색상 애니메이션
		if selectedTrailForPreview == "Rainbow" or
		   (currentData and currentData.equippedTrails[selectedBarrel] == "Rainbow" and not selectedTrailForPreview) then
			local hue = ((i / 15) + animationTime * 0.5) % 1
			trailPart.Color = Color3.fromHSV(hue, 1, 1)
		end
	end
end

-- 미리보기 업데이트
function updatePreview()
	createPreviewBarrel()

	-- 미리보기 정보 업데이트
	local trailName = selectedTrailForPreview
	if not trailName and currentData then
		trailName = currentData.equippedTrails[selectedBarrel]
	end

	if trailName and currentData and currentData.allTrails[trailName] then
		local trailInfo = currentData.allTrails[trailName]
		previewTrailName.Text = trailInfo.DisplayName
		previewTrailDesc.Text = trailInfo.Description
		previewRarity.Text = trailInfo.Rarity
		previewRarity.TextColor3 = rarityColors[trailInfo.Rarity] or COLORS.parchment

		if trailInfo.Price > 0 then
			previewPrice.Text = "R$ " .. trailInfo.Price
		else
			previewPrice.Text = "무료"
		end
	else
		previewTrailName.Text = "Trail 선택"
		previewTrailDesc.Text = "Trail을 선택하면 미리보기가 표시됩니다."
		previewRarity.Text = ""
		previewPrice.Text = ""
	end
end

-- 배럴 탭 업데이트
function updateBarrelTabs()
	for barrelName, button in pairs(barrelButtons) do
		if barrelName == selectedBarrel then
			button.BackgroundColor3 = COLORS.gold
			button.TextColor3 = COLORS.black
		else
			button.BackgroundColor3 = COLORS.woodLight
			button.TextColor3 = COLORS.parchment
		end
	end
end

-- Trail 목록 업데이트
function updateTrailList()
	-- 기존 Trail 아이템 제거
	for _, frame in pairs(trailFrames) do
		frame:Destroy()
	end
	trailFrames = {}

	if not currentData then
		return
	end

	-- 현재 장착된 Trail 표시
	local equippedTrailName = currentData.equippedTrails[selectedBarrel]
	local equippedTrailInfo = currentData.allTrails[equippedTrailName]
	if equippedTrailInfo then
		equippedLabel.Text = "현재 장착: " .. equippedTrailInfo.DisplayName
	else
		equippedLabel.Text = "현재 장착: 없음"
	end

	-- Trail 목록 생성 (희귀도/가격 순으로 정렬)
	local sortedTrails = {}
	for trailName, trailInfo in pairs(currentData.allTrails) do
		table.insert(sortedTrails, {name = trailName, info = trailInfo})
	end
	table.sort(sortedTrails, function(a, b)
		local rarityA = currentData.rarities[a.info.Rarity] and currentData.rarities[a.info.Rarity].order or 0
		local rarityB = currentData.rarities[b.info.Rarity] and currentData.rarities[b.info.Rarity].order or 0
		if rarityA == rarityB then
			return a.info.Price < b.info.Price
		end
		return rarityA < rarityB
	end)

	for i, trailData in ipairs(sortedTrails) do
		local trailName = trailData.name
		local trailInfo = trailData.info
		local isOwned = table.find(currentData.ownedTrails, trailName) ~= nil
		local isEquipped = currentData.equippedTrails[selectedBarrel] == trailName

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
		frameStroke.Color = isEquipped and COLORS.green or (rarityColors[trailInfo.Rarity] or COLORS.rope)
		frameStroke.Thickness = isEquipped and 3 or 2
		frameStroke.Parent = trailFrame

		-- 아이콘 영역 (Trail 색상으로 표시)
		local iconFrame = Instance.new("Frame")
		iconFrame.Size = UDim2.new(1, -12, 0, 55)
		iconFrame.Position = UDim2.new(0, 6, 0, 6)
		iconFrame.BackgroundColor3 = trailColors[trailName] or COLORS.woodDark
		iconFrame.BorderSizePixel = 0
		iconFrame.Parent = trailFrame

		local iconCorner = Instance.new("UICorner")
		iconCorner.CornerRadius = UDim.new(0, 6)
		iconCorner.Parent = iconFrame

		-- 장착됨 표시
		if isEquipped then
			local equippedBadge = Instance.new("TextLabel")
			equippedBadge.Size = UDim2.new(0, 45, 0, 16)
			equippedBadge.Position = UDim2.new(1, -47, 0, 2)
			equippedBadge.BackgroundColor3 = COLORS.green
			equippedBadge.TextColor3 = Color3.new(1, 1, 1)
			equippedBadge.Text = "장착중"
			equippedBadge.TextSize = 9
			equippedBadge.Font = Enum.Font.GothamBold
			equippedBadge.Parent = iconFrame

			local badgeCorner = Instance.new("UICorner")
			badgeCorner.CornerRadius = UDim.new(0, 4)
			badgeCorner.Parent = equippedBadge
		end

		-- 희귀도 표시
		local rarityLabel = Instance.new("TextLabel")
		rarityLabel.Size = UDim2.new(1, 0, 0, 14)
		rarityLabel.Position = UDim2.new(0, 0, 0, 64)
		rarityLabel.BackgroundTransparency = 1
		rarityLabel.TextColor3 = rarityColors[trailInfo.Rarity] or COLORS.parchment
		rarityLabel.Text = trailInfo.Rarity
		rarityLabel.TextSize = 10
		rarityLabel.Font = Enum.Font.GothamBold
		rarityLabel.Parent = trailFrame

		-- Trail 이름
		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(1, -6, 0, 16)
		nameLabel.Position = UDim2.new(0, 3, 0, 80)
		nameLabel.BackgroundTransparency = 1
		nameLabel.TextColor3 = COLORS.parchment
		nameLabel.Text = trailInfo.DisplayName
		nameLabel.TextSize = 11
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
		nameLabel.Parent = trailFrame

		-- 버튼 (장착/구매)
		local actionButton = Instance.new("TextButton")
		actionButton.Size = UDim2.new(1, -12, 0, 24)
		actionButton.Position = UDim2.new(0, 6, 1, -30)
		actionButton.Font = Enum.Font.GothamBold
		actionButton.TextSize = 10
		actionButton.Parent = trailFrame

		local buttonCorner = Instance.new("UICorner")
		buttonCorner.CornerRadius = UDim.new(0, 6)
		buttonCorner.Parent = actionButton

		if isOwned then
			if isEquipped then
				actionButton.BackgroundColor3 = COLORS.rope
				actionButton.TextColor3 = COLORS.parchment
				actionButton.Text = "장착됨"
				actionButton.Active = false
			else
				actionButton.BackgroundColor3 = COLORS.green
				actionButton.TextColor3 = Color3.new(1, 1, 1)
				actionButton.Text = "장착하기"

				actionButton.MouseButton1Click:Connect(function()
					local result = equipTrailFunc:InvokeServer(selectedBarrel, trailName)
					if result and result.success then
						selectedTrailForPreview = nil
					end
				end)
			end
		else
			if trailInfo.Price > 0 then
				actionButton.BackgroundColor3 = COLORS.blue
				actionButton.TextColor3 = Color3.new(1, 1, 1)
				actionButton.Text = "R$ " .. trailInfo.Price

				actionButton.MouseButton1Click:Connect(function()
					purchaseTrailFunc:InvokeServer(trailName)
				end)
			else
				actionButton.BackgroundColor3 = COLORS.gold
				actionButton.TextColor3 = COLORS.black
				actionButton.Text = "무료"

				actionButton.MouseButton1Click:Connect(function()
					purchaseTrailFunc:InvokeServer(trailName)
				end)
			end
		end

		-- 클릭 시 미리보기 선택
		trailFrame.MouseButton1Click:Connect(function()
			selectedTrailForPreview = trailName
			updatePreview()

			-- 선택 표시 업데이트
			for name, frame in pairs(trailFrames) do
				local stroke = frame:FindFirstChildOfClass("UIStroke")
				if stroke then
					local info = currentData.allTrails[name]
					local equipped = currentData.equippedTrails[selectedBarrel] == name
					if name == trailName then
						stroke.Color = COLORS.gold
						stroke.Thickness = 3
					elseif equipped then
						stroke.Color = COLORS.green
						stroke.Thickness = 3
					else
						stroke.Color = rarityColors[info.Rarity] or COLORS.rope
						stroke.Thickness = 2
					end
				end
			end
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
		selectedTrailForPreview = nil
		updateTrailList()
		updatePreview()
	else
		warn("[TrailShopGui] Trail 데이터 로드 실패:", result)
	end
end

-- 서버에서 데이터 업데이트 수신
trailDataUpdated.OnClientEvent:Connect(function(data)
	if currentData then
		currentData.ownedTrails = data.ownedTrails
		currentData.equippedTrails = data.equippedTrails
		selectedTrailForPreview = nil
		updateTrailList()
		updatePreview()
	end
end)

-- GUI 활성화/비활성화 처리
trailGui:GetPropertyChangedSignal("Enabled"):Connect(function()
	if trailGui.Enabled then
		loadTrailData()
		-- 미리보기 애니메이션 시작
		if previewConnection then
			previewConnection:Disconnect()
		end
		previewConnection = RunService.RenderStepped:Connect(updatePreviewAnimation)
	else
		-- 미리보기 애니메이션 중지
		if previewConnection then
			previewConnection:Disconnect()
			previewConnection = nil
		end
	end
end)

-- 초기 상태: 비활성화
trailGui.Enabled = false
