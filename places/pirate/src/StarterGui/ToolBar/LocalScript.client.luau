game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)

local toolBarCount = 9
local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local players = game:GetService("Players")
local player = players.LocalPlayer

local toolbar = script.Parent
local toolArray = {}
local namedQueues = {}

local SurfaceTarget = require(script.Parent:WaitForChild("SurfaceTarget"))
local GuiFactory = require(script.Parent:WaitForChild("GuiFactory"))
local numberDictionary = {
	[Enum.KeyCode.One] = 1, [Enum.KeyCode.Two] = 2, [Enum.KeyCode.Three] = 3,
	[Enum.KeyCode.Four] = 4, [Enum.KeyCode.Five] = 5, [Enum.KeyCode.Six] = 6,
	[Enum.KeyCode.Seven] = 7, [Enum.KeyCode.Eight] = 8, [Enum.KeyCode.Nine] = 9
}

local BarrelStatusUpdateEvent = ReplicatedStorage:WaitForChild("BarrelStatusUpdateEvent")
local RequestInitialBarrelStatus = ReplicatedStorage:WaitForChild("RequestInitialBarrelStatus")

local function createCooldownOverlay(icon)
	local overlay = Instance.new("Frame")
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.BackgroundColor3 = Color3.new(0, 0, 0)
	overlay.BackgroundTransparency = 0.5
	overlay.ClipsDescendants = true
	overlay.Parent = icon
	overlay.ZIndex = 2
	overlay.Name = "CooldownOverlay"
	overlay.Position = UDim2.new(0, 0, 0, 0)

	return overlay
end

local function startCooldown(toolName, icon, duration)
	local overlayName = "CooldownOverlay"
	local overlay = icon:FindFirstChild(overlayName)
	if not overlay then
		overlay = createCooldownOverlay(icon)
	else
		overlay.Size = UDim2.new(1, 0, 1, 0)
		overlay.Position = UDim2.new(0, 0, 0, 0)
	end

	-- namedQueues[toolName]이 nil인 경우 초기화
	if not namedQueues[toolName] then
		namedQueues[toolName] = {}
	end

	while #namedQueues[toolName] > 0 do
		local startTime = namedQueues[toolName][1]
		local elapsed = tick() - startTime

		if elapsed < duration then
			while tick() - startTime < duration do
				local elapsedTime = tick() - startTime
				local progress = elapsedTime / duration
				overlay.Size = UDim2.new(1, 0, 1 - progress, 0)
				wait(0.03)
			end
			table.remove(namedQueues[toolName], 1)
		else
			table.remove(namedQueues[toolName], 1)
		end
	end

	overlay:Destroy()
end

BarrelStatusUpdateEvent.OnClientEvent:Connect(function(toolName, shotIndex, shotLeft, reloading, duration)	
	for _, tool in pairs(toolArray) do
		if tool.ToolItem.ToolName.Value == toolName then
			tool.ToolItem.Stack.Text = tostring(shotLeft)
			if reloading then
				if not namedQueues[toolName] then
					namedQueues[toolName] = {}
				end

				table.insert(namedQueues[toolName], tick())
				if #namedQueues[toolName] == 1 then
					coroutine.wrap(function()					
						startCooldown(toolName, tool.ToolItem.Icon, duration)
					end)()
				end
			end
			break
		end
	end
end)

local function EquipTool(toolName)
	local backPack = player:WaitForChild("Backpack")
	for _, v in pairs(backPack:GetChildren()) do
		if v:IsA("Tool") and v.Name == toolName then
			SurfaceTarget:DrawSurfaceTarget()
			local humanoid = player.Character.Humanoid
			if humanoid then
				humanoid:EquipTool(v)
				break
			end
		end
	end
end

local function UnequipTool()
	local humanoid = player.Character.Humanoid
	if humanoid then
		humanoid:UnequipTools()
		SurfaceTarget:RemoveSurfaceTarget()
	end
end

local function AllToolBarDeselected()
	UnequipTool()

	for i, v in pairs(toolArray) do
		v.ToolItem.DeselectedEvent:Fire()
	end
end

local function SelectToolBar(selectedToolItem)
	if selectedToolItem.ToolItem.Selected.Value then
		selectedToolItem.ToolItem.DeselectedEvent:Fire()
		UnequipTool(selectedToolItem.ToolItem.ToolName.Value)
	else
		AllToolBarDeselected()
		selectedToolItem.ToolItem.SelectedEvent:Fire()
		EquipTool(selectedToolItem.ToolItem.ToolName.Value)
	end
end

local function OnSelectedToolBar(actionName, inputState, inputObject)
	if not player.Character then
		return
	end

	if inputState == Enum.UserInputState.Begin then
		SelectToolBar(toolArray[numberDictionary[inputObject.KeyCode]])
	end
end

local function LoadBackPack()
	print("로드백팩")
	local sortTable = {}
	while not player do
		wait()
		player = players.LocalPlayer
	end

	-- 플레이어의 백팩 가져오기
	local backPack = player:WaitForChild("Backpack")
	for _, v in pairs(backPack:GetChildren()) do
		if v:IsA("Tool") then
			table.insert(sortTable, v)
		end
	end

	local initialBarrelStatus = RequestInitialBarrelStatus:InvokeServer()

	for i = 1, #sortTable do
		local toolName = sortTable[i].Name
		toolArray[i].ToolItem.Icon.Image = sortTable[i].TextureId
		toolArray[i].ToolItem.ToolName.Value = toolName
		local toolStatus = initialBarrelStatus[toolName] or {ToolName = toolName, MaxShots = 0, ShotLeft = 0, Reloading = {}, ReloadTime = 0}
		toolArray[i].ToolItem.Stack.Text = tostring(toolStatus.ShotLeft)
		for _, isReloading in pairs(toolStatus.Reloading) do
			if isReloading then
				coroutine.wrap(function()
					startCooldown(toolName, toolArray[i].ToolItem.Icon, toolStatus.ReloadTime)
				end)()
			end
		end
	end
end

local function OnMouseButton1Down(index)
	SelectToolBar(toolArray[index])
end

local function ClearToolBar()
	-- 기존 툴바 초기화
	for i = #toolArray, 1, -1 do
		if toolArray[i] then
			toolArray[i]:Destroy()  -- 툴바 항목을 파괴 (게임에서 제거)
			table.remove(toolArray, i)  -- 배열에서 해당 항목 제거
		end
	end
end


local function RenderToolBar()
	ClearToolBar()

	-- Frame이 없으면 동적으로 생성
	local frame = script.Parent:FindFirstChild("Frame")
	if not frame then
		frame = GuiFactory.CreateToolBarFrame()
		frame.Parent = script.Parent
	end

	for i = 0, toolBarCount do
		-- GuiFactory로 MoveableFrame 동적 생성 (ReplicatedStorage Clone 대신)
		local moveableFrame = GuiFactory.CreateMoveableFrame()
		moveableFrame.Parent = frame
		moveableFrame.LayoutOrder = i

		moveableFrame.ToolItem.Number.Text = tostring(i + 1)
		moveableFrame.ToolItem.Icon.MouseButton1Down:Connect(function()
			OnMouseButton1Down(i + 1)
		end)
		toolArray[i + 1] = moveableFrame
	end

	LoadBackPack()
end


ContextActionService:BindAction("SelectToolBar", OnSelectedToolBar, false,
	Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three,
	Enum.KeyCode.Four, Enum.KeyCode.Five, Enum.KeyCode.Six,
	Enum.KeyCode.Seven, Enum.KeyCode.Eight, Enum.KeyCode.Nine)

-- 초기 렌더링
RenderToolBar()

-- 새 아이템 추가 시 다시 렌더링
local toolBarAddItemEvent = ReplicatedStorage:WaitForChild("ToolBarAddItemEvent")
toolBarAddItemEvent.OnClientEvent:Connect(function()
	RenderToolBar()
end)
