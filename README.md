# gopher-lua-example
gopher-lua库的使用例子
依赖库：
https://github.com/leyafo/gopher-lua.git
https://github.com/rucuriousyet/loguago.git
https://github.com/rs/zerolog.git
https://github.com/yuin/gluamapper.git
https://github.com/mitchellh/mapstructure.git
目录介绍:
script	lua脚本目录
golua	go提供库目录
golua/do	lua逻辑实现目录
golua/gxlua lua库目录，主要是对接go库的实现
主要文件
main.go	程序主函数入口
maintest.go 测试程序主函数入口
main.lua lua逻辑层，主入口
