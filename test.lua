local ss = require "selenScript"


local settings = {
	defaultLocals=true,
	indent="\t",
	targetVersion="5.2"
}


local program = ss.program.new(settings)

local source_file = program:addSourceFileByPath("test_code.sel")

print("--- Parse Errors ---")
for _, err in ipairs(source_file.parseErrors) do
	print(tostring(err.start) .. ":" .. tostring(err.finish) .. " " ..  err.msg)
end
print("--- AST ---")
ss.helpers.printAST(source_file.block)

print()

print("--- Binder Diagnostics ---")
for _, err in ipairs(source_file.binder.diagnostics) do
	local str = err.msg
	if err.start ~= nil and err.finish ~= nil then
		str = tostring(err.start) .. ":" .. tostring(err.finish) .. " " .. str
	elseif err.start ~= nil then
		str = tostring(err.start) .. " " .. str
	end
	print(str)
end
local luaSrc = program:transpileAndWriteSourceFile(source_file)
print("--- Transformer Diagnostics ---")
for _, err in ipairs(source_file.transformer.diagnostics) do
	print(tostring(err.start) .. ":" .. tostring(err.finish) .. " " .. (err.severity or "unknown") .. ": " ..  err.msg)
end
print("--- Transpiler Diagnostics ---")
for _, err in ipairs(source_file.transpiler.diagnostics) do
	print(tostring(err.start) .. ":" .. tostring(err.finish) .. " " .. (err.severity or "unknown") .. ": " ..  err.msg)
end
