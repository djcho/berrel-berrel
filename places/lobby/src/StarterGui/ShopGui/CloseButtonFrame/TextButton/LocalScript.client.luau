local button = script.Parent
local shopGui = script.Parent.Parent.Parent

button.MouseButton1Click:Connect(function()
	if shopGui then
		shopGui.Enabled = false -- ShopGui를 활성화
	end
end)