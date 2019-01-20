package luatool

import (
	"github.com/yuin/gopher-lua"
)

type Person struct{
	Name string
}

const luaPersonTypeName = "person"

// Registers my person type to given L.
func RegisterPersonType(L *lua.LState) {
	//go实现lua的元表
	mt := L.NewTypeMetatable(luaPersonTypeName)
	//设置元表在lua中的名字
	L.SetGlobal("person", mt)
	// static attributes
	//全局方法:生成元表的一个子表
	L.SetField(mt, "new", L.NewFunction(newPerson))
	//go实现lua元表的_index
	L.SetField(mt, "__index", L.SetFuncs(L.NewTable(), personMethods))
}

/*
生成一个表方法,附带元表
*/
func newPerson(L *lua.LState) int {
	person := &Person{L.CheckString(1)}
	ud := L.NewUserData()
	ud.Value = person
	L.SetMetatable(ud, L.GetTypeMetatable(luaPersonTypeName))
	L.Push(ud)
	return 1
}
var personMethods = map[string]lua.LGFunction{
	"name": personGetSetName,
}

func checkPerson(L *lua.LState) *Person {
	ud := L.CheckUserData(1)
	if v, ok := ud.Value.(*Person); ok {
		return v
	}
	L.ArgError(1, "person expected")
	return nil
}
// Getter and setter for the Person#Name
func personGetSetName(L *lua.LState) int {
	p := checkPerson(L)
	if L.GetTop() == 2 {
		p.Name = L.CheckString(2)
		return 0
	}
	L.Push(lua.LString(p.Name))
	return 1
}

