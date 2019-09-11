local selenScript = require "selenScript"


local project = selenScript.project.new()

local testFile = selenScript.file.newFile {
	path="tests/project/test.sl"
}
project:addFile(testFile)

print("--- AST ---")
selenScript.helpers.printAST(testFile.ast)

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
