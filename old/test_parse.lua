local selenScript = require "selenScript"


local print_ast = true
local print_lua = false

local prepend_provided_deps = false
local write_to_file = nil--"out.lua"


print("Parsing")
local result = selenScript.parser.parse(
[=[
global t = 33
]=])
print("Took " .. tostring(result.parseTime) .. "s")

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
