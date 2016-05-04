-- Power-on self-test
 
_G.timezone = 1 -- GMT +01
_G.dst = true   -- Daylight Saving Time
 
local now = timetable(time(), _G.timezone, _G.dst)
log("Fecha:    " .. now:date())
log("Hora:     " .. now:time())
now = nil
collectgarbage()
 
log("Heap:     " .. heap() .. " bytes")
log("GC Count: " .. collectgarbage("count") .. " kilobytes")
