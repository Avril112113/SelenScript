local TestLib = require "testlib"

local Parser = require "SelenScript.parser.parser"
local AST = require "SelenScript.parser.ast"


---@type Parser
local testParser
TestLib.test("Parser.new()", function()
	local parser, errors = Parser.new()
	if #errors > 0 then
		print_error("-- Grammar Errors: " .. #errors .. " --")
		for _, v in ipairs(errors) do
			print_error((v.id or "NO_ID") .. ": " .. v.msg)
		end
	end
	TestLib.assert(parser ~= nil, "parser ~= nil")
	TestLib.assert(#errors <= 0, "#errors <= 0")
	testParser = parser
end)

TestLib.test("parser:parse(\"\")", function()
	local ast, errors, comments = testParser:parse("")
	print("-- Parsed AST: --")
	print(AST.tostring_ast(ast))
	if #errors > 0 then
		print_error("-- Parse Errors: " .. #errors .. " --")
		for _, v in ipairs(errors) do
			print_error(v.id .. ": " .. v.msg)
		end
	end
	TestLib.assert(ast ~= nil, "ast ~= nil")
	TestLib.assert(#errors <= 0, "#errors <= 0")
	TestLib.assert(#comments <= 0, "#comments <= 0")
end)
