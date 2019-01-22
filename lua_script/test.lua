--[[
学习:lua调用go提供的方法测试模块
--]]--
local ret = nil
--go提供全局函数给lua使用
print("=====1:go提供全局函数给lua使用=====")
print("  ====1.1:函数没有参数")
ret = add()
print("  ret : " .. tostring(ret))
print("  ====1.2:函数有参数")
ret = double(2)
print("  ret : " .. tostring(ret))

--引用go对象和调用对象方法
print("=====2:引用go对象和调用对象方法=====")
local m = require("test")--引用go封装的对象
ret = m.getName()--调用go对象方法
print("ret : " .. tostring(ret))

--go实现lua的元表功能
print("=====3:go实现lua的元表功能=====")
local p = person.new("hanfeng")
ret = p:name()
print("ret : " .. tostring(ret))

print("==================lua-lua=enter=========================")
RandomAward.Test()
print("==================lua-lua=end=========================")
