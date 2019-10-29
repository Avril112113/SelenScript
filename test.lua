local ss = require "selenScript"


local settings = {
	defaultLocals=true,
	indent="\t",
	targetVersion="5.1"
}


local program = ss.program.new(settings)

local file = ss.file.new("./test_code.sl")
program:addFile(file)

print("--- Parse Errors ---")
for _, err in ipairs(file.parseResult.errors) do
	print(tostring(err.start) .. ":" .. tostring(err.finish) .. " " ..  err.msg)
end
-- print("--- AST ---")
-- ss.helpers.printAST(file.ast)

print()

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

print()

file:diagnose()
print("--- Diagnostics ---")
for _, err in ipairs(file.diagnostics) do
	print(tostring(err.start) .. ":" .. tostring(err.finish) .. " " .. (err.severity or "unknown") .. ": " ..  err.msg)
end

print()

local ok, transformer, transpiler, transformedAst = file:transpile()
if not ok then
	print("Failed to open file '" .. file:getWriteFilePath() .. "' to write")
end
-- print("--- AST (After Transform) ---")
-- ss.helpers.printAST(transformedAst)
print("--- Transformer Diagnostics ---")
for _, err in ipairs(transformer.diagnostics) do
	print(tostring(err.start) .. ":" .. tostring(err.finish) .. " " .. (err.severity or "unknown") .. ": " ..  err.msg)
end
print("--- Transpiler Diagnostics ---")
for _, err in ipairs(transpiler.diagnostics) do
	print(tostring(err.start) .. ":" .. tostring(err.finish) .. " " .. (err.severity or "unknown") .. ": " ..  err.msg)
end
