local ffi = require("ffi")
local socket = require("socket")
local struct = require("lib.struct")
local matrix = require("lib.matrix")

udp = socket.udp()
udp:setsockname("*", 1234)
udp:settimeout(0)

function color_wheel(WheelPos)
	WheelPos = WheelPos % 255
	WheelPos = 255 - WheelPos
	if (WheelPos < 85) then
		return {255 - WheelPos * 3, 0, WheelPos * 3}
	elseif (WheelPos < 170) then
		WheelPos = WheelPos - 85
		return {0, WheelPos * 3, 255 - WheelPos * 3}
	else
		WheelPos = WheelPos - 170
		return {WheelPos * 3, 255 - WheelPos * 3, 0}
	end
end


matrix:init({
	rows = 32,
	cols = 64,
	chain_length = 2,
	hardware_mapping = "adafruit-hat",
	pixel_mapper_config = "U-mapper"
})
--
while true do
	data, ip, port = udp:receivefrom()
	if data then
		print("Received: ",ip,port)
		print(data)
		for x=0,64-1 do
			for y=0,64-1 do
				local c = color_wheel(x+y)
				matrix:setPixel(x,y,c)
			end
		end
		matrix:send()
	end
	socket.sleep(0.1)
end
