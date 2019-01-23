print("*************lua-开始写代码=入口位置-lua******************")
local function init()
	local lastdofiles = {
		"lua_script/gxlua/init.lua",
		"lua_script/do/init.lua",
	}
	for _,v in pairs(lastdofiles) do
		dofiles(v)
	end
end
init()
unitimer.init(110)
print("unitimer.tickmsec:" .. tostring(unitimer.tickmsec))
