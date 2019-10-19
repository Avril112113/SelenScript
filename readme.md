# SelenScript
This is a transpiler that outputs Lua code  
Any normal Lua code should in theory transpile without issues (if not please report it)  
The goal of SelenScript is to make Lua neater and easier to code  
and make complex things simple  
TODO: improve readme

## Name
Selen is based from  
```
Selina /səˈliːnə/ is a feminine given name, of Greek origin, derived from the Greek "Selēnē" meaning "moon". It reached peak popularity in the 1980s.
``` 
it was recommended by DreadberryJam from a discord server i talk in.

## Syntax
Please note that the syntax may change as this is work in progress!  
The syntax of SelenScript is directly a extension of Lua 5.4  
This dose not mean you can't use it for other Lua versions (proper support maybe added later)  

Typing info 
```Lua
local a: number
local b: int|float  -- same as number
local c: string or nil  -- you can use the pipe or `or`
d: function  -- also works on globals
e: function(arg: string) -> string  -- also can do function type definitions
-- this function will be typed by the typing info just above
function e(arg)
	return "Nah..."
end
function f(foo: number) -> number
	return -foo
end
g: table[string=number]
h: array[string]
```

`continue` works like any other language  
NOTE: versions prior to (LuaJIT/Lua5.2+) may not support this as it use's goto  
```Lua
for i, v in pairs(t) do
	if type(v) ~= "string" then
		continue
	end
	print("not string", v)
end
-- Lua
for i, v in pairs(t) do
	if type(v) ~= "string" then
		goto continue
	end
	print("not string", v)
	::continue::
end
```

Inline `if`  
```Lua
foo = 100
bar = foo if foo >= 100 else foo+100  -- Bar: 100
bar = foo-100 if foo < 500 else foo  -- Bar: 0
-- Lua (Formatted)
foo = 100
local __sls0
if foo >= 100 then
	__sls0 = foo
else
	__sls0 = foo+100
end
bar = __sls0
local __sls1
if foo < 500 then
	__sls1 = foo-100
else
	__sls1 = foo
end
bar = __sls1
```

Statement conditionals  
```Lua
break if baz == "baz"
continue if baz == "baz"
```

expression statements  
NOTE: versions prior to (LuaJIT/Lua5.2+) may not support this as it use's goto  
```Lua
foo = while true do
	break "foo's value"
end
bar = do
	return "OOooo, fancy"
end
baz = for i,v in pairs(t) do
	-- will not break until v == "baz"
	-- if all elements have been checked and none was true then baz == nil
	break v if v == "baz"
	-- basically if nothing 'returned' a value then Lua's default is used `nil`
end
```

Interface's  
```Lua
interface FooBar
	-- basically just a bunch of type definition's
	-- this helps to define the structure of a table
	-- or things a table should implement/define
	foo: string
	bar: number
end
function f() -> FooBar
	return {foo="Hi", bar=33}
end

interface Jsonable
	jsonify: function->any
end
@implements(Jsonable, FooBar)  -- TODO: there is planned to have some fancy syntax stuff later but for now its decorator
Person = {
	foo="Im foo",
	bar="and im foo's big brother",
	function jsonify()
		return {
			foo=self.foo,
			bar=self.bar
		}
	end
}
```

Decorators (similar to Python)  
```Lua
-- `f` is always supplied
-- `f` will be only argument if the decorator is not called
-- if the decorator is call then those args are passed after `f`
function default(f, ...)
	local defs = {...}
	-- return a new function that calls the supplied function `f` with the default parameters `defs`
	-- and any other parameters that might be supplied when the new function is called
	return function(...) return f(unpack(defs), ...) end
end

@default(3)
function foo(a)
	return a
end
-- Lua (Formatted)
function foo(a)
	return a
end
foo = default(foo, 3)

-- the reason we define the function first then redefine with the decorator it instead of just using
-- it directly as an argument to the decorator is because for example
-- `function t:foo() end`, we want to preserve the special nature of `:`

print(foo()) -- Result: 3
```

String formatting (like in python)  
```Lua
local test = 123
print(f"{test} {{}}") -- Result: "123 {}"
```


## Settings/Options
`default_local`, in Lua variables are by default global, this make all variables default to local instead  
and to define a global you can just use `global` like you'd use `local`  
note that we cant know the globals at runtime so they must be defined global somewhere  
there is a setting `globals` for any variables that are global in any file  

## Reserved Words
All Lua's reserved words and any that SelenScript provides like `interface` ect  
also variables starting with `__sls` is reserved, using these may cause unexpected results  

## Notes
Using an expression statements in a format string may cause unexpected results  
you can still use a return in a `do` statement without using it as a expression, but it will work as it would in Lua for example  
```Lua
function gz(b)
	if b then goto later end
	do
		return "early happened"
	end
	::later::
	return "later happened"
end
```
would return from the function and not the `do` statement as its not used as an expression statement  

## Types
`any` can be anything  
`table` normal Lua table  
`table[KeyType=ValueType]`  
`array` a list of values  
`array[ValueType]`  
`string`  
`number` int or float  
`int` whole number  
`float` floating point number  
`function`  
`function(arg: ArgType)`  
`function(arg: ArgType) -> ReturnType`  
`unknown` when no type is defined (can be ignored, not useable, use `any` if the type is explisitly unknown)  


# Contributors
Matrixmage - Helped with some code stuff  
Matrixmage, Pyry, Yolathothep - Language design  
DreadberryJam - Name Suggestion

Where ever I borrowed code for tests  
and anyone who finds bugs and reports them  
