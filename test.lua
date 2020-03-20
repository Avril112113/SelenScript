local ss = require "selenScript"


local settings = {
	defaultLocals=true,
	indent="\t",
	targetVersion="5.2"
}


local program = ss.program.new(settings)

local source_file = program:addSourceFileByPath("test_code.sl")

print("--- Parse Errors ---")
for _, err in ipairs(source_file.parseErrors) do
	print(tostring(err.start) .. ":" .. tostring(err.finish) .. " " ..  err.msg)
end
print("--- AST ---")
ss.helpers.printAST(source_file.block)

print()

print("--- Binder Diagnostics ---")
for _, err in ipairs(source_file.binderDiagnostics) do
	local str = err.msg
	if err.start ~= nil and err.finish ~= nil then
		str = tostring(err.start) .. ":" .. tostring(err.finish) .. " " .. str
	elseif err.start ~= nil then
		str = tostring(err.start) .. " " .. str
	end
	print(str)
end

print()

-- program:checkSourceFile(source_file)
-- print("--- Diagnostics ---")
-- for _, err in ipairs(source_file.chekerDiagnostics) do
-- 	print(tostring(err.start) .. ":" .. tostring(err.finish) .. " " .. (err.severity or "unknown") .. ": " ..  err.msg)
-- end

print()

local luaSrc = program:transpileSourceFile(source_file)
print("--- Transformer Diagnostics ---")
for _, err in ipairs(source_file.transformerDiagnostics) do
	print(tostring(err.start) .. ":" .. tostring(err.finish) .. " " .. (err.severity or "unknown") .. ": " ..  err.msg)
end
print("--- Transpiler Diagnostics ---")
for _, err in ipairs(source_file.transpilerDiagnostics) do
	print(tostring(err.start) .. ":" .. tostring(err.finish) .. " " .. (err.severity or "unknown") .. ": " ..  err.msg)
end
