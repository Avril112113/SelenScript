local TestLib = require "testlib"

local ParserTestUtils = require "tests.1_parser.parserTestUtils"
local AST = require "SelenScript.parser.ast"


TestLib.test("assign", function ()
	local parser = TestLib.assert(ParserTestUtils.getTestParser())
	local ast, errors, comments = ParserTestUtils.parse(parser, [[
		while true do
			continue
			continue
		end
	]])
	TestLib.assert(ast ~= nil, "ast ~= nil")
	TestLib.assert(#errors <= 0, "#errors <= 0")
	TestLib.assert(#comments <= 0, "#comments <= 0")
	TestLib.assert_table_match(ast, {
		type = "chunk",
		block = {
			type = "block",
			{
				type = "while",
				block = {
					type = "block",
					{ type="continue" },
					{ type="continue" }
				}
			}
		}
	})
end)
