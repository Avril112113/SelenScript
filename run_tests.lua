local bl = {
	Sp=true,
	Sc=true,
	Scc=true,
	Comment=true,
	LongComment=true,
}
-- function debug.relabelDbgFilter(n) return bl[n] == nil end

local selenScript = require "selenScript"

local files = {}
local function addTests(glob)
	local handle = io.popen('python listTests.py "' .. glob .. '"')
	local filesStr = handle:read "*a"
	handle:close()
	local _files = loadstring("return " .. filesStr, "@listTests.py (RESULT)")()
	for i, v in ipairs(_files) do
		table.insert(files, v)
	end
end

addTests("tests/selenScript/**/*.sl")
addTests("tests/pure lua/**/*.lua")

print(tostring(#files) .. " files to test...")
local totalTime = 0
local totalTransTime = 0
for _, path in ipairs(files) do
	print("Parsing", path)
	local f = io.open(path, "r")
	local data = f:read("*a")
	f:close()
	local result = selenScript.parser.parse(data)
	totalTime = totalTime + result.parseTime
	if #result.errors > 0 then
		print("Errors while parsing file ", path)
		for _, err in ipairs(result.errors) do
			print(tostring(err.start) .. ":" .. tostring(err.finish) .. " " ..  err.msg)
		end
		break
	end
	local start = os.clock()
	local luaResult, _ = selenScript.transpiler.transpile(result.ast)
	local finish = os.clock()
	totalTransTime = totalTransTime + finish-start
	-- theres more operators, but this should do
	if luaResult:find("<<") ~= nil or luaResult:find(">>") ~= nil then
		print("Skipping syntax check, has luaJIT incompatabilities.")
	else
		local _, err = loadstring(luaResult, "@luaResult")
		if err ~= nil then
			print("Resulting Lua Error:", err)
			print(luaResult)
			break
		end
	end
end

print("Parsing test files took " .. tostring(totalTime) .. "s")
print("Transpiling test files took " .. tostring(totalTransTime) .. "s")
