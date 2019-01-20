package luatool

import (
	"github.com/yuin/gopher-lua"
)

func Add(L *lua.LState) int {
	lv1 := L.ToInt(1)
	//lv2 := L.ToInt(2)
	//ret := lv1 + lv2
	L.Push(lua.LNumber(lv1 * 2))
	return 1
}

