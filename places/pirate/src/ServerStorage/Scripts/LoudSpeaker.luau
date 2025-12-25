-- 특정 혹은 모든 클라이언트에게 메시지나 소리를 전송시키는 클래스
-- 대상 플레이어를 입력하지 않을 경우에는 모든 클라이언트로 전송된다.  
local LoudSpeakerEvent = game.ReplicatedStorage.LoudSpeakerEvent
local LoudSpeaker = {}
LoudSpeaker.__index = LoudSpeaker

function LoudSpeaker.new(targetPlayer)
	local self = setmetatable({}, LoudSpeaker)	
	self.TargetPlayer = targetPlayer
	
	return self
end

function LoudSpeaker:SetTargetPlayer(targetPlayer)
	self.TargetPlayer = targetPlayer
end

function LoudSpeaker:DoTalk(message)
	if message == nil and not self.TargetPlayer then
		return 
	end
	
	LoudSpeakerEvent:FireClient(self.TargetPlayer, message)
end

function LoudSpeaker:DoShout(message)
	if message == nil and not self.TargetPlayer then
		return 
	end
	
	LoudSpeakerEvent:FireAllClients(message)
end

function LoudSpeaker:PlayAlone(sound)
	if sound == nil then
		return 
	end
	if self.TargetPlayer then
		LoudSpeakerEvent:FireClient(self.TargetPlayer, sound)
	end
end

function LoudSpeaker:PlayLoudly(sound)
	if sound == nil then
		return 
	end
	
	LoudSpeakerEvent:FireAllClients(sound)
end

return LoudSpeaker
