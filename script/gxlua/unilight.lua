local gologging = require("gologging")

unilight = unilight or {}

-- log --
unilight.debug = function(...)
	print("unilight-debug:" .. tostring(...))
	--gologging.debug(...)
end

unilight.info = function(...)
	print("unilight-info:" .. tostring(...))
	--gologging.info(...)
end

unilight.warn = function(...)
	print("unilight-warn:" .. tostring(...))
	--gologging.warning(...)
end

unilight.error = function(...)
	local arg = {...}
	if next(arg) == nil then
		unilight.error(debug.traceback())
	end
	--gologging.error(...)
	print("unilight-error:" .. tostring(...))
end

unilight.stack = function(...)
	print("unilight-stack:" .. tostring(...))
end
