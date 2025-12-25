local model = script.Parent

-- Configuration 폴더와 WaitTime 동적 생성
local configuration = script:FindFirstChild("Configuration")
if not configuration then
	configuration = Instance.new("Configuration")
	configuration.Name = "Configuration"
	configuration.Parent = script
end

local waitTime = configuration:FindFirstChild("WaitTime")
if not waitTime then
	waitTime = Instance.new("IntValue")
	waitTime.Name = "WaitTime"
	waitTime.Value = 10 -- 기본값
	waitTime.Parent = configuration
end

local function resetWaitTime(newTime)
	waitTime.Value = newTime
end

waitTime:GetPropertyChangedSignal("Value"):Connect(function()
	resetWaitTime(waitTime.Value)
end)

local bindableEvent = Instance.new("BindableEvent")
bindableEvent.Name = "OnPartRemoving"
bindableEvent.Parent = model

while waitTime.Value > 0 do
	wait(1)
	waitTime.Value = waitTime.Value - 1
end

-- 파츠 삭제 전에 Slower 스크립트로 신호 보내기
bindableEvent:Fire()

wait(0.1)  -- 파츠가 삭제되기 전에 잠시 대기
model:Destroy()
