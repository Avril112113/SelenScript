local selenScript = require "selenScript"


print("Parsing")
local start = os.clock()
local result = selenScript.parser.parse(
--[[
class BarClass extends FooClass implements SomeInterface
	foo: string
	bar = "hi"

	@decorator
	function f()
	end

	function f2()
	end
end
]]
[=[
a_ = 1+2*3    -- 1+(2*3)
ar = (1+2)*3  -- (1+2)*3

b_ = -2^2    -- -(2^2)
br = (-2)^2  -- (-2)^2

c_ = "a" .. "b" .. "c"    -- "a" .. ("b" .. "c")
cr = ("a" .. "b") .. "c"  -- ("a" .. "b") .. "c"

d_ = -2*2    -- (-2)*2
dr = -(2*2)  -- -(2*2)
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

selenScript.helpers.printAST(result.ast)
-- print(selenScript.helpers.reconstructMath(result.ast[1][2][1]))

print("Resulting Lua...")
local luaResult = selenScript.transpiler.transpile(result.ast)
local _, err = loadstring(luaResult, "@luaResult")
if err ~= nil then
	print("Resulting Lua Error:", err)
end
print(luaResult)
