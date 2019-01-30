print("*************lua-开始写代码=入口位置-lua******************")
require "script/gxlua_poker/RoomBase"

local function init()
	getLuaFiles("table")
	getLuaFiles("script/gxlua")
	print("")	
	getLuaFiles("script/gxlua_poker")
	getLuaFiles("script/gxlua_laba")
	local lastdofiles = {
		"script/do/init.lua",
	}
	for _,v in pairs(lastdofiles) do
		dofiles(v)
	end
end
init()
unilight.debug("lua脚本加载完毕")

function TestGetAllSeat()
    local config = {gameid=5030,usernbr = 3}
    local room = RoomBase:Ctor(config)
    room:GetLoopTimer():Stop()
    assert(table.len(room:GetAllSeat()) == 3)
end

TestGetAllSeat()
