--local players = game:GetService("Players")
--local runService = game:GetService("RunService")

--local player = players.LocalPlayer
--local camera = workspace.CurrentCamera

--local function onPlayerAdded(player)	
--	camera.CameraSubject = player.Character.Head
--	camera.CameraType = Enum.CameraType.Fixed
--	camera.FieldOfView = 70
--end


--local function onUpdate()
--	if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then		
--		camera.CFrame = CFrame.new(player.Character.HumanoidRootPart.Position) * 
--			CFrame.new(0, 70, 20, 0.999961913, 0.00848915521, -0.00202239212, 0, 0.231746808, 0.972776115, 0.00872673094, -0.972739041, 0.231737986)
--	end
--end

--players.PlayerAdded:Connect(onPlayerAdded)
--runService:BindToRenderStep("Camera", Enum.RenderPriority.Camera.Value, onUpdate)