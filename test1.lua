--[[
学习:lua提供go提供的方法测试模块
--]]--
function double(a)
	return a * a
end
local i = 1
function thread()
	i = i + 1
	return i
end
