--[[
	WindBarrel: 바람통
	강력한 바람으로 적을 밀어내고, 기름/독 구름을 확산시킵니다.
]]

local ServerStorage = game:GetService("ServerStorage")
local TweenService = game:GetService("TweenService")

local BaseBarrel = require(script.Parent.BaseBarrel)
local ItemDb = require(ServerStorage.Items.Database.ItemDb)

local WindBarrel = setmetatable({}, BaseBarrel)
WindBarrel.__index = WindBarrel

function WindBarrel.new(player, toolInfo, level)
	local self = BaseBarrel.new(player, toolInfo, level)
	setmetatable(self, WindBarrel)

	-- ItemDb에서 바람 전용 설정 가져오기
	local itemConfig = ItemDb.Tool["WindBarrel"]
	self.WindSpreadRadius = itemConfig.WindSpreadRadius or 20
	self.GasPushDistance = itemConfig.GasPushDistance or 25
	self.OilPushDistance = itemConfig.OilPushDistance or 15
	self.KnockbackForce = toolInfo.KnockbackForce or itemConfig.KnockbackForce or 80

	return self
end

function WindBarrel:OnTouched(hitPart)
	self:DealDamageToTarget(hitPart, self.HitDamage)
end

function WindBarrel:Throw(targetPosition)
	BaseBarrel.Throw(self, targetPosition)
end

-- 넉백 적용 함수
function WindBarrel:ApplyKnockback(character, explosionOrigin)
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChild("Humanoid")

	if not humanoidRootPart or not humanoid or humanoid.Health <= 0 then
		return
	end

	local direction = (humanoidRootPart.Position - explosionOrigin).Unit
	direction = Vector3.new(direction.X, 0.3, direction.Z).Unit

	local bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
	bodyVelocity.Velocity = direction * self.KnockbackForce
	bodyVelocity.Parent = humanoidRootPart

	game.Debris:AddItem(bodyVelocity, 0.3)
end

-- 가스/기름 확산 효과 (바람으로 밀어냄)
function WindBarrel:SpreadPoolsWithWind(explosionOrigin)
	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Exclude
	overlapParams.FilterDescendantsInstances = {self.Player.Character}

	local partsInRadius = workspace:GetPartBoundsInRadius(explosionOrigin, self.WindSpreadRadius, overlapParams)
	local processedModels = {}

	for _, part in partsInRadius do
		if part.Parent and not processedModels[part.Parent] then
			local parentName = part.Parent.Name

			-- 가스 구름 확산
			if parentName:match("Poison") then
				processedModels[part.Parent] = true
				self:PushModel(part.Parent, explosionOrigin, self.GasPushDistance)

				-- 가스 범위 확대 효과
				for _, poisonPart in part.Parent:GetChildren() do
					if poisonPart:IsA("BasePart") then
						local currentSize = poisonPart.Size
						local newSize = currentSize * 1.3
						local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Sine)
						local tween = TweenService:Create(poisonPart, tweenInfo, {Size = newSize})
						tween:Play()
					end
				end

				-- 불이 붙어있으면 WindBoosted 설정
				for _, child in part.Parent:GetDescendants() do
					if child.Name == "ToxicFireSpread" or child.Name == "FireSpread" then
						child:SetAttribute("WindBoosted", true)
					end
				end

			-- 기름 웅덩이 밀어내기
			elseif parentName:match("Oil") then
				processedModels[part.Parent] = true
				self:PushModel(part.Parent, explosionOrigin, self.OilPushDistance)

				-- 불이 붙어있으면 WindBoosted 설정
				for _, child in part.Parent:GetDescendants() do
					if child.Name == "FireSpread" then
						child:SetAttribute("WindBoosted", true)
					end
				end
			end
		end
	end
end

-- 바닥 높이를 찾는 함수
function WindBarrel:FindGroundHeight(position, model)
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = {model}

	local rayOrigin = Vector3.new(position.X, position.Y + 50, position.Z)
	local rayDirection = Vector3.new(0, -100, 0)

	local result = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
	if result then
		return result.Position.Y
	end
	return position.Y
end

-- 모델을 바람 방향으로 밀어내는 함수
function WindBarrel:PushModel(model, explosionOrigin, distance)
	local primaryPart = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
	if not primaryPart then return end

	local direction = (primaryPart.Position - explosionOrigin).Unit
	direction = Vector3.new(direction.X, 0, direction.Z).Unit

	local targetPosition = primaryPart.Position + direction * distance
	local groundY = self:FindGroundHeight(targetPosition, model)

	local lowestY = math.huge
	for _, part in model:GetChildren() do
		if part:IsA("BasePart") then
			local bottomY = part.Position.Y - part.Size.Y / 2
			if bottomY < lowestY then
				lowestY = bottomY
			end
		end
	end

	local heightAdjustment = groundY - lowestY + 0.1
	targetPosition = Vector3.new(targetPosition.X, primaryPart.Position.Y + heightAdjustment, targetPosition.Z)

	local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

	local lastTween = nil
	for _, part in model:GetChildren() do
		if part:IsA("BasePart") then
			local offset = part.Position - primaryPart.Position
			local targetPos = targetPosition + offset
			local tween = TweenService:Create(part, tweenInfo, {Position = targetPos})
			tween:Play()
			lastTween = tween
		end
	end

	if lastTween then
		lastTween.Completed:Connect(function()
			self:RefreshZoneScripts(model)
		end)
	end
end

-- Slower, PoisonDamage 스크립트를 재시작하여 영역 재계산
function WindBarrel:RefreshZoneScripts(model)
	local bindableEvent = model:FindFirstChild("OnPartRemoving")
	if bindableEvent then
		bindableEvent:Fire()
	end

	task.wait(0.1)

	local newBindableEvent = Instance.new("BindableEvent")
	newBindableEvent.Name = "OnPartRemoving"
	newBindableEvent.Parent = model

	local slower = model:FindFirstChild("Slower")
	if slower then
		slower:Destroy()
		local newSlower = ServerStorage.Scripts.Slower:Clone()
		newSlower.Parent = model
	end

	local poisonDamage = model:FindFirstChild("PoisonDamage")
	if poisonDamage then
		local ownerName = poisonDamage:GetAttribute("PoisonOwner")
		local damageMultiplier = poisonDamage:GetAttribute("DamageMultiplier")
		poisonDamage:Destroy()
		local newPoisonDamage = ServerStorage.Scripts.PoisonDamage:Clone()
		if ownerName then
			newPoisonDamage:SetAttribute("PoisonOwner", ownerName)
		end
		if damageMultiplier then
			newPoisonDamage:SetAttribute("DamageMultiplier", damageMultiplier)
		end
		newPoisonDamage.Parent = model
	end

	local toxicDamage = model:FindFirstChild("ToxicSlimeDamage")
	if toxicDamage then
		local ownerName = toxicDamage:GetAttribute("PoisonOwner")
		local damageMultiplier = toxicDamage:GetAttribute("DamageMultiplier")
		toxicDamage:Destroy()
		local newToxicDamage = ServerStorage.Scripts.PoisonDamage:Clone()
		newToxicDamage.Name = "ToxicSlimeDamage"
		if ownerName then
			newToxicDamage:SetAttribute("PoisonOwner", ownerName)
		end
		if damageMultiplier then
			newToxicDamage:SetAttribute("DamageMultiplier", damageMultiplier)
		end
		newToxicDamage.Parent = model
	end
end

function WindBarrel:Explode(hitPart, hitPosition)
	if BaseBarrel.Explode(self, hitPart, hitPosition) == false then
		return
	end

	local explosionOrigin = self.BarrelPart.Position
	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Exclude
	overlapParams.FilterDescendantsInstances = {self.Player.Character}
	local partsInRadius = workspace:GetPartBoundsInRadius(explosionOrigin, self.ExplosionRadius, overlapParams)

	local processedCharacters = {}
	for _, part in partsInRadius do
		local character = part.Parent
		local humanoid = character and character:FindFirstChild("Humanoid")

		if humanoid and not processedCharacters[character] then
			processedCharacters[character] = true

			local targetPlayer = game.Players:GetPlayerFromCharacter(character)
			if targetPlayer and targetPlayer ~= self.Player then
				if not (self.Player.Team and targetPlayer.Team and self.Player.Team == targetPlayer.Team) then
					self:ApplyKnockback(character, explosionOrigin)
					self:DealDamageToTarget(part, self.HitDamage)
				end
			elseif not targetPlayer then
				self:ApplyKnockback(character, explosionOrigin)
				self:DealDamageToTarget(part, self.HitDamage)
			end
		end
	end

	-- 가스/기름/불 확산 효과
	self:SpreadPoolsWithWind(explosionOrigin)
end

return WindBarrel
