local breakOnParseError = false
local breakOnSymbolizeDiagnostic = false
local breakOnTransformerDiagnostic = false
local breakOnTranspilerDiagnostic = false

local settings = {
	defaultLocals=false
}


local selenScript = require "selenScript"


local files = {}
local function addTests(glob)
	local handle = io.popen('python listFiles.py "' .. glob .. '"')
	local filesStr = handle:read "*a"
	handle:close()
	local _files = load("return " .. filesStr, "@listFiles.py (RESULT)")()
	for i, v in ipairs(_files) do
		table.insert(files, v)
	end
end

addTests("tests/selenScript/**/*.sl")
addTests("tests/pure lua/**/*.lua")


print(tostring(#files) .. " files to test...")
local totalParseTime = 0
local totalSymbolizeTime = 0
local totalTranspileTime = 0
local testStartTime = os.clock()
for _, path in ipairs(files) do
	print("--- Parsing " .. tostring(path) .. " ---")
	local program = selenScript.program.new(settings)
	local file = selenScript.file.new(path)
	file.writeOnTranspile = false
	totalParseTime = totalParseTime + file.parseResult.parseTime

	if #file.parseResult.errors > 0 then
		print("- Parse Errors -")
		for _, err in ipairs(file.parseResult.errors) do
			print(tostring(err.start) .. ":" .. tostring(err.finish) .. " " ..  err.msg)
		end
		if breakOnParseError then break end
	end

	program:addFile(file)

	local symbolizeTime = file:symbolize()
	totalSymbolizeTime = totalSymbolizeTime + symbolizeTime
	if #file.symbolizeDiagnostics > 0 then
		print("- Symbolize Diagnostics -")
		for _, err in ipairs(file.symbolizeDiagnostics) do
			local str = err.msg
			if err.start ~= nil then
				local posStr = tostring(err.start)
				if err.finish ~= nil then
					posStr = posStr .. ":" .. tostring(err.finish)
				end
				str = posStr .. " " .. str
			end
			print(str)
		end
		if breakOnSymbolizeDiagnostic then break end
	end

	local transpileStart = os.clock()
	local ok, transformer, transpiler, _, luaCode = file:transpile()
	totalTranspileTime = totalTranspileTime + (os.clock() - transpileStart)
	if #transformer.diagnostics > 0 then
		print("- Transformer Diagnostics -")
		for _, err in ipairs(transformer.diagnostics) do
			local str = err.msg
			if err.start ~= nil then
				local posStr = tostring(err.start)
				if err.finish ~= nil then
					posStr = posStr .. ":" .. tostring(err.finish)
				end
				str = posStr .. " " .. str
			end
			print(str)
		end
		if breakOnTransformerDiagnostic then break end
	end
	if #transpiler.diagnostics > 0 then
		print("- Transpiler Diagnostics -")
		for _, err in ipairs(transpiler.diagnostics) do
			local str = err.msg
			if err.start ~= nil then
				local posStr = tostring(err.start)
				if err.finish ~= nil then
					posStr = posStr .. ":" .. tostring(err.finish)
				end
				str = posStr .. " " .. str
			end
			print(str)
		end
		if breakOnTranspilerDiagnostic then break end
	end
	if ok and #transpiler.diagnostics <= 0 then
		local pcallOk, err = pcall(load, luaCode)
		if pcallOk == false and err ~= nil then
			print("Syntax check of file failed")
			print(err)
		end
	end
end

local testProcessTime = os.clock() - testStartTime
print("\nTotal time taken processing test files " .. tostring(testProcessTime) .. "s")
print("Parsing test files took " .. tostring(totalParseTime) .. "s")
print("Symbolizing test files took " .. tostring(totalSymbolizeTime) .. "s")
print("Transpiling test files took " .. tostring(totalTranspileTime) .. "s")
