local TestLib = require "testlib"

local ParserTestUtils = require "tests.1_parser.parserTestUtils"


TestLib.test("ifexpr", function ()
	local parser = TestLib.assert(ParserTestUtils.getTestParser())
	local ast, errors, comments = ParserTestUtils.parse(parser, [[
		_ = if true then 1 else 0
	]])
	TestLib.assert(ast ~= nil, "ast ~= nil")
	TestLib.assert(#errors <= 0, "#errors <= 0")
	TestLib.assert(#comments <= 0, "#comments <= 0")
	TestLib.assert_table_match(ast, {
		type = "chunk",
		block = {
			type = "block",
			{
				type = "assign",
				values = {
					type = "expressionlist",
					{
						type = "ifexpr",
						lhs = { type="numeral" },
						condition = { type="boolean" },
						rhs = { type="numeral" },
					}
				}
			}
		}
	})
end)