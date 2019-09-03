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


local providedList = {}
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
	local luaResult, _ = selenScript.transpiler.transpile(result.ast)
	local name = path:gsub("^.*[\\/]", ""):gsub("%.sl$", "")
	providedList[name] = {
		name=name,
		lua=luaResult
	}
	::continue::
end

for _, v in pairs(providedList) do
	local deps = {}
	v.deps = deps
	for _, other in pairs(providedList) do
		if v ~= other and v.lua:find("__sls_" .. other.name) ~= nil then
			table.insert(deps, other.name)
		end
	end
end

local providedFile = io.open("selenScript/provided.lua", "w")
providedFile:write("-- WARNING: this is a generated file by transpile_provided.lua\n")
providedFile:write("return {\n")

for _, v in pairs(providedList) do
	providedFile:write(v.name .. " = {lua=[======[")
	providedFile:write(v.lua)
	providedFile:write("]======], deps={")
	for _, depName in pairs(v.deps) do
		providedFile:write("'" .. depName .. "',")
	end
	providedFile:write("}},\n")
end

providedFile:write("\n}")
providedFile:close()
