/*
学习:go提供对象和对象发个方法给lua使用
*/
package golua

import (
	"time"	
	"github.com/yuin/gopher-lua"
)
type timeModule struct {
	exports map[string]lua.LGFunction
}
//创建模块
func NewTimeModule() *timeModule {
	ret := &timeModule{
		exports : make(map[string]lua.LGFunction),
	}
	ret.init()
	return ret
}

//模块函数注册
func (h *timeModule) init() int{
	h.exports["Test"] = h.test
	h.exports["luatime"] = h.msec
	h.exports["Msec"] = h.msec
	h.exports["Nsec"] = h.msec
	return 1
}

//模块注册
func (h *timeModule) Loader(L *lua.LState) int {
	mod := L.SetFuncs(L.NewTable(), h.exports)
	L.Push(mod)
	return 1
}

//测试函数
func (h *timeModule) test(L *lua.LState) int {
	ret := lua.LString("hello word")
	L.Push(ret)
	return 1
}
//获取当前秒
func (h *timeModule) second(L *lua.LState) int {
	second := time.Now().Unix()
	ret := lua.LNumber(second)
	L.Push(ret)
	return 1
}
//获取当前毫秒
func (h *timeModule) msec(L *lua.LState) int {
	msec := time.Now().UnixNano() / 1e6
	ret := lua.LNumber(msec)
	L.Push(ret)
	return 1
}
//获取当前纳秒秒
func (h *timeModule) nsec(L *lua.LState) int {
	msec := time.Now().UnixNano() / 1e9
	ret := lua.LNumber(msec)
	L.Push(ret)
	return 1
}
