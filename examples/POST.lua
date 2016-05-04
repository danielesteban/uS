-- Power-on self-test
 
local timezone = 1 -- GMT +01
local dst = true   -- Daylight Saving Time
 
local now = timetable(time(), timezone, dst)
log("Fecha:    " .. now:date())
log("Hora:     " .. now:time())
timezone = nil
dst = nil
now = nil
collectgarbage()
 
log("Heap:     " .. heap())
log("GC Count: " .. collectgarbage("count"))
