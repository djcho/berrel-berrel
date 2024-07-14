local model = script.Parent
if script.Configuration.WaitTime and script.Configuration.WaitTime.Value ~= 0 then
	wait(script.Configuration.WaitTime.Value)
	model:Destroy()
end

