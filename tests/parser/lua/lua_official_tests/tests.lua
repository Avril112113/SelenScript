local TestUtils = require "tests.test_utils"


---@param full_path string
---@param local_path string
local function add_test(full_path, local_path)
	TEST.addTest(local_path, function ()
		local source = TestUtils.ReadFile(full_path)
		local parser = TestUtils.CreateParser(TEST)
		local ast, errors, comments = parser:parse(source, full_path)
		TestUtils.PrintParseResult(ast, errors, comments)
		TEST.assert("ast ~= nil", ast ~= nil)
		TEST.assert("#errors <= 0", #errors <= 0)
	end)
end

TestUtils.RunForEachLuaFile("./tests/parser/lua/lua_official_tests/tests", add_test)
