game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)

local toolBarCount = 9
local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local players = game:GetService("Players")
local player = players.LocalPlayer

local toolbar = script.Parent
local toolArray = {}
local namedQueues = {}

-- 편집 모드 관련 변수
local isEditMode = false
local longPressTime = 0.5  -- 길게 누르기 시간 (초)
local pressStartTime = nil
local pressedSlotIndex = nil
local wobbleConnections = {}
local draggedSlotIndex = nil
local isDragging = false
local dragClone = nil
local toolbarOrder = {}  -- 슬롯 순서 저장
local savedToolbarOrder = {}  -- 사용자 정의 툴바 순서 (toolName 기준)

local SurfaceTarget = require(script.Parent:WaitForChild("SurfaceTarget"))
local GuiFactory = require(script.Parent:WaitForChild("GuiFactory"))
local numberDictionary = {
	[Enum.KeyCode.One] = 1, [Enum.KeyCode.Two] = 2, [Enum.KeyCode.Three] = 3,
	[Enum.KeyCode.Four] = 4, [Enum.KeyCode.Five] = 5, [Enum.KeyCode.Six] = 6,
	[Enum.KeyCode.Seven] = 7, [Enum.KeyCode.Eight] = 8, [Enum.KeyCode.Nine] = 9
}

local BarrelStatusUpdateEvent = ReplicatedStorage:WaitForChild("BarrelStatusUpdateEvent")
local RequestInitialBarrelStatus = ReplicatedStorage:WaitForChild("RequestInitialBarrelStatus")

--============================================================
-- 편집 모드 함수들
--============================================================

-- 흔들림 애니메이션 시작
local function startWobbleAnimation(slot)
	if not slot then return end

	local toolItem = slot:FindFirstChild("ToolItem")
	if not toolItem then return end

	-- 기존 연결 해제
	if wobbleConnections[slot] then
		wobbleConnections[slot]:Disconnect()
	end

	local startTime = tick()
	local originalRotation = toolItem.Rotation

	wobbleConnections[slot] = RunService.RenderStepped:Connect(function()
		local elapsed = tick() - startTime
		-- 좌우로 흔들리는 효과 (사인 함수 사용)
		local wobble = math.sin(elapsed * 12) * 2.5
		toolItem.Rotation = originalRotation + wobble
	end)
end

-- 흔들림 애니메이션 중지
local function stopWobbleAnimation(slot)
	if wobbleConnections[slot] then
		wobbleConnections[slot]:Disconnect()
		wobbleConnections[slot] = nil
	end

	local toolItem = slot:FindFirstChild("ToolItem")
	if toolItem then
		toolItem.Rotation = 0
	end
end

-- 편집 모드 진입
local function enterEditMode()
	if isEditMode then return end
	isEditMode = true

	-- 모든 슬롯에 흔들림 애니메이션 적용
	for i, slot in pairs(toolArray) do
		if slot and slot.ToolItem.ToolName.Value ~= "" then
			startWobbleAnimation(slot)
		end
	end

	-- 편집 모드 안내 표시 (toolbar 자체에 라벨 추가, Frame이 아닌)
	local editModeLabel = toolbar:FindFirstChild("EditModeLabel")
	if not editModeLabel then
		editModeLabel = Instance.new("TextLabel")
		editModeLabel.Name = "EditModeLabel"
		editModeLabel.Size = UDim2.new(0, 200, 0, 30)
		editModeLabel.AnchorPoint = Vector2.new(0.5, 1)
		editModeLabel.Position = UDim2.new(0.5, 0, 0, -10)  -- 툴바 위쪽에 표시
		editModeLabel.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
		editModeLabel.BackgroundTransparency = 0.3
		editModeLabel.TextColor3 = Color3.new(1, 1, 1)
		editModeLabel.Text = "드래그하여 순서 변경"
		editModeLabel.TextSize = 14
		editModeLabel.Font = Enum.Font.GothamBold
		editModeLabel.Parent = toolbar  -- toolbar 직접 자식으로

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 6)
		corner.Parent = editModeLabel
	end
	editModeLabel.Visible = true

	-- 페이드 인 애니메이션
	editModeLabel.TextTransparency = 1
	TweenService:Create(editModeLabel, TweenInfo.new(0.3), {TextTransparency = 0}):Play()
end

-- 편집 모드 종료
local function exitEditMode()
	if not isEditMode then return end
	isEditMode = false

	-- 모든 흔들림 애니메이션 중지
	for i, slot in pairs(toolArray) do
		stopWobbleAnimation(slot)
	end

	-- 안내 숨기기
	local editModeLabel = toolbar:FindFirstChild("EditModeLabel")
	if editModeLabel then
		TweenService:Create(editModeLabel, TweenInfo.new(0.2), {TextTransparency = 1}):Play()
		task.delay(0.2, function()
			editModeLabel.Visible = false
		end)
	end

	-- 드래그 중이면 취소
	if dragClone then
		dragClone:Destroy()
		dragClone = nil
	end
	isDragging = false
	draggedSlotIndex = nil
end

-- 두 슬롯의 내용 교환
local function swapSlots(index1, index2)
	if index1 == index2 then return end
	if not toolArray[index1] or not toolArray[index2] then return end

	local slot1 = toolArray[index1]
	local slot2 = toolArray[index2]

	-- 데이터 교환
	local temp = {
		toolName = slot1.ToolItem.ToolName.Value,
		icon = slot1.ToolItem.Icon.Image,
		stack = slot1.ToolItem.Stack.Text
	}

	slot1.ToolItem.ToolName.Value = slot2.ToolItem.ToolName.Value
	slot1.ToolItem.Icon.Image = slot2.ToolItem.Icon.Image
	slot1.ToolItem.Stack.Text = slot2.ToolItem.Stack.Text

	slot2.ToolItem.ToolName.Value = temp.toolName
	slot2.ToolItem.Icon.Image = temp.icon
	slot2.ToolItem.Stack.Text = temp.stack

	-- 순서 배열 업데이트
	toolbarOrder[index1], toolbarOrder[index2] = toolbarOrder[index2], toolbarOrder[index1]

	-- savedToolbarOrder도 업데이트 (toolName 기반 순서 저장)
	local newOrder = {}
	for i, slot in ipairs(toolArray) do
		if slot and slot.ToolItem.ToolName.Value ~= "" then
			newOrder[i] = slot.ToolItem.ToolName.Value
		end
	end
	savedToolbarOrder = newOrder
end

-- 마우스 위치에 있는 슬롯 인덱스 찾기
local function getSlotIndexAtPosition(mousePos)
	local frame = toolbar:FindFirstChild("Frame")
	if not frame then return nil end

	for i, slot in pairs(toolArray) do
		if slot and slot.Parent == frame then
			local absPos = slot.AbsolutePosition
			local absSize = slot.AbsoluteSize

			if mousePos.X >= absPos.X and mousePos.X <= absPos.X + absSize.X and
			   mousePos.Y >= absPos.Y and mousePos.Y <= absPos.Y + absSize.Y then
				return i
			end
		end
	end
	return nil
end

-- 드래그 시작
local function startDrag(slotIndex, mousePos)
	if not toolArray[slotIndex] then return end

	isDragging = true
	draggedSlotIndex = slotIndex

	local slot = toolArray[slotIndex]

	-- 드래그용 복제본 생성
	dragClone = slot.ToolItem:Clone()
	dragClone.Name = "DragClone"
	dragClone.Parent = toolbar
	dragClone.Size = UDim2.new(0, slot.AbsoluteSize.X, 0, slot.AbsoluteSize.Y)
	dragClone.Position = UDim2.new(0, mousePos.X - slot.AbsoluteSize.X/2, 0, mousePos.Y - slot.AbsoluteSize.Y/2)
	dragClone.ZIndex = 100
	dragClone.BackgroundTransparency = 0.3

	-- 원본 슬롯 반투명 처리
	slot.ToolItem.BackgroundTransparency = 0.8
	slot.ToolItem.Icon.ImageTransparency = 0.5
end

-- 드래그 업데이트
local function updateDrag(mousePos)
	if not isDragging or not dragClone then return end

	-- 드래그 복제본 위치 업데이트
	dragClone.Position = UDim2.new(0, mousePos.X - dragClone.AbsoluteSize.X/2, 0, mousePos.Y - dragClone.AbsoluteSize.Y/2)

	-- 현재 마우스 위치의 슬롯 찾기
	local targetIndex = getSlotIndexAtPosition(mousePos)

	if targetIndex and targetIndex ~= draggedSlotIndex then
		-- 슬롯 교환
		swapSlots(draggedSlotIndex, targetIndex)

		-- 원본 슬롯 투명도 복원
		local oldSlot = toolArray[draggedSlotIndex]
		if oldSlot then
			oldSlot.ToolItem.BackgroundTransparency = 0.8
			oldSlot.ToolItem.Icon.ImageTransparency = 0
		end

		-- 새 위치 업데이트
		draggedSlotIndex = targetIndex

		-- 새 슬롯 반투명 처리
		local newSlot = toolArray[draggedSlotIndex]
		if newSlot then
			newSlot.ToolItem.BackgroundTransparency = 0.8
			newSlot.ToolItem.Icon.ImageTransparency = 0.5
		end
	end
end

-- 드래그 종료
local function endDrag()
	if not isDragging then return end

	-- 원본 슬롯 투명도 복원
	if draggedSlotIndex and toolArray[draggedSlotIndex] then
		local slot = toolArray[draggedSlotIndex]
		slot.ToolItem.BackgroundTransparency = 0.8
		slot.ToolItem.Icon.ImageTransparency = 0
	end

	-- 드래그 복제본 제거
	if dragClone then
		dragClone:Destroy()
		dragClone = nil
	end

	isDragging = false
	draggedSlotIndex = nil
end

--============================================================
-- 기존 함수들
--============================================================

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
	if not player.Character then return end
	local backPack = player:WaitForChild("Backpack")
	for _, v in pairs(backPack:GetChildren()) do
		if v:IsA("Tool") and v.Name == toolName then
			SurfaceTarget:DrawSurfaceTarget()
			local humanoid = player.Character:FindFirstChild("Humanoid")
			if humanoid then
				humanoid:EquipTool(v)
				break
			end
		end
	end
end

local function UnequipTool()
	if not player.Character then return end
	local humanoid = player.Character:FindFirstChild("Humanoid")
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
	-- 편집 모드에서는 선택 무시
	if isEditMode then return end

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

	-- 편집 모드에서는 키보드 선택 무시
	if isEditMode then return end

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

	-- 저장된 순서가 있으면 그 순서대로 정렬, 새 아이템은 뒤에 추가
	if #savedToolbarOrder > 0 then
		local orderedTools = {}

		-- 백팩 도구들을 이름으로 맵핑
		local toolsByName = {}
		for _, tool in pairs(sortTable) do
			toolsByName[tool.Name] = tool
		end

		-- 저장된 순서대로 배치
		for _, toolName in ipairs(savedToolbarOrder) do
			if toolsByName[toolName] then
				table.insert(orderedTools, toolsByName[toolName])
				toolsByName[toolName] = nil  -- 처리 완료
			end
		end

		-- 남은 도구들 (새로 해금된 것들) 뒤에 추가
		for _, tool in pairs(sortTable) do
			if toolsByName[tool.Name] then
				table.insert(orderedTools, tool)
			end
		end

		sortTable = orderedTools
	end

	-- savedToolbarOrder 업데이트
	savedToolbarOrder = {}
	for i, tool in ipairs(sortTable) do
		savedToolbarOrder[i] = tool.Name
	end

	-- 순서 배열 초기화
	for i = 1, toolBarCount + 1 do
		toolbarOrder[i] = i
	end

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

local function OnSlotMouseButton1Down(index)
	-- 길게 누르기 감지 시작
	pressStartTime = tick()
	pressedSlotIndex = index

	-- 길게 누르기 체크 코루틴
	coroutine.wrap(function()
		while pressStartTime and pressedSlotIndex == index do
			local elapsed = tick() - pressStartTime
			if elapsed >= longPressTime then
				-- 길게 누르기 완료 - 편집 모드 진입
				if not isEditMode then
					enterEditMode()
					-- 드래그 시작
					local mousePos = UserInputService:GetMouseLocation()
					startDrag(index, mousePos)
				end
				break
			end
			wait(0.05)
		end
	end)()
end

local function OnSlotMouseButton1Up(index)
	local wasLongPress = pressStartTime and (tick() - pressStartTime >= longPressTime)

	pressStartTime = nil
	pressedSlotIndex = nil

	if isEditMode then
		-- 편집 모드에서 드래그 종료
		endDrag()
	elseif not wasLongPress then
		-- 짧은 클릭 - 도구 선택
		SelectToolBar(toolArray[index])
	end
end

local function ClearToolBar()
	-- 편집 모드 종료
	exitEditMode()

	-- 현재 장착 중인 도구 해제
	AllToolBarDeselected()

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

		-- 마우스 다운/업 이벤트 연결
		local slotIndex = i + 1
		moveableFrame.ToolItem.Icon.MouseButton1Down:Connect(function()
			OnSlotMouseButton1Down(slotIndex)
		end)
		moveableFrame.ToolItem.Icon.MouseButton1Up:Connect(function()
			OnSlotMouseButton1Up(slotIndex)
		end)

		toolArray[i + 1] = moveableFrame
	end

	LoadBackPack()
end

--============================================================
-- 입력 이벤트 처리
--============================================================

-- 마우스 이동 처리 (드래그)
UserInputService.InputChanged:Connect(function(input, gameProcessed)
	if input.UserInputType == Enum.UserInputType.MouseMovement then
		if isEditMode and isDragging then
			local mousePos = UserInputService:GetMouseLocation()
			updateDrag(mousePos)
		end
	end
end)

-- 마우스 버튼 해제 처리
UserInputService.InputEnded:Connect(function(input, gameProcessed)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		pressStartTime = nil
		pressedSlotIndex = nil

		if isEditMode then
			endDrag()
		end
	end
end)

-- 화면 다른 곳 클릭 시 편집 모드 종료
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		if isEditMode and not isDragging then
			local mousePos = UserInputService:GetMouseLocation()
			local slotIndex = getSlotIndexAtPosition(mousePos)

			-- 툴바 영역 밖 클릭 시 편집 모드 종료
			if not slotIndex then
				exitEditMode()
			end
		end
	end
end)

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
