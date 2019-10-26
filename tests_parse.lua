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
local totalTime = 0
for _, path in ipairs(files) do
	print("Parsing", path)
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
end

print("Parsing test files took " .. tostring(totalTime) .. "s")
