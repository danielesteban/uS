-- µS Init File

node.egc.setmode(node.egc.ON_ALLOC_FAILURE)
if file.list()["config.lc"] then
	dofile("logger.lc")("output.log")
	Config = dofile("config.lc")
else
	Config = dofile("configure.lc")
	if Config == nil then
		return
	end
end

wifi.setmode(Config.wifi.mode)
wifi.setphymode(wifi.PHYMODE_G)
if Config.wifi.mode == wifi.SOFTAP then
	wifi.ap.config({
		ssid = Config.wifi.ssid
	})
	if Config.wifi.ip ~= nil then
		wifi.ap.setip(Config.wifi.ip)
	end
else
	wifi.sta.config(Config.wifi.ssid, Config.wifi.password, 1)
	if Config.wifi.ip ~= nil then
		wifi.sta.setip(Config.wifi.ip)
	end
end

local joinCounter = 0
local joinMaxAttempts = 5
print("==============================")
tmr.alarm(0, 3000, tmr.ALARM_AUTO, function()
	local ip = wifi.sta.getip() or wifi.ap.getip()
	if ip == nil and joinCounter < joinMaxAttempts then
		print('Conectando a: ' .. Config.wifi.ssid .. '...')
		joinCounter = joinCounter + 1
	else
		tmr.stop(0)
		if joinCounter == joinMaxAttempts then
			print('FAIL! Reseteando config...')
			file.remove("config.lc")
			node.restart()
			return
		end
		print('IP: ', ip)
		print("==============================")
		local App = Config.app
		mdns.register(App.host, {
			description = "µS",
			service = "http",
			port = 80
		})
		if Config.noip then
			http.get("http://dynupdate.no-ip.com/nic/update?hostname=" .. Config.noip.host, "Authorization: Basic " .. Config.noip.auth .. "\r\n")
			Config.noip = nil
		end
		App.host = nil
		joinCounter = nil
		joinMaxAttempts = nil
		Config = nil
		collectgarbage()
		if App.id == "setup" then
			dofile("server.lc")(App)
		else
			sntp.sync('es.pool.ntp.org', function(sec, usec)
				App.boot = {sec, usec}
				dofile("server.lc")(App)
			end)
		end
	end
end)
