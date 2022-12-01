local TestLib = require "testlib"

local ParserTestUtils = require "tests.1_parser.parserTestUtils"


TestLib.test("assignment_type", function ()
	local parser = TestLib.assert(ParserTestUtils.getTestParser())
	local ast, errors, comments = ParserTestUtils.parse(parser, [[
		local _local_type: string
		_global_type: string
		local non_standard: RandomThing
		local a: string, b: number
	]])
	TestLib.assert(ast ~= nil, "ast ~= nil")
	TestLib.assert(#errors <= 0, "#errors <= 0")
	TestLib.assert(#comments <= 0, "#comments <= 0")
	TestLib.assert_table_match(ast.block, {
		type = "chunk",
		block = {
			type = "block",
			{
				-- TODO
			}
		}
	})
end)

TestLib.test("type_args", function ()
	local parser = TestLib.assert(ParserTestUtils.getTestParser())
	local ast, errors, comments = ParserTestUtils.parse(parser, [[
		local _local_type: table<string, function>
		local _local_type: array<number>
	]])
	TestLib.assert(ast ~= nil, "ast ~= nil")
	TestLib.assert(#errors <= 0, "#errors <= 0")
	TestLib.assert(#comments <= 0, "#comments <= 0")
	TestLib.assert_table_match(ast.block, {
		type = "chunk",
		block = {
			type = "block",
			{
				-- TODO
			}
		}
	})
end)

TestLib.test("type_special", function ()
	local parser = TestLib.assert(ParserTestUtils.getTestParser())
	local ast, errors, comments = ParserTestUtils.parse(parser, [[
		local _literal_string: "a"
		local _function: function(arg: string) -> string
		local _code: `_function()`
	]])
	TestLib.assert(ast ~= nil, "ast ~= nil")
	TestLib.assert(#errors <= 0, "#errors <= 0")
	TestLib.assert(#comments <= 0, "#comments <= 0")
	TestLib.assert_table_match(ast.block, {
		type = "chunk",
		block = {
			type = "block",
			{
				-- TODO
			}
		}
	})
end)

TestLib.test("function_type", function ()
	local parser = TestLib.assert(ParserTestUtils.getTestParser())
	local ast, errors, comments = ParserTestUtils.parse(parser, [[
		function foo(arg1: number) -> string
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
				-- TODO
			}
		}
	})
end)

TestLib.test("interface", function ()
	local parser = TestLib.assert(ParserTestUtils.getTestParser())
	local ast, errors, comments = ParserTestUtils.parse(parser, [[
		interface FooBar
			foo: unknown
			foo: number
			<number>: table
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
				-- TODO
			}
		}
	})
end)