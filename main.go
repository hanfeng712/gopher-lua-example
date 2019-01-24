package main
import (
	"fmt"
	"os"
	"./golua"
	"github.com/yuin/gopher-lua"
	"github.com/rs/zerolog"
	"github.com/rucuriousyet/loguago"
)
func initLuaScript() []string{
	luaPath := []string{
		"script/main.lua",
	}
	return luaPath
}

func dofile(L *lua.LState) int{
	pwd, err := os.Getwd()
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
	luaPath := L.ToString(1)
	luafile := fmt.Sprintf("%s%s%s", pwd,"/",luaPath)
	if err := L.DoFile(luafile); err != nil {
			panic(err)
	}
	return 1
}

func initGoLuaModule(L *lua.LState) int{
	/********add global function*********/
	//提供全局函数给lua
	L.SetGlobal("dofiles", L.NewFunction(dofile))
	//加载go提供对象给lua
	L.PreloadModule("gotime", golua.NewTimeModule().Loader)
	//加载go提供元表给lua
	golua.RegisterPersonType(L)
	/*log*/
	zlogger := zerolog.New(os.Stdout)
	logger := loguago.NewLogger(zlogger.With().Str("unit", "my-lua-module").Logger())
	L.PreloadModule("gologging", logger.Loader)
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
		luafile := fmt.Sprintf("%s%s%s", pwd,"/",luaPath)
		if err := L.DoFile(luafile); err != nil {
			panic(err)
		}
	}
	return
}
