local gologging = require("gologging")

unilight = unilight or {}

-- log --
unilight.debug = function(...)
	local arg = {...}	
	gologging.debug(arg[1], arg[2] or {})
end

unilight.info = function(...)
	local arg = {...}	
	gologging.info(arg[1], arg[2] or {})
end

unilight.warn = function(...)
	print("unilight-warn:" .. tostring(...))
	local arg = {...}	
	gologging.warning(arg[1], arg[2] or {})
end

unilight.error = function(...)
	local arg = {...}
	if next(arg) == nil then
		unilight.error(debug.traceback())
	end
	gologging.error(arg[1], arg[2] or {})
end

unilight.stack = function(...)
	local arg = {...}	
	print("unilight-stack:" .. tostring(...))
end
