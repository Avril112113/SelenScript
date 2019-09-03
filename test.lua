local selenScript = require "selenScript"


local print_ast = false
local print_lua = false

local prepend_provided_deps = true
local write_to_file = "t.lua"


print("Parsing")
local start = os.clock()
local result = selenScript.parser.parse(
[=[
class FooClass
	foo = "im foo..."
	both = "im defined in FooClass"
end
class BarClass
	bar = "im bar..."
	both = "im defined in BarClass"
end

class TestClass extends FooClass, BarClass
	function test(self)
		print(tostring(self) .. ":test()")
	end
end

print("inherit count", #TestClass.__sls_inherits)

TestClass:test()
local obj = TestClass()
obj:test()

print(tostring(TestClass.foo))
print(tostring(obj.foo))
print(tostring(obj.both))
]=])
local finish = os.clock()
print("Took " .. tostring(finish-start) .. "s")

if #result.errors > 0 then
	print("Errors (caught)")
	for _, err in ipairs(result.errors) do
		local str = tostring(err.start) .. ":" .. tostring(err.finish) .. " " ..  err.msg
		if err.fix ~= nil then
			str = str .. "(fix: '" .. tostring(err.fix):gsub("\n", "\\n"):gsub("\r", "\\r"):gsub("\t", "\\t") ..  "')"
		end
		print(str)
		if err.ast ~= nil then
			selenScript.helpers.printAST(err.ast)
		end
	end
end

if print_ast then
	selenScript.helpers.printAST(result.ast)
end

print("Resulting Lua...")
local luaResult, transpiler = selenScript.transpiler.transpile(result.ast)
if prepend_provided_deps then
	for _, dep in pairs(transpiler.provided_deps) do
		luaResult = dep.lua .. luaResult
	end
end
local _, err = loadstring(luaResult, "@luaResult")
if err ~= nil then
	print("Resulting Lua Error:", err)
end
if print_lua then
	print(luaResult)
end

if write_to_file ~= nil then
	local f = io.open(write_to_file, "w")
	f:write(luaResult)
	f:close()
end
