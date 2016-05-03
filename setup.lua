-- µS Setup API

return function(App)
	return function(connection, params)
		connection:send("HTTP/1.0 200 OK\r\nContent-Type: application/json; charset=utf-8\r\nConnection: close\r\n\r\n")
		if params[1] == "networks" then
			connection:send(App.networks or "{}")
		elseif params[1] == "config" and #params >= 5 then
			file.open("config.lua", "w")
			file.writeline([[-- µS Configuration File]])
			file.writeline([[]])
			file.writeline([[local Config = {]])
			file.writeline([[  wifi = {]])
			file.writeline([[    mode = wifi.STATION,]])
			file.writeline([[    ssid = "]] .. params[2] .. [[",]])
			file.writeline([[    password = "]] .. params[3] .. [["]])
			file.writeline([[  },]])
			file.writeline([[  app = {]])
			file.writeline([[    id = "main",]])
			file.writeline([[    backend = "backend",]])
			file.writeline([[    password = "]] .. params[4] .. [[",]])
			file.writeline([[    host = "]] .. params[5] .. [["]])
			file.writeline([[  }]])
			if params[6] and params[7] then
				file.writeline([[  ,noip = {]])
				file.writeline([[    host = "]] .. params[6] .. [[",]])
				file.writeline([[    auth = "]] .. params[7] .. [["]])
				file.writeline([[  },]])
			end
			file.writeline([[}]])
			file.writeline([[]])
			file.writeline([[return Config]])
			file.close()
			node.compile("config.lua")
			file.remove("config.lua")
			wifi.ap.deauth()
			node.restart()
		end
	end
end
