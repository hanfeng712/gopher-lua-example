package main
import (
	"fmt"
	"os"
	"./golua"
	"github.com/yuin/gopher-lua"
)
func initLuaScript() []string{
	luaPath := []string{
		"/script/test/test1.lua",
		"/script/test/test.lua",
		"/script/test/testinit.lua",
	}
	return luaPath
}

func main(){
	fmt.Println("start!")
	pwd, err := os.Getwd()
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
	luaPathMap := initLuaScript()
	/*******************************************************/

	L := lua.NewState()
	defer L.Close()
	if err := L.DoString(`print("hello")`); err != nil {
		    panic(err)
	}
	//提供全局函数给lua
	L.SetGlobal("add", L.NewFunction(golua.Add))
	L.SetGlobal("double", L.NewFunction(golua.Double))
	//加载go提供对象给lua
	L.PreloadModule("test", golua.NewTestModule().Loader)
	//加载go提供元表给lua
	golua.RegisterPersonType(L)

	//加载lua脚本
	for _, luaPath := range luaPathMap {
		luafile := fmt.Sprintf("%s%s", pwd,luaPath)
		if err := L.DoFile(luafile); err != nil {
			panic(err)
		}
	}

	//go调用lua的方法
	fmt.Print("\n\n==============================\n")
	fmt.Print("====1:go调用lua的全局方法====\n")
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

//go提供协程给lua使用
func test(L *lua.LState){
	co, _ := L.NewThread() /* create a new thread */
	fn := L.GetGlobal("thread").(*lua.LFunction) /* get function from lua */
	for {
		st, err, values := L.Resume(co, fn)
		if st == lua.ResumeError {
			fmt.Println("yield break(error)")
			fmt.Println(err.Error())
			break
		}
		fmt.Print(values)
		if st == lua.ResumeOK {
			fmt.Println("\nyield break(ok)")
			break
		}
	}
}
