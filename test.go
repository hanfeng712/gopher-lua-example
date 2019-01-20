package main
import (
	"fmt"
	"./luatool"
	"github.com/yuin/gopher-lua"
)
func main(){
	fmt.Println("start!")
	L := lua.NewState()
	defer L.Close()
	if err := L.DoString(`print("hello")`); err != nil {
		    panic(err)
	}
	//提供全局函数给lua
	L.SetGlobal("add", L.NewFunction(Add))
	L.SetGlobal("double", L.NewFunction(Double))
	//加载go提供对象给lua
	L.PreloadModule("test", luatool.NewTestModule().Loader)
	//加载go提供元表给lua
	luatool.RegisterPersonType(L)
	if err := L.DoFile("test.lua"); err != nil {
		panic(err)
	}
	return
}

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

