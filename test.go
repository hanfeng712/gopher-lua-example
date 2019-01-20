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
	return
}
