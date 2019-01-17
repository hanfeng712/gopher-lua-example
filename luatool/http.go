package luatool

import (
	"github.com/yuin/gopher-lua"
)
type testModule struct {
	exports map[string]lua.LGFunction
}
//创建模块
func NewTestModule() *testModule {
	ret := &testModule{
		exports : make(map[string]lua.LGFunction),
	}
	ret.init()
	return ret
}
//模块函数注册
func (h *testModule) init() int{
	h.exports["getName"] = h.getName
	h.exports["test"] = h.test
	return 1
}
//模块注册
func (h *testModule) Loader(L *lua.LState) int {
	mod := L.SetFuncs(L.NewTable(), h.exports)
	L.Push(mod)
	return 1
}

//测试函数
func (h *testModule) getName(L *lua.LState) int {
	ret := lua.LString("hello word")
	L.Push(ret)
	return 1
}
func (h *testModule) test(L *lua.LState) int {
	return 1
}
