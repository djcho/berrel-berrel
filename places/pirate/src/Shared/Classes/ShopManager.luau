local ReplicatedStorage = game:GetService("ReplicatedStorage")
local requestItemCount = ReplicatedStorage:WaitForChild("RequestItemCount")
local activateItemEvent = ReplicatedStorage:WaitForChild("ActivateItemEvent")
local ShopManager = {}
ShopManager.__index = ShopManager

function ShopManager.new(sayingEvent)
	local self = setmetatable({}, ShopManager)
	
	self.SayingEvent = sayingEvent
	self.ManagedItems = {}
	self.TargetShelfs = {}

	return self
end
	
	
function ShopManager:DisplayItems(targetShelf, items, onClickFunc)
	if not items  then
		print("DisplayItems failed. items is nil.")
		return
	end
	
	if not targetShelf then
		print("DisplayItems failed. targetShelf is nil.")
		return
	end
	
	for _, item in pairs(items) do
		table.insert(self.ManagedItems, item)
	end
	
	table.insert(self.TargetShelfs, targetShelf)

	for _, item in pairs(items) do
		local imageButton = Instance.new("ImageButton")
		local uIiAspectRatioConstraint = Instance.new("UIAspectRatioConstraint")
		local intValue = Instance.new("IntValue")
		intValue.Name = "ItemId"
		intValue.Parent = imageButton
		intValue.Value = item.Id
		uIiAspectRatioConstraint.Parent = imageButton
		
		imageButton.Parent = targetShelf
		imageButton.Name = item.DisplayName
		imageButton.Image = item.TextureId
		imageButton.BackgroundColor3 = Color3.new(0.768627, 0.682353, 0.596078)
		imageButton.BorderColor3 = Color3.new(0.105882, 0.164706, 0.207843)
		imageButton.Size = UDim2.new(1, 0, 1, 0)
		imageButton.MouseButton1Click:Connect(function()
			onClickFunc(item)
		end)
	end
end

function ShopManager:SelectItem(itemId)
	for _, item in pairs(self.ManagedItems) do
		if item.Id == itemId then
			return item
		end
	end
end


function ShopManager:CountItem(itemId)
	local result = requestItemCount:InvokeServer(itemId)
	if result.Result then
		if self.SayingEvent then
			self:Say(result.Message)
		end
		return true
	else
		self:Say(result.Message)
	end
	return false
end

function ShopManager:Say(message)
	self.SayingEvent:Fire(message)
end

function ShopManager:PurchaseItem(itemId)
	local result = requestItemCount:InvokeServer(itemId)
	if not result.Result then
		if self.SayingEvent then
			self:Say(result.Message)
		end
		--return false
	end
	
	activateItemEvent:FireServer(itemId)
	self:Say(result.Message)

	return true
end

function ShopManager:ClearItems()
	table.clear(self.ManagedItems)
	for _, targetShelf in pairs(self.TargetShelfs) do
		for _,  v in pairs(targetShelf:GetChildren()) do
			if v:IsA("UIListLayout") then
				continue
			end
			v:Destroy()
		end
	end
	self.ManagedItems = {}
	self.TargetShelfs = {}
end

return ShopManager
