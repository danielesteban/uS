-- Isolated global scope
if STATE == nil then STATE = 6 end
STATE = STATE + 1
if STATE > 6 then STATE = 1 end
 
-- Output Test
local RGB = function(r, g, b)
	ws2812.write(2, string.char(g, r, b))
end
 
if STATE == 1 then
	for i=0,508 do RGB(i/4, 0, 0) end
elseif STATE == 2 then
	for i=0,508 do RGB(127 - i/4, 0, 0) end
elseif STATE == 3 then
	for i=0,508 do RGB(0, i/4, 0) end
elseif STATE == 4 then
	for i=0,508 do RGB(0, 127 - i/4, 0) end
elseif STATE == 5 then
	for i=0,508 do RGB(0, 0, i/4) end
elseif STATE == 6 then
	for i=0,508 do RGB(0, 0, 127 - i/4) end
end
 
RGB = nil
collectgarbage()
