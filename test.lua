local filePath = "test.sl"  -- relitive to src_dir
local print_ast = true
local include_provided_deps = true


local relabel = require "relabel"
local selenScript = require "selenScript"


local project = selenScript.project.new {
	src_dir="tests/test",
	provided_deps_require="tests/test/__sls_provided_deps"
}
local testFile = selenScript.file.new {
	path=filePath,
	include_provided_deps=include_provided_deps,

	project=project
}

if print_ast then
	print("--- AST ---")
	selenScript.helpers.printAST(testFile.ast)
end

print("--- Diagnostics ---")
for _, diag in pairs(testFile.diagnostics) do
	local errType = diag.type or "nil"
	local sl, sc = relabel.calcline(testFile.code, diag.start)
	local str = diag.serverity:upper() .. ":" .. errType .. " at " .. tostring(sl) .. ":" .. tostring(sc) .. " " ..  diag.msg
	if diag.fix ~= nil then
		str = str .. "\nfix: '" .. tostring(diag.fix):gsub("\n", "\\n"):gsub("\r", "\\r"):gsub("\t", "\\t") ..  "'"
	end
	print(str)
	if diag.ast ~= nil then
		selenScript.helpers.printAST(diag.ast)
	end
end

print("--- VM ---")
local function strType(type)
	if type == nil then return "unknown" end
	if type.type == "type" then
		return type.name
	elseif type.type == "type_array" then
		return type.name .. "[" .. strType(type.valuetype) .. "]"
	elseif type.type == "type_table" then
		return type.name .. "[" .. strType(type.keytype) .. "=" .. strType(type.valuetype) .. "]"
	elseif type.type == "type_function" then
		local str = "function"
		if type.type_args ~= nil then
			str = str .. "("
			for i, arg in ipairs(type.type_args) do
				if i > 1 then str = str .. "," end
				str = str .. arg.name
				if arg.param_type ~= nil then
					str = str .. ":" .. strType(arg.param_type)
				end
			end
			str = str .. ")"
		end
		if type.type_return ~= nil then
			str = str .. "->" .. strType(type.type_return)
		end
		return str
	else
		return "<Unknown:" .. tostring(type.type) .. ">"
	end
end
local function strVariable(origin, k, v)
	return selenScript.helpers.strValueFromType(k) .. ": " .. strType(origin.types[k]) .. " = " .. selenScript.helpers.strValueFromType(v) .. " (Refs: " .. origin.references[k] .. ")"
end
local function printVmTable(slTbl, indent)
	indent = indent or 0
	local indentStr = string.rep("    ", indent)
	local printed = {}
	for k, v in pairs(slTbl.content) do
		print(indentStr .. strVariable(slTbl, k, v))
		if type(v) == "table" and v.content ~= nil and v.types ~= nil then
			printVmTable(v, indent+1)
		end
		printed[k] = v
	end
	for k, v in pairs(slTbl.references) do
		if printed[k] == nil then
			print(indentStr .. selenScript.helpers.strValueFromType(k) .. ": " .. strType(slTbl.types[k]))
		end
		printed[k] = v
	end
end
print("- Globals -")
printVmTable(testFile.vm.globals)
print("- Main Block Variables -")
printVmTable(testFile.vm.block.locals)

--[[
local complete_pos = 7
print("--- Complete:" .. tostring(complete_pos) .. " ---")
local completions = testFile:complete(complete_pos)
for i, v in ipairs(completions) do
	print(v)
end
--]]
