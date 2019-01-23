/*
学习:go提供全局方法给lua使用
*/
package golua

import (
	"fmt"
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

func TableToMap(L *lua.LState) int{
	lv := L.ToTable(1)
	fmt.Println(lv)
	return 1
}
