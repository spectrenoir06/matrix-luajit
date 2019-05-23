local ffi = require("ffi")
local socket = require("socket")
local matrix = require("lib.matrix")

local lpack = require("pack")
local pack = string.pack
local upack = string.unpack

udp = socket.udp()
udp:setsockname("*", 12345)
-- udp:settimeout(1)

local CMD_INIT			= 0
local CMD_SQR 			= 1
local CMD_SEND			= 2
local CMD_SEND_UPDATE	= 3

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
		local _, cmd = upack(data, "b")
		-- print("Received: ",ip,port, cmd, #data)
		if cmd == CMD_INIT then
			matrix:decode_and_init(data)
			init = true
		elseif cmd == CMD_SQR and init then
			local _, cmd, px, py, ox, oy = upack(data, "bIIII")
			local data = data:sub(18)
			-- print("Pixel ",_, cmd, px, py, ox, oy)
			for y=oy,py-1+oy do
				for x=ox,px-1+ox do
					local _,r,g,b = upack(data, "bbb")
					data = data:sub(4)
					if r then
						matrix:setPixel(x, y, {r,g,b})
					end
				end
			end
			matrix:send()
		elseif (cmd == CMD_SEND or cmd == CMD_SEND_UPDATE) and init then
			local _, cmd, off, len = upack(data, "bII")
			data = data:sub(10)
			local prev = 1
			local r,g,b = 0,0,0
			local lx = matrix.lx
			for i=0,len-1 do
				prev,r,g,b = upack(data, "bbb", prev)
				-- data = data:sub(4)
				-- if r then
					--matrix:setPixel((off+i)%matrix.lx, (off+i)/matrix.lx, {r,g,b})
					matrix:set_color((off+i)%lx, (off+i)/lx, r,g,b)
				-- end
			end
			if cmd == CMD_SEND_UPDATE then
				matrix:send()
			end
		end
	end
	-- socket.sleep(0.0001)
end
