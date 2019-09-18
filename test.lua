local filePath = "tests/test/test.sl"
local print_ast = false
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

--[[
local complete_pos = 0
print("--- Complete:" .. tostring(complete_pos) .. " ---")
--]]

--[[
local completePos = 22
local completions = testFile:complete(completePos)
for i, v in ipairs(completions) do
	print(i, v)
end
--]]
