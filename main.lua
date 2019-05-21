local ffi = require("ffi")
local socket = require("socket")
local matrix = require("lib.matrix")

local lpack = require("pack")
local pack = string.pack
local upack = string.unpack

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

local init = false

while true do
	data, ip, port = udp:receivefrom()
	if data then
		print("Received: ",ip,port)
		local _, cmd = upack(data, "b")
		if cmd == 65 then
			matrix:decode_and_init(data)
			init = true
		elseif cmd == 66 and init then
			local _, cmd, px, py, ox, oy = upack(data, "bIIII")
			local data = data:sub(18)
			print("Pixel ",_, cmd, px, py, ox, oy)
			for x=ox,px-1+ox do
				for y=oy,py-1+oy do
					local _,r,g,b = upack(data, "bbb")
					data = data:sub(4)
					print(r,g,b)
					matrix:setPixel(x, y, {r,g,b})
				end
			end
			matrix:send()
		end
	end
	socket.sleep(0.1)
end
