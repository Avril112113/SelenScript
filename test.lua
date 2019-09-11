local filePath = "tests/project/test.sl"
local print_ast = false
local include_provided_deps = true


local selenScript = require "selenScript"


local project = selenScript.project.new {
	src_dir="tests/project",
	provided_deps_require="tests/project/__sls_provided_deps"
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
	local str = diag.serverity:upper() .. " at " .. tostring(diag.start) .. ":" .. tostring(diag.finish) .. " " ..  diag.msg
	if diag.fix ~= nil then
		str = str .. "(fix: '" .. tostring(diag.fix):gsub("\n", "\\n"):gsub("\r", "\\r"):gsub("\t", "\\t") ..  "')"
	end
	print(str)
	if diag.ast ~= nil then
		selenScript.helpers.printAST(diag.ast)
	end
end

--[[
local completePos = 22
local completions = testFile:complete(completePos)
for i, v in ipairs(completions) do
	print(i, v)
end
--]]
