print("*************lua-开始写代码=入口位置-lua******************")
local gologging = require("gologging")

local function init()
	local lastdofiles = {
		"script/gxlua/init.lua",
		"script/do/init.lua",
	}
	for _,v in pairs(lastdofiles) do
		dofiles(v)
	end
end
init()
unitimer.init(110)
print("unitimer.tickmsec:" .. tostring(unitimer.tickmsec))
local timer1 = NewUniTimerClass(nil, 10)
local tick1 = timer1:GetId()
print("tick1:" .. tostring(tick1))
local timer2 = NewUniTimerClass(nil, 20)
local tick2 = timer2:GetId()
print("tick2:" .. tostring(tick2))

function test(...)
	gologging.error(...,{})
end

test("hello word")

