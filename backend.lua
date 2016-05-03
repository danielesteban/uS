-- µS Main Backend

local RunCounter = 3599
local RunScripts = function(boot)
	if file.open("scripts.json") == nil then
		return
	end
	local scripts = ""
	local read = file.read(1024)
	while read ~= nil do
		collectgarbage()
		scripts = scripts .. read
		read = file.read(1024)
	end
	file.close()
	scripts = cjson.decode(scripts) or {}
	read = nil
	collectgarbage()

	RunCounter = RunCounter + 1
	if RunCounter == 3600 then
		RunCounter = 0
	end

	for id,data in pairs(scripts) do
		if (data.trigger == 'interval' or (boot and data.trigger == 'boot')) and RunCounter % data.interval == 0 then
			if data.interval >= 10 then print(id .. ".lc") end
			local status, err = pcall(dofile, "script_" .. id .. ".lc")
			if status == false then
				print("Error: ", err)
			end
			if data.interval >= 10 or status == false then print("==============================") end
		end
	end
end
tmr.alarm(0, 1000, tmr.ALARM_AUTO, RunScripts)
RunScripts(true)
