local TestLib = require "testlib"

local ParserTestUtils = require "tests.1_parser.parserTestUtils"
local Parser = require "SelenScript.parser.parser"
local AST = require "SelenScript.parser.ast"


TestLib.test("Parser.new()", function()
	local parser, errors = Parser.new()
	if #errors > 0 then
		print_error("-- Grammar Errors: " .. #errors .. " --")
		for _, v in ipairs(errors) do
			print_error((v.id or "NO_ID") .. ": " .. v.msg)
		end
	end
	TestLib.assert(parser ~= nil, "parser ~= nil")  ---@cast parser -?
	TestLib.assert(#errors <= 0, "#errors <= 0")
	ParserTestUtils.setTestParser(parser)
end)

TestLib.test("parser:parse(\"\")", function()
	local parser = TestLib.assert(ParserTestUtils.getTestParser())
	local ast, errors, comments = ParserTestUtils.parse(parser, "")
	TestLib.assert(ast ~= nil, "ast ~= nil")
	TestLib.assert(#errors <= 0, "#errors <= 0")
	TestLib.assert(#comments <= 0, "#comments <= 0")
	TestLib.assert_table_match(ast, {
		type = "source",
		start = 1,
		finish = 1,
		source = ""
	})
end)
