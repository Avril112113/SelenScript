local TestUtils = require "tests.test_utils"


TEST.addTest("ifexpr", function ()
	local parser = TestUtils.CreateNewParser(TEST)
	local ast, errors, comments = parser:parse([[
		_ = if true then 1 else 0
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
	}, true)
end)
