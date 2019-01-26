package main
import (
	"fmt"
	"os"
	"./golua"
	"github.com/yuin/gopher-lua"
	"github.com/rs/zerolog"
	"github.com/rucuriousyet/loguago"
	"github.com/gopher-lua-json"
)
func initLuaScript() []string{
	luaPath := []string{
		"script/gopack.lua",
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

func listFile(myfolder string) []string{
	var ret []string	
	files, _ := ioutil.ReadDir(myfolder)
	for _, file := range files {
		if file.IsDir() {
			listFile(myfolder + "/" + file.Name())
		} else {
			var filenameWithSuffix string = path.Base(file.Name()) //获取文件名带后缀
			var fileSuffix string = path.Ext(filenameWithSuffix) //获取文件后缀
			if fileSuffix == ".lua"{
				fmt.Println(myfolder + "/" + file.Name())
				filePath := fmt.Sprintf("%s%s%s", myfolder,"/",file.Name())	
				append(filePath)
			}
		}
	}
}

func getLuaFiles(L *lua.LState) int{
	luaPath := L.ToString(1)

	return 1
}

func initGoLuaModule(L *lua.LState) int{
	/********add global function*********/
	/*提供全局函数给lua*/
	L.SetGlobal("dofiles", L.NewFunction(dofile))
	/*加载go提供对象给lua*/
	L.PreloadModule("gotime", golua.NewTimeModule().Loader)
	/*加载go提供元表给lua*/
	golua.RegisterPersonType(L)
	/*log*/
	zlogger := zerolog.New(os.Stdout)
	//logger := loguago.NewLogger(zlogger.With().Str("unit", "my-lua-module").Logger())
	logger := loguago.NewLogger(zlogger.With().Str("auth:","hf").Logger())
	L.PreloadModule("gologging", logger.Loader)
	/*json*/
	L.PreloadModule("json",json.Loader)
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
