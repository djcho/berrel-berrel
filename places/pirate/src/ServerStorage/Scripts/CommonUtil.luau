local CommonUtil = {}
CommonUtil.__index = CommonUtil

function CommonUtil.new()
	return setmetatable({}, CommonUtil)
end

function CommonUtil:ScaleModel(model, scale)
	local primary = model.PrimaryPart
	local primaryCf = primary.CFrame

	for _,v in pairs(model:GetDescendants()) do
		if (v:IsA("BasePart")) then
			v.Size = Vector3.new(v.Size.X * scale,v.Size.Y,v.Size.Z * scale)
			if (v ~= primary) then
				v.CFrame = (primaryCf + (primaryCf:inverse() * v.Position * scale))
			end
		end
	end

	return model
end

function CommonUtil:GetHumanoidByPart(part)
	if not part  then
		return nil
	end
	
	local humanoid = nil
	if part.Parent and part.Parent:FindFirstChild("Humanoid") then
		humanoid = part.Parent:FindFirstChild("Humanoid")
	elseif part.Parent.Parent and part.Parent.Parent:FindFirstChild("Humanoid")  then
		humanoid = part.Parent.Parent:FindFirstChild("Humanoid")
	else
		return nil
	end
	
	return humanoid
end

function CommonUtil:IsPartIncludedCharacter(part)
	if not part  then
		return false
	end
	local Self = require(script)
	if not Self:GetHumanoidByPart(part) then
		return false
	end
	
	return true
end

return CommonUtil
