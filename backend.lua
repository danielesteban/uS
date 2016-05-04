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
			if data.silent == 0 then
				print("Ejecutando: " .. id .. ".lc")
				print("------------------------------")
			end
			if file.open("script_" .. id .. ".lc") == nil then
				if data.silent == 0 then
					print("Error: El script no existe o no ha sido compilado")
					print("==============================")
				end
			else
				file.close()
				local script = dofile("script_" .. id .. ".lc")
				local status, err = pcall(script, data)
				if data.silent == 0 then
					if not status then
						print("Error: ", err)
					end
					print("==============================")
				end
			end
		end
	end
end
tmr.alarm(0, 1000, tmr.ALARM_AUTO, RunScripts)
RunScripts(true)
