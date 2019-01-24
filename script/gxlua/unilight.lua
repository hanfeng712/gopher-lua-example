unilight = unilight or {}

-- log --
unilight.debug = function(...)
	print("unilight-debug:" .. tostring(...))
	--go.logging.Debug(...)
end

unilight.info = function(...)
	print("unilight-info:" .. tostring(...))
	--go.logging.Info(...)
end

unilight.warn = function(...)
	print("unilight-warn:" .. tostring(...))
	--go logging.Warning(...)
end

unilight.error = function(...)
	local arg = {...}
	if next(arg) == nil then
		unilight.error(debug.traceback())
	end
	--go.logging.Error(...)
	print("unilight-error:" .. tostring(...))
end

unilight.stack = function(...)
	print("unilight-stack:" .. tostring(...))
end
