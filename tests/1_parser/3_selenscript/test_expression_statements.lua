local TestLib = require "testlib"

local ParserTestUtils = require "tests.1_parser.parserTestUtils"


TestLib.test("while", function ()
	local parser = TestLib.assert(ParserTestUtils.getTestParser())
	local ast, errors, comments = ParserTestUtils.parse(parser, [[
		_ = while true do
			break 123, 456
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
				-- TODO
			}
		}
	})
end)

TestLib.test("do", function ()
	local parser = TestLib.assert(ParserTestUtils.getTestParser())
	local ast, errors, comments = ParserTestUtils.parse(parser, [[
		_ = do
			return 123, 456
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
				-- TODO
			}
		}
	})
end)

TestLib.test("forrange", function ()
	local parser = TestLib.assert(ParserTestUtils.getTestParser())
	local ast, errors, comments = ParserTestUtils.parse(parser, [[
		_ = for i=1,10,2 do
			break i
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
				-- TODO
			}
		}
	})
end)

TestLib.test("foriter", function ()
	local parser = TestLib.assert(ParserTestUtils.getTestParser())
	local ast, errors, comments = ParserTestUtils.parse(parser, [[
		_ = for i,v in iter do
			break i, v
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
				-- TODO
			}
		}
	})
end)
