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
	local luaResult, trans = selenScript.transpiler.transpile(
		selenScript.file.newFile {
			code=data,
			parse_result=result
		}
	)
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
	providedFile:write("\t" .. v.name .. " = {\n\t\tlua=\"")
	local lua_output = v.lua:gsub("\n", "\\n"):gsub("\r", "\\r"):gsub("\t", "\\t"):gsub("\"", "\\\"")
	providedFile:write(lua_output)
	providedFile:write("\",\n\t\tdeps={")
	for _, depName in pairs(v.deps) do
		providedFile:write("\"" .. depName .. "\",")
	end
	providedFile:write("}\n\t},\n")
end

providedFile:write("}")
providedFile:close()
