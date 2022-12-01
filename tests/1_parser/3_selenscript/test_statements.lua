local TestLib = require "testlib"

local ParserTestUtils = require "tests.1_parser.parserTestUtils"


TestLib.test("continue", function ()
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
	TestLib.assert_table_match(ast.block, {
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

TestLib.test("conditional_stmt", function ()
	local parser = TestLib.assert(ParserTestUtils.getTestParser())
	local ast, errors, comments = ParserTestUtils.parse(parser, [[
		if true continue
		if true break
		if true goto test
		if true return
	]])
	TestLib.assert(ast ~= nil, "ast ~= nil")
	TestLib.assert(#errors <= 0, "#errors <= 0")
	TestLib.assert(#comments <= 0, "#comments <= 0")
	TestLib.assert_table_match(ast.block, {
		type = "chunk",
		block = {
			type = "block",
			{
				type = "conditional_stmt",
				condition = { type="boolean" },
				{
					type = "continue",
				}
			},
			{
				type = "conditional_stmt",
				condition = { type="boolean" },
				{
					type = "break",
				}
			},
			{
				type = "conditional_stmt",
				condition = { type="boolean" },
				{
					type = "goto",
				}
			},
			{
				type = "conditional_stmt",
				condition = { type="boolean" },
				{
					type = "return",
				}
			}
		}
	})
end)
