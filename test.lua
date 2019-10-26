local ss = require "selenScript"


local settings = {
	defaultLocals=true
}


local program = ss.program.new(settings)

local file = ss.file.new("./test_code.sl")
program:addFile(file)

print("--- Parse Errors ---")
for _, err in ipairs(file.parseResult.errors) do
	print(tostring(err.start) .. ":" .. tostring(err.finish) .. " " ..  err.msg)
end

file:symbolize()

print("--- Symbolize Diagnostics ---")
for _, err in ipairs(file.symbolizeDiagnostics) do
	local str = err.msg
	if err.start ~= nil then
		str = tostring(err.start) .. " " .. str
		if err.finish ~= nil then
			str = ":" .. tostring(err.finish) .. " " .. str
		end
	end
	print(str)
end


print("--- AST (After Symbolize) ---")
ss.helpers.printAST(file.ast)
print("--- Global Symbols ---")
ss.helpers.printSymbols(program.globals)
