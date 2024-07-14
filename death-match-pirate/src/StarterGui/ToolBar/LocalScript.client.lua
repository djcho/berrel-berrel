game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.Backpack,false)

local toolBarCount = 9
local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local players = game:GetService("Players")
local player = players.LocalPlayer
local backPack = player.Backpack

local toolbar = script.Parent
local toolArray = {}

local SurfaceTarget = require(script.Parent:WaitForChild("SurfaceTarget"))

local numberDictionary = 
	{
		[Enum.KeyCode.One] = 1, [Enum.KeyCode.Two] = 2, [Enum.KeyCode.Three] = 3,
		[Enum.KeyCode.Four] = 4, [Enum.KeyCode.Five] = 5, [Enum.KeyCode.Six] = 6,
		[Enum.KeyCode.Seven] = 7, [Enum.KeyCode.Eight] = 8, [Enum.KeyCode.Nine] = 9
	}

local function EquipTool(toolName)
	for _, v in pairs(backPack:GetChildren()) do
		if v:IsA("Tool") and v.Name == toolName  then
			SurfaceTarget:DrawSurfaceTarget()
			local humanoid = player.Character.Humanoid
			if humanoid  then
				humanoid:EquipTool(v)
				break
			end
		end
	end
end

local playerUnequipToolEvent = ReplicatedStorage:WaitForChild("PlayerUnequipToolEvent")
local function UnequipTool()
	local humanoid = player.Character.Humanoid
	if humanoid  then
		humanoid:UnequipTools()
		SurfaceTarget:RemoveSurfaceTarget()
	end
end

local function AllToolBarDeselected()
	UnequipTool()
	
	for i, v in pairs(toolArray)  do
		v.ToolItem.DeselectedEvent:Fire()		
	end
end

local function SelectToolBar(selectedToolItem)
	if selectedToolItem.ToolItem.Selected.Value  then
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
	
	if inputState == Enum.UserInputState.Begin  then
		SelectToolBar(toolArray[numberDictionary[inputObject.KeyCode]])
	end
end

local function LoadBackPack()
	local index = 1
	local fixTable = {"NormalBarrel"}
	
	for i = 1, #fixTable do
		local tool = backPack:FindFirstChild(fixTable[i])
		toolArray[i].ToolItem.Icon.Image = tool.TextureId
		toolArray[i].ToolItem.ToolName.Value = tool.Name
	end
	
	local sortTable = {}
	for _, v in pairs(backPack:GetChildren()) do
		if v:IsA("Tool")  then
			if table.find(fixTable, v.Name)  then
				continue
			end
			
			table.insert(sortTable, v)
		end
	end
	
	table.sort(sortTable, function(a,b)
		return a.Name > b.Name
	end)
	
	for i = 1, #sortTable do
		toolArray[i+#fixTable].ToolItem.Icon.Image = sortTable[i].TextureId
		toolArray[i+#fixTable].ToolItem.ToolName.Value = sortTable[i].Name
	end
end

local function OnMouseButton1Down(index)
	SelectToolBar(toolArray[index])
end

local function RenderToolBar() 
	
	local frame = script.Parent:FindFirstChild("Frame", true) 
	toolArray[1] = script.Parent:FindFirstChild("MoveableFrame", true) 
	toolArray[1].ToolItem.Icon.MouseButton1Down:Connect(function()
		OnMouseButton1Down(1)
	end)
	
	local toolClone = nil
	for i = 1 , toolBarCount-1 do
		toolClone = toolArray[1]:Clone()
		toolClone.Position = UDim2.new(toolClone.Position.X.Scale + 0.06 * i, 
			toolClone.Position.X.Offset,
			toolClone.Position.Y.Scale,
			toolClone.Position.Y.Offset)
		toolClone.Parent =  toolArray[1].Parent		
		toolClone.ToolItem.Number.Text = i + 1
		toolClone.ToolItem.Icon.MouseButton1Down:Connect(function()
			OnMouseButton1Down(i + 1)
		end)
		toolArray[i+1] = toolClone
	end
	
	LoadBackPack()
end

RenderToolBar()
ContextActionService:BindAction("SelectToolBar", OnSelectedToolBar, false,
	Enum.KeyCode.One, Enum.KeyCode.Two,	Enum.KeyCode.Three,
	Enum.KeyCode.Four, Enum.KeyCode.Five, Enum.KeyCode.Six,
	Enum.KeyCode.Seven, Enum.KeyCode.Eight,	Enum.KeyCode.Nine)

local toolBarAddItemEvent = ReplicatedStorage.RemoteEvent.ToolBarAddItemEvent
toolBarAddItemEvent.OnClientEvent:Connect(function(newTool)
	for _, moveableFrame in pairs(toolArray) do
		if moveableFrame.ToolItem.ToolName.Value == "" then		
			moveableFrame.ToolItem.Icon.Image = newTool.TextureId
			moveableFrame.ToolItem.ToolName.Value = newTool.Name
			break
		end
	end
end)