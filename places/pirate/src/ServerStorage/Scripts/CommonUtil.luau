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
	if not part then
		return false
	end
	local Self = require(script)
	if not Self:GetHumanoidByPart(part) then
		return false
	end

	return true
end

-- 파트에서 캐릭터를 찾고 해당 플레이어를 반환
function CommonUtil:GetPlayerByPart(part)
	if not part then
		return nil
	end

	local character = nil
	if part.Parent and part.Parent:FindFirstChild("Humanoid") then
		character = part.Parent
	elseif part.Parent and part.Parent.Parent and part.Parent.Parent:FindFirstChild("Humanoid") then
		character = part.Parent.Parent
	end

	if not character then
		return nil
	end

	local Players = game:GetService("Players")
	return Players:GetPlayerFromCharacter(character)
end

-- 두 플레이어가 같은 팀인지 확인
function CommonUtil:IsSameTeam(player1, player2)
	if not player1 or not player2 then
		return false
	end
	return player1.Team and player2.Team and player1.Team == player2.Team
end

return CommonUtil
