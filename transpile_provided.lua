local selenScript = require "selenScript"


local files = {}
local function addGlob(glob)
	local handle = io.popen('python listTests.py "' .. glob .. '"')
	local filesStr = handle:read "*a"
	handle:close()
	local _files = loadstring("return " .. filesStr, "@listTests.py (RESULT)")()
	for i, v in ipairs(_files) do
		table.insert(files, v)
	end
end

addGlob("selenScript/provided/**/*.sl")

for _, path in ipairs(files) do
	local f = io.open(path, "r")
	local data = f:read("*a")
	f:close()
	local result = selenScript.parser.parse(data)
	if #result.errors > 0 then
		print("Errors while parsing file ", path)
		for _, err in ipairs(result.errors) do
			print(tostring(err.start) .. ":" .. tostring(err.finish) .. " " ..  err.msg)
		end
		goto continue
	end
	local luaResult = selenScript.transpiler.transpile(result.ast)
	local f = io.open(path .. ".lua", "w")
	f:write(luaResult)
	f:close()
	::continue::
end
