-- µS Setup Configuration File

local Networks
if file.open("networks.json", "r") == nil then
	print("Scanning for networks...")
	wifi.setmode(wifi.STATION)
	wifi.sta.getap({}, 1, function(networks)
		file.open("networks.json", "w+")
		file.write(cjson.encode(networks))
		file.flush()
		file.close()
		node.restart()
	end)
	return
else
	Networks = ""
	local read = file.read(1024)
	while read ~= nil do
		collectgarbage()
		Networks = Networks .. read
		read = file.read(1024)
	end
	file.close()
	file.remove("networks.json")
	read = nil
	collectgarbage()
end

local Config = {
	wifi = {
		mode = wifi.SOFTAP,
		ssid = "µS Setup",
		ip = {
			ip = "192.168.1.1",
			netmask = "255.255.255.0",
			gateway = "192.168.1.1"
		}
	},
	app = {
		id = "setup",
		host = "userver",
		networks = Networks
	}
}

return Config
