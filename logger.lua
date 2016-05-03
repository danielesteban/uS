-- µS Output Logger

local Truncate = function(log)
	local size = file.list()[log]
	local offset = size - 1000
	file.remove(log .. ".old")
	file.rename(log, log .. ".old")
	file.open(log .. ".old", "r")
	file.seek("set", offset)
	local line = file.readline()
	file.close()
	offset = offset + #line
	line = nil
	collectgarbage()
	local continue = true
	local chunkSize = 1024
	while continue do
		collectgarbage()
		file.open(log .. ".old")
		file.seek("set", offset)
		local chunk = file.read(chunkSize)
		file.close()
		file.open(log, "a+")
		file.write(chunk)
		file.close()
		offset = offset + #chunk
		chunk = nil
		if offset == size then continue = false end
	end
	file.remove(log .. ".old")
end

return function(log)
	file.remove(log)
	node.output(function(str)
		collectgarbage()
		if (file.list()[log] or 0) >= 10000 then
			Truncate(log)
		end
		file.open(log, "a+")
		file.write(str)
		file.close()
	end, 0)
end
