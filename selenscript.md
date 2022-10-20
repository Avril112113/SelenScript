# SelenScript Syntax
Please note that the syntax may change as this is work in progress!  
The syntax of SelenScript is directly a extension of Lua 5.4  
However, SelenScript plans to be compatible with versions back to Lua5.2 and LuaJIT  

### **Typing info** 
```Lua
local a: number
e: function(arg: string) -> string  -- Function type definitions
e: function<{arg=string}, <string>>  -- This is equivalent to the above
-- This function will be typed by the typing info just above
function e(arg)
	return "Yep!"
end
function f(foo: number) -> number
	return -foo
end
-- Use a backtick string for more dynamic typing, any valid SelenScript expression is valid within the backticks
GetLevel: function(tbl: table) -> `tbl.GetLevel()`
g: table<string, number>
h: array<string>
local i1: string, i2: string, i3: number = "i1", "i2", 3
```

### **`continue`**
works like any other language, it will skip to the next iteration  
NOTE: versions prior to (LuaJIT/Lua5.2+) may not support this as it uses goto  
```Lua
for i, v in pairs(t) do
	if type(v) ~= "string" then
		continue
	end
	print("not string", v)
end
```

### **Inline `if`**  
```Lua
foo = 100
bar = if foo >= 100 then foo else foo+100  -- Bar: 100
bar = if foo < 500 then foo-100 else foo  -- Bar: 0
```

### **Statement conditionals**  
```Lua
if baz == "baz" break
if bar == "bar" continue
if foo == "foo" goto label
if der == "der" return 1, 2, "stringy"
```

### **Expression statements**  
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

Using a `return` in a statement that **is not** being used as an expression, will act like normal Lua.
That is, with the following example, it will return from the function instead of the `do` block.
```Lua
function gz(b)
	if b then goto later end
	do
		return "early happened"
	end
	::later::
	return "later happened"
end
print(gz(false) == "early happened")
```
The same applies for `for`, `while`, `repeat` and any other expressionable statements.

### **Interfaces**  
```Lua
interface FooBar
	-- basically just a bunch of type definition's
	-- this helps to define the structure of a table
	-- or things a table should implement/define
	foo: string
	bar: number
	<number>: table
end
function f() -> FooBar
	return {foo="Hi", bar=33}
end

interface Jsonable
	jsonify: function->any
end
Person: Jsonable and FooBar = {
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

### **Decorators** (based on Python)  
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

-- the reason we define the function first then redefine with the decorator is because
-- we want to preserve the special nature of `:`; `function t:foo() end`.

print(foo()) -- Result: 3
```

### **Format string** (based on python)  
```Lua
local test = 123
print(f"{test} {{}}") -- Result: "123 {}"
```


## Reserved Words
All Lua's reserved words and any that SelenScript provides like `interface` ect  
also variables starting with `__ss_` is reserved, using these may cause unexpected results  


## Types
`any` can be anything  
`table` normal Lua table  
`table<KeyType, ValueType>`  
`array` a list of values  
`array<ValueType>`  
`string`  
`number` int or float  
`int` whole number  
`float` non-whole number (contains decimal)  
`function`  
`fun`  Shorthand for `function` (because EmmyLua)  
`function(arg: ArgType)`  
`function(arg: ArgType) -> ReturnType`  
`unknown` when no type is defined (not useable in syntax, use `any` if the type is explicitly unknown)  
