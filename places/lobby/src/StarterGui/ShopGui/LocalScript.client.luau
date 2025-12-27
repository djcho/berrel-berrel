local shopGui = script.Parent

-- 해적 컨셉 색상
local COLORS = {
	woodDark = Color3.fromRGB(62, 39, 22),      -- 어두운 나무
	woodLight = Color3.fromRGB(101, 67, 33),    -- 밝은 나무
	gold = Color3.fromRGB(255, 200, 50),        -- 금화
	goldDark = Color3.fromRGB(180, 140, 30),    -- 어두운 금
	parchment = Color3.fromRGB(210, 180, 140),  -- 양피지
	rope = Color3.fromRGB(139, 119, 83),        -- 밧줄
	red = Color3.fromRGB(150, 40, 40),          -- 해적 빨강
	black = Color3.fromRGB(20, 15, 10),         -- 검정
}

-- 메인 프레임 (나무 상자 느낌)
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0.65, 0, 0.75, 0)
mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mainFrame.BackgroundColor3 = COLORS.woodDark
mainFrame.BorderSizePixel = 0
mainFrame.Parent = shopGui

-- 메인 프레임 둥근 모서리
local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 12)
mainCorner.Parent = mainFrame

-- 메인 프레임 테두리 (금색)
local mainStroke = Instance.new("UIStroke")
mainStroke.Color = COLORS.goldDark
mainStroke.Thickness = 4
mainStroke.Parent = mainFrame

-- 상단 장식 바
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

-- 타이틀 생성
local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "TitleLabel"
titleLabel.Size = UDim2.new(1, -100, 1, 0)
titleLabel.Position = UDim2.new(0, 20, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.TextColor3 = COLORS.gold
titleLabel.Text = "해적 보물 상점"
titleLabel.TextSize = 28
titleLabel.Font = Enum.Font.GothamBlack
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = topBar

-- 타이틀 그림자 효과
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

-- 닫기 버튼 (해적 스타일)
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
	shopGui.Enabled = false
end)

-- 카테고리 탭 영역
local categoryFrame = Instance.new("Frame")
categoryFrame.Name = "CategoryFrame"
categoryFrame.Size = UDim2.new(1, -20, 0, 40)
categoryFrame.Position = UDim2.new(0, 10, 0, 60)
categoryFrame.BackgroundTransparency = 1
categoryFrame.Parent = mainFrame

local categoryLayout = Instance.new("UIListLayout")
categoryLayout.FillDirection = Enum.FillDirection.Horizontal
categoryLayout.SortOrder = Enum.SortOrder.LayoutOrder
categoryLayout.Padding = UDim.new(0, 10)
categoryLayout.Parent = categoryFrame

local categories = {"스킨", "펫", "이펙트", "특별 아이템"}
for i, catName in ipairs(categories) do
	local catButton = Instance.new("TextButton")
	catButton.Name = catName
	catButton.Size = UDim2.new(0, 100, 1, 0)
	catButton.BackgroundColor3 = i == 1 and COLORS.gold or COLORS.woodLight
	catButton.TextColor3 = i == 1 and COLORS.black or COLORS.parchment
	catButton.Text = catName
	catButton.TextSize = 14
	catButton.Font = Enum.Font.GothamBold
	catButton.LayoutOrder = i
	catButton.Parent = categoryFrame

	local catCorner = Instance.new("UICorner")
	catCorner.CornerRadius = UDim.new(0, 6)
	catCorner.Parent = catButton
end

-- 상품 목록 스크롤 프레임 (양피지 느낌)
local itemList = Instance.new("ScrollingFrame")
itemList.Name = "ItemList"
itemList.Size = UDim2.new(1, -20, 1, -120)
itemList.Position = UDim2.new(0, 10, 0, 110)
itemList.BackgroundColor3 = COLORS.parchment
itemList.BorderSizePixel = 0
itemList.ScrollBarThickness = 8
itemList.ScrollBarImageColor3 = COLORS.woodDark
itemList.CanvasSize = UDim2.new(0, 0, 0, 0)
itemList.AutomaticCanvasSize = Enum.AutomaticSize.Y
itemList.Parent = mainFrame

local itemListCorner = Instance.new("UICorner")
itemListCorner.CornerRadius = UDim.new(0, 8)
itemListCorner.Parent = itemList

local itemListStroke = Instance.new("UIStroke")
itemListStroke.Color = COLORS.woodLight
itemListStroke.Thickness = 3
itemListStroke.Parent = itemList

-- UIGridLayout으로 그리드 형태로 배치
local uiGridLayout = Instance.new("UIGridLayout")
uiGridLayout.CellSize = UDim2.new(0, 150, 0, 180)
uiGridLayout.CellPadding = UDim2.new(0, 15, 0, 15)
uiGridLayout.SortOrder = Enum.SortOrder.LayoutOrder
uiGridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
uiGridLayout.Parent = itemList

local uiPadding = Instance.new("UIPadding")
uiPadding.PaddingTop = UDim.new(0, 15)
uiPadding.PaddingBottom = UDim.new(0, 15)
uiPadding.PaddingLeft = UDim.new(0, 15)
uiPadding.PaddingRight = UDim.new(0, 15)
uiPadding.Parent = itemList

-- 샘플 상품 (해적 테마)
local shopItems = {
	{name = "해적 선장 스킨", price = 500, category = "스킨", rarity = "레어"},
	{name = "유령 해적 스킨", price = 1000, category = "스킨", rarity = "에픽"},
	{name = "앵무새 펫", price = 300, category = "펫", rarity = "일반"},
	{name = "해골 원숭이 펫", price = 800, category = "펫", rarity = "레어"},
	{name = "금화 이펙트", price = 200, category = "이펙트", rarity = "일반"},
	{name = "유령불 이펙트", price = 600, category = "이펙트", rarity = "레어"},
	{name = "전설의 보물지도", price = 2000, category = "특별 아이템", rarity = "전설"},
	{name = "해적왕의 나침반", price = 1500, category = "특별 아이템", rarity = "에픽"},
}

local rarityColors = {
	["일반"] = Color3.fromRGB(150, 150, 150),
	["레어"] = Color3.fromRGB(50, 150, 255),
	["에픽"] = Color3.fromRGB(180, 50, 255),
	["전설"] = Color3.fromRGB(255, 180, 0),
}

for i, item in ipairs(shopItems) do
	local itemFrame = Instance.new("Frame")
	itemFrame.Name = "Item" .. i
	itemFrame.BackgroundColor3 = COLORS.woodLight
	itemFrame.BorderSizePixel = 0
	itemFrame.LayoutOrder = i
	itemFrame.Parent = itemList

	local itemCorner = Instance.new("UICorner")
	itemCorner.CornerRadius = UDim.new(0, 8)
	itemCorner.Parent = itemFrame

	local itemStroke = Instance.new("UIStroke")
	itemStroke.Color = rarityColors[item.rarity] or COLORS.rope
	itemStroke.Thickness = 2
	itemStroke.Parent = itemFrame

	-- 아이템 이미지 영역
	local imageFrame = Instance.new("Frame")
	imageFrame.Size = UDim2.new(1, -20, 0, 80)
	imageFrame.Position = UDim2.new(0, 10, 0, 10)
	imageFrame.BackgroundColor3 = COLORS.woodDark
	imageFrame.BorderSizePixel = 0
	imageFrame.Parent = itemFrame

	local imageCorner = Instance.new("UICorner")
	imageCorner.CornerRadius = UDim.new(0, 6)
	imageCorner.Parent = imageFrame

	-- 등급 표시
	local rarityLabel = Instance.new("TextLabel")
	rarityLabel.Size = UDim2.new(1, 0, 0, 18)
	rarityLabel.Position = UDim2.new(0, 0, 0, 95)
	rarityLabel.BackgroundTransparency = 1
	rarityLabel.TextColor3 = rarityColors[item.rarity] or COLORS.parchment
	rarityLabel.Text = item.rarity
	rarityLabel.TextSize = 12
	rarityLabel.Font = Enum.Font.GothamBold
	rarityLabel.Parent = itemFrame

	-- 아이템 이름
	local itemName = Instance.new("TextLabel")
	itemName.Size = UDim2.new(1, -10, 0, 20)
	itemName.Position = UDim2.new(0, 5, 0, 115)
	itemName.BackgroundTransparency = 1
	itemName.TextColor3 = COLORS.parchment
	itemName.Text = item.name
	itemName.TextSize = 12
	itemName.Font = Enum.Font.GothamBold
	itemName.TextTruncate = Enum.TextTruncate.AtEnd
	itemName.Parent = itemFrame

	-- 구매 버튼
	local buyButton = Instance.new("TextButton")
	buyButton.Size = UDim2.new(1, -20, 0, 30)
	buyButton.Position = UDim2.new(0, 10, 1, -40)
	buyButton.BackgroundColor3 = COLORS.gold
	buyButton.TextColor3 = COLORS.black
	buyButton.Text = item.price .. " Gold"
	buyButton.TextSize = 14
	buyButton.Font = Enum.Font.GothamBold
	buyButton.Parent = itemFrame

	local buyCorner = Instance.new("UICorner")
	buyCorner.CornerRadius = UDim.new(0, 6)
	buyCorner.Parent = buyButton

	-- 호버 효과
	buyButton.MouseEnter:Connect(function()
		buyButton.BackgroundColor3 = COLORS.goldDark
	end)
	buyButton.MouseLeave:Connect(function()
		buyButton.BackgroundColor3 = COLORS.gold
	end)
end

-- 초기 상태: 비활성화
shopGui.Enabled = false
