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
	L.PreloadModule("test", luatool.NewTestModule().Loader)
	if err := L.DoFile("test.lua"); err != nil {
		panic(err)
	}
	return
}
