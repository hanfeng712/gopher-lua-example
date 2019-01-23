print("*************lua-开始写代码=入口位置-lua******************")
function init()
	dofiles("lua_script/gxlua/unitimer.lua")
	dofiles("lua_script/do/RandomReturnAward.lua")
end
init()
unitimer.init(110)
print("unitimer.tickmsec:" .. tostring(unitimer.tickmsec))
