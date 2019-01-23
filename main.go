package main
import (
	"fmt"
	"os"
	"./luatool"
	"github.com/yuin/gopher-lua"
)
func initLuaScript() []string{
	luaPath := []string{
		"/lua_script/gxlua/unitimer.lua",
		"/lua_script/gxlua/RandomReturnAward.lua",
		"/lua_script/gxlua/init.lua",
	}
	return luaPath
}

func initGoLuaModule(L *lua.LState) int{
	//加载go提供对象给lua
	L.PreloadModule("gotime", luatool.NewTimeModule().Loader)
	//加载go提供元表给lua
	luatool.RegisterPersonType(L)
	return 0
}

func main(){
	fmt.Println("start!")
	pwd, err := os.Getwd()
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
	luaPathMap := initLuaScript()

	L := lua.NewState()
	defer L.Close()

	//加载go提供对象给lua
	initGoLuaModule(L)
	//加载lua脚本
	for _, luaPath := range luaPathMap {
		luafile := fmt.Sprintf("%s%s", pwd,luaPath)
		if err := L.DoFile(luafile); err != nil {
			panic(err)
		}
	}
	return
}
