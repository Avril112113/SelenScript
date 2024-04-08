local TestUtils = require "tests.test_utils"


TEST.addTest("assignment_type", function ()
	local parser = TestUtils.CreateNewParser(TEST)
	local ast, errors, comments = parser:parse([[
		local _local_type: string
		_global_type: string
		local non_standard: RandomThing
		local a: string, b: number
	]])
	TestUtils.PrintParseResult(ast, errors, comments)
	TEST.assert("ast ~= nil", ast ~= nil)
	TEST.assert("#errors <= 0", #errors <= 0)
	TEST.assert("#comments <= 0", #comments <= 0)
	TEST.eqDeep(ast, {
		type = "chunk",
		block = {
			type = "block",
			{
				-- TODO
			}
		}
	}, true)
end)

TEST.addTest("type_args", function ()
	local parser = TestUtils.CreateNewParser(TEST)
	local ast, errors, comments = parser:parse([[
		local _local_type: table<string, function>
		local _local_type: array<number>
	]])
	TestUtils.PrintParseResult(ast, errors, comments)
	TEST.assert("ast ~= nil", ast ~= nil)
	TEST.assert("#errors <= 0", #errors <= 0)
	TEST.assert("#comments <= 0", #comments <= 0)
	TEST.eqDeep(ast, {
		type = "chunk",
		block = {
			type = "block",
			{
				-- TODO
			}
		}
	}, true)
end)

TEST.addTest("type_special", function ()
	local parser = TestUtils.CreateNewParser(TEST)
	local ast, errors, comments = parser:parse([[
		local _literal_string: "a"
		local _function: function(arg: string) -> string
		local _code: `_function()`
	]])
	TestUtils.PrintParseResult(ast, errors, comments)
	TEST.assert("ast ~= nil", ast ~= nil)
	TEST.assert("#errors <= 0", #errors <= 0)
	TEST.assert("#comments <= 0", #comments <= 0)
	TEST.eqDeep(ast, {
		type = "chunk",
		block = {
			type = "block",
			{
				-- TODO
			}
		}
	}, true)
end)

TEST.addTest("function_type", function ()
	local parser = TestUtils.CreateNewParser(TEST)
	local ast, errors, comments = parser:parse([[
		function foo(arg1: number) -> string
		end
	]])
	TestUtils.PrintParseResult(ast, errors, comments)
	TEST.assert("ast ~= nil", ast ~= nil)
	TEST.assert("#errors <= 0", #errors <= 0)
	TEST.assert("#comments <= 0", #comments <= 0)
	TEST.eqDeep(ast, {
		type = "chunk",
		block = {
			type = "block",
			{
				-- TODO
			}
		}
	}, true)
end)

TEST.addTest("interface", function ()
	local parser = TestUtils.CreateNewParser(TEST)
	local ast, errors, comments = parser:parse([[
		interface FooBar
			foo: unknown
			foo: number
			<number>: table
		end
	]])
	TestUtils.PrintParseResult(ast, errors, comments)
	TEST.assert("ast ~= nil", ast ~= nil)
	TEST.assert("#errors <= 0", #errors <= 0)
	TEST.assert("#comments <= 0", #comments <= 0)
	TEST.eqDeep(ast, {
		type = "chunk",
		block = {
			type = "block",
			{
				-- TODO
			}
		}
	}, true)
end)
