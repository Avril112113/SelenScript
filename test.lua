local ss = require "selenScript"


local settings = {
	defaultLocals=true,
	indent="\t"
}


local program = ss.program.new(settings)

local file = ss.file.new("./test_code.sl")
program:addFile(file)

print("--- Parse Errors ---")
for _, err in ipairs(file.parseResult.errors) do
	print(tostring(err.start) .. ":" .. tostring(err.finish) .. " " ..  err.msg)
end

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

local ok, transformer, transpiler = file:transpile()
if not ok then
	print("Failed to open file '" .. file:getWriteFilePath() .. "' to write")
end
print("--- Transformer Diagnostics ---")
for _, err in ipairs(transformer.diagnostics) do
	print(tostring(err.start) .. ":" .. tostring(err.finish) .. " " .. (err.severity or "unknown") .. ": " ..  err.msg)
end
print("--- Transpiler Diagnostics ---")
for _, err in ipairs(transpiler.diagnostics) do
	print(tostring(err.start) .. ":" .. tostring(err.finish) .. " " .. (err.severity or "unknown") .. ": " ..  err.msg)
end
