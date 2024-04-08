local TestUtils = require "tests.test_utils"


TEST.addTest("basic", function ()
	local parser = TestUtils.CreateNewParser(TEST)
	local ast, errors, comments = parser:parse("")
	TestUtils.PrintParseResult(ast, errors, comments)
	TEST.assert("ast ~= nil", ast ~= nil)
	TEST.assert("#errors <= 0", #errors <= 0)
end)
