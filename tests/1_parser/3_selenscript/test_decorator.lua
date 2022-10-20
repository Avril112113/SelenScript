local TestLib = require "testlib"

local ParserTestUtils = require "tests.1_parser.parserTestUtils"
local AST = require "SelenScript.parser.ast"


TestLib.test("decorator", function ()
	local parser = TestLib.assert(ParserTestUtils.getTestParser())
	local ast, errors, comments = ParserTestUtils.parse(parser, [[
		@testdecsimple
		@testdeccomplex()
		function test()
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
				type = "functiondef",
				decorators = {
					{
						type = "decorator",
						expr = {
							type = "index",
							expr = { type="name", name="testdecsimple" }
						}
					},
					{
						type = "decorator",
						expr = {
							type = "index",
							expr = { type="name", name="testdeccomplex" },
							index = {
								type = "index",
								expr = { type = "call" }
							}
						}
					}
				}
			}
		}
	})
end)
