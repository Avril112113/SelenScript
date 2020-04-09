local breakOnParseError = true
local breakOnBindDiagnostic = false
local breakOnTransformerDiagnostic = true
local breakOnTranspilerDiagnostic = true

local settings = {
	defaultLocals=false
}


local ss = require "selenScript"


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

addTests("basic_tests/selenScript/**/*.sel")
addTests("basic_tests/pure lua/**/*.lua")


print(tostring(#files) .. " files to test...")
local totalParseTime = 0
local totalBindTime = 0
local totalTranspileTime = 0
local testStartTime = os.clock()
for _, path in ipairs(files) do
	print("--- Parsing " .. tostring(path) .. " ---")
	local program = ss.program.new(settings)
	local source_file = program:addSourceFileByPath(path)
	totalParseTime = totalParseTime + source_file.parseTime

	if #source_file.parseErrors > 0 then
		print("- Parse Errors -")
		for _, err in ipairs(source_file.parseErrors) do
			print(tostring(err.start) .. ":" .. tostring(err.finish) .. " " ..  err.msg)
		end
		if breakOnParseError then break end
	end

	totalBindTime = totalBindTime + source_file.bindTime
	if #source_file.binder.diagnostics > 0 then
		print("- Bind Diagnostics -")
		for _, err in ipairs(source_file.binder.diagnostics) do
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
		if breakOnBindDiagnostic then break end
	end

	local transpileStart = os.clock()
	local luaSrc = program:transpileSourceFile(source_file)
	totalTranspileTime = totalTranspileTime + (os.clock() - transpileStart)
	if #source_file.transformer.diagnostics > 0 then
		print("- Transformer Diagnostics -")
		for _, err in ipairs(source_file.transformer.diagnostics) do
			local str = err.msg
			if err.start ~= nil and err.finish ~= nil then
				str = tostring(err.start) .. ":" .. tostring(err.finish) .. " " .. str
			elseif err.start ~= nil then
				str = tostring(err.start) .. " " .. str
			end
			print(str)
		end
		if breakOnTransformerDiagnostic then break end
	end
	if #source_file.transpiler.diagnostics > 0 then
		print("- Transpiler Diagnostics -")
		for _, err in ipairs(source_file.transpiler.diagnostics) do
			local str = err.msg
			if err.start ~= nil and err.finish ~= nil then
				str = tostring(err.start) .. ":" .. tostring(err.finish) .. " " .. str
			elseif err.start ~= nil then
				str = tostring(err.start) .. " " .. str
			end
			print(str)
		end
		if breakOnTranspilerDiagnostic then break end
	end
	if #source_file.transformer.diagnostics <= 0 and #source_file.transpiler.diagnostics <= 0 then
		local pcallOk, err = pcall(load, luaSrc)
		if pcallOk == false and err ~= nil then
			print("Syntax check of file failed")
			print(err)
		end
	end
end

local testProcessTime = os.clock() - testStartTime
print("\nTotal time test time " .. tostring(testProcessTime) .. "s (console output takes time)")
print("Parsing test files took " .. tostring(totalParseTime) .. "s")
print("Binding test files took " .. tostring(totalBindTime) .. "s")
print("Transpiling test files took " .. tostring(totalTranspileTime) .. "s")
