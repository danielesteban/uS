-- µS HTTP Server

local BufferedConnection = function(connection)
	local instance = {}
	instance.connection = connection
	instance.size = 0
	instance.data = {}

	function instance:flush()
		if self.size > 0 then
			self.connection:send(table.concat(self.data, ""))
			self.data = {}
			self.size = 0
			return true
		end
		return false
	end

	function instance:send(payload)
		local flushthreshold = 1400

		local newsize = self.size + payload:len()
		while newsize > flushthreshold do
			local piecesize = flushthreshold - self.size
			local piece = payload:sub(1, piecesize)
			payload = payload:sub(piecesize + 1, -1)
			table.insert(self.data, piece)
			self.size = self.size + piecesize
			if self:flush() then
			  coroutine.yield()
			end
			newsize = self.size + payload:len()
		end
		    
		local plen = payload:len()
		if plen == flushthreshold then
			table.insert(self.data, payload)
			self.size = self.size + plen
			if self:flush() then
				coroutine.yield()
			end
		elseif payload:len() then
			table.insert(self.data, payload)
			self.size = self.size + plen
		end
	end

	return instance
end

local ServeError = function(connection, params)
	connection:send("HTTP/1.0 " .. params.code .. " " .. params.text .. "\r\nContent-Type: text/plain; charset=utf-8\r\nConnection: close\r\n\r\n")
	connection:send(params.text)
end

local ServeStatic = function(connection, params)
	connection:send("HTTP/1.0 200 OK\r\nContent-Type: " .. (params.mime or "text/plain") .. "; charset=utf-8\r\nCache-Control: max-age=21600\r\nConnection: close\r\n\r\n")
	local size = file.list()[params.file]
	if size == nil or size == 0 then
		return
	end
	local continue = true
	local bytesSent = 0
	local chunkSize = 1024
	while continue do
		collectgarbage()
		file.open(params.file)
		file.seek("set", bytesSent)
		local chunk = file.read(chunkSize)
		file.close()
		connection:send(chunk)
		bytesSent = bytesSent + #chunk
		chunk = nil
		if bytesSent == size then continue = false end
	end
end

return function(App)
	local s = net.createServer(net.TCP, 10)
	s:listen(App.port or 80, function(connection)
		local connectionThread
		local function startServing(connection, handler, params)
			connectionThread = coroutine.create(function(handler, bc, params)
				handler(bc, params)
				if not bc:flush() then
					connection:close()
					connectionThread = nil
				end
			end)

			local bc = BufferedConnection(connection)
			local status, err = coroutine.resume(connectionThread, handler, bc, params)
			if not status then
				print("Error: ", err)
			end
		end

		local function onReceive(connection, request)
			collectgarbage()
			local _, _, method, path = string.find(request, "([A-Z]+) (.+) HTTP")
			local handler = nil
			local params = nil
			if method ~= "GET" then
				handler = ServeError
				params = {
					code = 405,
					text = 'Not allowed'
				}
			else
				if path == "/" or path == "/app.js" or path == "/lib.js" or path == "/screen.css" then
					handler = ServeStatic
					params = {}
					if path == "/" then
						params.file = App.id .. ".html"
						params.mime = "text/html"
					elseif path == "/app.js" then
						params.file = App.id .. ".js"
						params.mime = "application/javascript"
					elseif path == "/lib.js" then
						params.file = "lib.js"
						params.mime = "application/javascript"
					elseif path == "/screen.css" then
						params.file = "screen.css"
						params.mime = "text/css"
					end
				elseif string.sub(path, 1, 5) == "/api/" then
					path = string.sub(path, 6)
					collectgarbage()
					handler = dofile(App.id .. ".lc")(App)
					params = {}
					local n = 1
					for val in path:gmatch("([^/]*)") do
						if val == "" then
							n = n + 1
						else
							params[n] = val:gsub("%%(%x%x)", function(x)
								return string.char(tonumber(x, 16))
							end)
						end
					end
				else
					handler = ServeError
					params = {
						code = 404,
						text = 'Not found'
					}
				end
			end
			path = nil
			collectgarbage()
			startServing(connection, handler, params)
		end

		local function onSent(connection)
			collectgarbage()
			if connectionThread then
				local connectionThreadStatus = coroutine.status(connectionThread)
				if connectionThreadStatus == "suspended" then
					local status, err = coroutine.resume(connectionThread)
					if not status then
						print(err)
					end
				elseif connectionThreadStatus == "dead" then
					connection:close()
					connectionThread = nil
				end
			end
		end

		local function onDisconnect()
			if connectionThread then
				connectionThread = nil
				collectgarbage()
			end
		end

		connection:on("receive", onReceive)
		connection:on("sent", onSent)
		connection:on("disconnection", onDisconnect)
	end)
	if App.backend then
		dofile(App.backend .. ".lc")
	end
end
