local breakOnParseError = false
local breakOnSymbolizeDiagnostic = false


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


local function validate(value)
	if type(value) == "table" then
		if value.type ~= nil then
			if value.start == nil then
				print("value.start missing for ast type " .. tostring(value.type))
				selenScript.helpers.printAST(value)
			elseif type(value.start) ~= "number" then
				print("value.start is not a number for ast type " .. tostring(value.type))
				selenScript.helpers.printAST(value)
			end
			if value.finish == nil then
				print("value.finish missing for ast type " .. tostring(value.type))
				selenScript.helpers.printAST(value)
			elseif type(value.finish) ~= "number" then
				print("value.finish is not a number for ast type " .. tostring(value.type))
				selenScript.helpers.printAST(value)
			end
		end
		for i, v in pairs(value) do
			validate(v)
		end
	end
end


print(tostring(#files) .. " files to test...")
local totalParseTime = 0
local totalSymbolizeTime = 0
local testStartTime = os.clock()
for _, path in ipairs(files) do
	print("--- Parsing " .. tostring(path) .. " ---")
	local program = selenScript.program.new()
	local file = selenScript.file.new(path)
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
				str = tostring(err.start) .. " " .. str
				if err.finish ~= nil then
					str = ":" .. tostring(err.finish) .. " " .. str
				end
			end
			print(str)
		end
		if breakOnSymbolizeDiagnostic then break end
	end

	--[[
	local f = io.open(path, "r")
	local data = f:read("*a")
	f:close()
	local result = selenScript.parser.parse(data)
	totalTime = totalTime + result.parseTime
	-- selenScript.helpers.printAST(result.ast)
	validate(result.ast)
	if #result.errors > 0 then
		print("Errors while parsing file ", path)
		for _, err in ipairs(result.errors) do
			print(tostring(err.start) .. ":" .. tostring(err.finish) .. " " ..  err.msg)
		end
		break
	end
	]]
end

local testProcessTime = os.clock() - testStartTime
print("\nTotal time taken processing test files " .. tostring(testProcessTime) .. "s")
print("Parsing test files took " .. tostring(totalParseTime) .. "s")
print("Symbolizing test files took " .. tostring(totalSymbolizeTime) .. "s")
