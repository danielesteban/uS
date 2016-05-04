-- µS Main API

local Scripts = function()
	local data
	if file.open("scripts.json") == nil then
		data = {}
	else
		data = ""
		local read = file.read(1024)
		while read ~= nil do
			collectgarbage()
			data = data .. read
			read = file.read(1024)
		end
		file.close()
		data = cjson.decode(data) or {}
		read = nil
		collectgarbage()
	end
	local files = file.list()
	for name,size in pairs(files) do
		if string.sub(name, 1, 7) == "script_" and string.sub(name, -4) == ".lua" then
			local id = string.sub(name, 8, -5)
			if data[id] == nil then
				data[id] = {
					trigger = "manual",
					interval = 30,
					silent = 0
				}
			end
		end
	end
	return data
end

local EditScript = function(id, code)
	local name = "script_" .. id
	local prefix = {
		"return function(config)",
		"if ScriptsGlobalScope == nil then ScriptsGlobalScope = {} end",
		"if ScriptScope_" .. id .. " == nil then ScriptScope_" .. id .. " = {} end",
		"local _G=ScriptsGlobalScope",
		"local collectgarbage=collectgarbage",
		"local gpio=gpio",
		"local heap=node.heap",
		"local http=http",
		"local print=print",
		"local string=string",
		"local table=table",
		"local time=rtctime.get",
		"local ws2812=ws2812",
		"local timetable=function(ts, tz, dst)",
		"return dofile('timetable.lc')(ts, tz, dst)",
		"end",
		"local log=function(...)",
		"if config.silent == 0 then print(...) end",
		"end",
		"setfenv(1, ScriptScope_" .. id .. ")"
	}
	local suffix = {
		"end"
	}
	for i,line in ipairs(code) do
		local mode
		if i == 1 then mode = "w" else mode = "a+" end
		file.open(name .. ".lua", mode)
		file.writeline(line)
		file.close()
	end
	for i,line in ipairs(prefix) do
		local mode
		if i == 1 then mode = "w" else mode = "a+" end
		file.open(name .. "_bytecode.lua", mode)
		file.writeline(line)
		file.close()
	end
	prefix = nil
	collectgarbage()
	for i,line in ipairs(code) do
		file.open(name .. "_bytecode.lua", "a+")
		file.writeline(line)
		file.close()
	end
	code = nil
	collectgarbage()
	for i,line in ipairs(suffix) do
		file.open(name .. "_bytecode.lua", "a+")
		file.writeline(line)
		file.close()
	end
	suffix = nil
	collectgarbage()
	file.remove(name .. ".lc")
	if pcall(node.compile, name .. "_bytecode.lua") then
		file.rename(name .. "_bytecode.lc", name .. ".lc")
	else
		print("ERROR compiling: " .. id)
	end
	file.remove(name .. "_bytecode.lua")
end

local SendHeader = function(connection, status, mimetype)
	connection:send("HTTP/1.0 " .. (status or "200 OK") .. "\r\nContent-Type: " .. (mimetype or "application/json") .. "; charset=utf-8\r\nConnection: close\r\n\r\n")
end

return function(App)
	return function(connection, params)
		if params[1] ~= App.password then
			SendHeader(connection, "401 Unauthorized")
			connection:send("Unauthorized")
			return
		end
		
		if params[2] == "heap" then
			SendHeader(connection)
			connection:send(cjson.encode(node.heap()))
		elseif params[2] == "status" then
			local scripts = Scripts()
			local epoch = {rtctime.get()}
			SendHeader(connection)
			connection:send(cjson.encode({
				boot = App.boot,
				epoch = epoch,
				scripts = scripts
			}))
		elseif params[2] == "log" or params[2] == "script" then
			SendHeader(connection, nil, "text/plain")
			local filename
			if params[2] == "log" then
				filename = "output.log"
			else
				filename = "script_" .. params[3] .. ".lua"
			end

			local size = file.list()[filename]
			if size == nil or size == 0 then
				return
			end

			local continue = true
			local bytesSent = 0
			local chunkSize = 1024
			while continue do
				collectgarbage()
				file.open(filename)
				file.seek("set", bytesSent)
				local chunk = file.read(chunkSize)
				file.close()
				connection:send(chunk)
				bytesSent = bytesSent + #chunk
				chunk = nil
				if bytesSent == size then continue = false end
			end
		elseif params[2] == "editScript" and #params >= 6 then
			local id = params[3]
			local scripts = Scripts()
			if scripts[id] == nil then
				scripts[id] = {}
			end
			scripts[id].trigger = params[4]
			scripts[id].interval = tonumber(params[5])
			scripts[id].silent = tonumber(params[6])
			if #params > 6 then
				local code = {}
				for i=7,#params do
					table.insert(code, params[i])
				end
				EditScript(id, code)
				code = nil
				collectgarbage()
			end
			local json = cjson.encode(scripts)
			file.open("scripts.json", "w")
			file.write(json)
			file.close()
			connection:send(json)
		elseif params[2] == "removeScript" and params[3] then
			local id = params[3]
			local name = "script_" .. id
			local scripts = Scripts()
			local json
			if scripts[id] ~= nil then
				scripts[id] = nil
				json = cjson.encode(scripts)
				file.open("scripts.json", "w")
				file.write(json)
				file.close()
			else
				json = cjson.encode(scripts)
			end
			file.remove(name .. ".lua")
			file.remove(name .. ".lc")
			SendHeader(connection)
			connection:send(json)
		elseif params[2] == "runScript" and params[3] then
			local scripts = Scripts()
			local id = params[3]
			local data = scripts[id]
			SendHeader(connection)
			if data == nil then
				return
			end
			if data.silent == 0 then
				print(id .. ".lc")
				print("------------------------------")
			end
			if file.open("script_" .. id .. ".lc") == nil then
				if data.silent == 0 then
					print("Error: File not found")
					print("==============================")
				end
			else
				file.close()
				local script = dofile("script_" .. id .. ".lc")
				local status, err = pcall(script, data)
				if status then
					connection:send("1")
				end
				if data.silent == 0 then
					if status == false then
						print("Error: ", err)
					end
					print("==============================")
				end
			end
		elseif params[2] == "restart" then
			node.restart()
		else
			SendHeader(connection, "404 Not found")
			connection:send("Not found")
		end
	end
end
