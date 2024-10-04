local TestUtils = require "tests.test_utils"


TEST.addTest("continue", function ()
	local parser = TestUtils.CreateNewParser(TEST)
	local ast, errors, comments = parser:parse([[
		while true do
			continue
			continue
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
				type = "while",
				block = {
					type = "block",
					{ type="continue" },
					{ type="continue" }
				}
			}
		}
	}, true)
end)

TEST.addTest("conditional_stmt", function ()
	local parser = TestUtils.CreateNewParser(TEST)
	local ast, errors, comments = parser:parse([[
		if true continue
		if true break
		if true goto test
		if true return
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
	}, true)
end)

TEST.addTest("plus_assign_stmt", function ()
	local parser = TestUtils.CreateNewParser(TEST)
	local ast, errors, comments = parser:parse([[
		a += 1
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
				type = "plus_assign",
				names = {
					type = "varlist",
					{
						type = "index",
						expr = {
							name = "a",
						}
					},
				},
				values = {
					type = "expressionlist",
					{
						type = "numeral",
						value = "\"1\"",
					}
				}
			}
		}
	}, true)
end)
