local TestUtils = require "tests.test_utils"


TEST.addTest("decorator", function ()
	local parser = TestUtils.CreateParser(TEST)
	local ast, errors, comments = parser:parse([[
		@testDecSimple
		@testDecComplex()
		function test()
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
				type = "functiondef",
				decorators = {
					{
						type = "decorator",
						expr = {
							type = "index",
							expr = { type="name", name="testDecSimple" }
						}
					},
					{
						type = "decorator",
						expr = {
							type = "index",
							expr = { type="name", name="testDecComplex" },
							index = {
								type = "index",
								expr = { type = "call" }
							}
						}
					}
				}
			}
		}
	}, true)
end)
