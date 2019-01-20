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
	L.SetGlobal("add", L.NewFunction(luatool.Add))
	L.SetGlobal("double", L.NewFunction(luatool.Double))
	//加载go提供对象给lua
	L.PreloadModule("test", luatool.NewTestModule().Loader)
	//加载go提供元表给lua
	luatool.RegisterPersonType(L)
	if err := L.DoFile("test.lua"); err != nil {
		panic(err)
	}
	//go调用lua的方法
	fmt.Print("\n\n==============================\n")
	fmt.Print("====1:go调用lua的全局方法====\n")
	if err := L.DoFile("test1.lua"); err != nil {
		panic(err)
	}
	if err := L.CallByParam(lua.P{
		Fn: L.GetGlobal("double"),
		NRet: 1,
		Protect: true,
	}, lua.LNumber(10)); err != nil {
		panic(err)
	}
	ret1 := L.Get(-1)
	L.Pop(1)
	fmt.Printf("ret1 : %d\n", ret1)
	return
}
