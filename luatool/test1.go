package luatool

import (
	"github.com/yuin/gopher-lua"
)

func Add(L *lua.LState) int {
	lv1 := 1
	lv2 := 2
	ret := lv1 + lv2
	L.Push(lua.LNumber(ret))
	return 1
}

func Double(L *lua.LState) int {
	lv := L.ToInt(1)             /* get argument */
	L.Push(lua.LNumber(lv * 2)) /* push result */
	return 1                     /* number of results */
}
