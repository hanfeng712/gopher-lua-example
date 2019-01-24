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
unilight.debug("lua脚本加载完毕")
print("time:" .. tostring(os.time) .. ", os.msectime:" .. tostring(os.msectime()) .. ", os.nsectime:" .. tostring(os.nsectime()))
