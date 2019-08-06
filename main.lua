local ffi			= require("ffi")
local socket		= require("socket")
local Matrix		= require("lib.librgbmatrix")
local MatrixWS2811	= require("lib.libws2811")

local lpack = require("pack")
local pack = string.pack
local upack = string.unpack

udp = socket.udp()
udp:setsockname("*", 1234)
udp:settimeout(1)

local CMD_INIT_MATRIX	= 0
local CMD_INIT_WS2811	= 4
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

matrix = MatrixWS2811:new(16,16)

local i = 0
while i<5000 do
	for y=0,15 do
		for x=0,15 do
			-- if y%2 == 0 then
				local c = color_wheel(i+x+y)
				matrix:setPixel(x,y,c)
			-- else
				-- local c = color_wheel(i+128)
				-- local c = 0
				-- matrix:clear()
				-- matrix:setPixel(x,y,c)
			-- end

		end
	end
	matrix:render()
	socket.sleep(0.001)
	i = i + 1
end
matrix:clear()
matrix:render()

local matrix

while true do
	local data, ip, port = udp:receivefrom()
	if data then
		local _, cmd = upack(data, "b")
		print("Received: ",ip,port, cmd, #data)
		if cmd == CMD_INIT then
			matrix = Matrix:new(data)
			init = true
		elseif cmd == CMD_INIT_WS2811 then
			matrix = MatrixWS2811:new(16,16)
			init = true
		elseif cmd == CMD_SQR and init then
			local _, cmd, px, py, ox, oy = upack(data, "bIIII")
			local prev = 1
			local r,g,b = 0,0,0
			local data = data:sub(18)
			-- print("Pixel ",_, cmd, px, py, ox, oy)
			for y=oy,py-1+oy do
				for x=ox,px-1+ox do
					prev,r,g,b = upack(data, "bbb", prev)
					if r then
						matrix:setRGB(x,y,r,g,b)
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
					matrix:setRGB((off+i)%lx, (off+i)/lx, r,g,b)
				-- end
			end
			if cmd == CMD_SEND_UPDATE then
				matrix:render()
			end
		end
	end
	-- socket.sleep(0.0001)
end
