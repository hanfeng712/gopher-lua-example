package luatool

import "github.com/yuin/gopher-lua"
func Loader(L *lua.LState) int{
	mod := L.SetFuncs(L.NewTable(), exports)
	// register other stuff
	L.SetField(mod, "name", lua.LString("value"))
	L.Push(mod)
	return 1
}

var exports = map[string]lua.LGFunction{
	"myfunc": myfunc,
}

func myfunc(L *lua.LState) int {
	//ret := lua.LString("hello word")
	L.Push(lua.LString("3"))
	return 1
}
