local gotime = require("gotime")--引用go封装的对象
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
