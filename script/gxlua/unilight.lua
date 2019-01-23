unilight = unilight or {}

-- log --
unilight.debug = function(...)
	print("unilight-debug")
	--go.logging.Debug(...)
end

unilight.info = function(...)
	print("unilight-info")
	--go.logging.Info(...)
end

unilight.warn = function(...)
	print("unilight-warn")
	--go logging.Warning(...)
end

unilight.error = function(...)
	local arg = {...}
	if next(arg) == nil then
		unilight.error(debug.traceback())
	end
	--go.logging.Error(...)
	print("unilight-error")
end

unilight.stack = function(...)
	print("unilight-stack")
end
