print("*************lua-开始写代码=入口位置-lua******************")
local json = require("json")
local xmlpath = require("xmlpath")

local function init()
	getLuaFiles("table")
	getLuaFiles("script/gxlua")
	local lastdofiles = {
		"script/do/init.lua",
	}
	for _,v in pairs(lastdofiles) do
		dofiles(v)
	end
end
init()
unilight.debug("lua脚本加载完毕")
local xmlpath = require("xmlpath")

local data = [[
<channels>
    <channel id="1" xz1="600" />
    <channel id="2"           />
    <channel id="x" xz2="600" />
</channels>
]]
local data_path = "//channel/@id"

-- xmlpath.load(data string)
local node, err = xmlpath.load(data)
if err then 
	error(err) 
end

-- xmlpath.compile(path string)
local path, err = xmlpath.compile(data_path)
if err then 
	error(err) 
end

-- path:iter(node)
local iter = path:iter(node)

for k, v in pairs(iter) do 
	print(v:string()) 
end

