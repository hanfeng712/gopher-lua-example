local gotime = require("gotime")--引用go封装的对象
CreateClass("UniTimerClass")
function NewUniTimerClass(callback, msec, ...)
	local timer = {
		--nextmsec=unitimer.now,
		nextmsec = 0,
		callback = callback,
		tick = msec,
		params = arg,
	}
	UniTimerClass:New(timer)
	return timer
end

function UniTimerClass:GetId()
	return self.tick
end

function UniTimerClass:GetName()
	return self.tick
end

function UniTimerClass:Stop()
	self.stop = true
	--unitimer.removetimer(self)
end

function UniTimerClass:Check(now,force)
	if self.nextmsec <= now or force then
		self.nextmsec = now + self.tick
		self.callback(unpack(self.params))
		return true
	end
	return false
end

unitimer = unitimer or {}
function unitimer.init(msec) --最小精度的定时器
	unitimer.now = gotime.Msec()
	if unitimer.ticktimer ~= nil then
		print("unitimer.init已经初始化过了:"..unitimer.tickmsec)
		return false
	end
	unitimer.tickmsec = msec --保存最小精度
	unitimer.ticktimer = nil
	return true
end
