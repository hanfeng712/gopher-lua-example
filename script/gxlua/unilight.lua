unilight = unilight or {}
os.time = go.time.luatime()
os.msectime = go.time.Msec
os.nsectime = go.time.Nsec

-- log --
unilight.debug = function(...)
	local arg = {...}
	go.logging.debug(arg[1], arg[2] or {})
end

unilight.info = function(...)
	local arg = {...}
	go.logging.info(arg[1], arg[2] or {})
end

unilight.warn = function(...)
	print("unilight-warn:" .. tostring(...))
	local arg = {...}
	go.logging.warning(arg[1], arg[2] or {})
end

unilight.error = function(...)
	local arg = {...}
	if next(arg) == nil then
		unilight.error(debug.traceback())
	end
	go.logging.error(arg[1], arg[2] or {})
end

unilight.stack = function(...)
	local arg = {...}
	print("unilight-stack:" .. tostring(...))
end

unilight.tablefiles = function()
	return luar.slice2table(go.getLuaFiles(go.tablePath))
end

unilight.scriptfiles = function()
	return luar.slice2table(go.getLuaFiles(go.scriptPath))
end
