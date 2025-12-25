local player = game.Players.LocalPlayer
local GuiFactory = require(script.Parent:WaitForChild("GuiFactory"))

-- CurrentGold가 없으면 동적으로 생성
local currentGold = script.Parent:FindFirstChild("CurrentGold")
if not currentGold then
	currentGold = GuiFactory.CreateCurrentGold()
	currentGold.Parent = script.Parent
end

-- AlertMessage Frame이 없으면 동적으로 생성
local alertFrame = script.Parent:FindFirstChild("Frame")
if not alertFrame then
	alertFrame = GuiFactory.CreateAlertFrame()
	alertFrame.Parent = script.Parent
end

-- GuiId가 없으면 생성
if not script.Parent:FindFirstChild("GuiId") then
	local guiId = GuiFactory.CreateGuiId(801)
	guiId.Parent = script.Parent
end

-- leaderstats가 존재할 때까지 기다립니다.
local leaderstats = player:WaitForChild("leaderstats")
local coins = leaderstats:WaitForChild("Coins")

local function updateGold()
	currentGold.Text = "골드 : " .. coins.Value
end

coins.Changed:Connect(updateGold)

-- 스크립트가 시작될 때 초기 텍스트를 설정합니다.
updateGold()
