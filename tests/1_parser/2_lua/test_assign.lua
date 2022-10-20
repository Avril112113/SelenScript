local TestLib = require "testlib"

local ParserTestUtils = require "tests.1_parser.parserTestUtils"
local AST = require "SelenScript.parser.ast"


TestLib.test("assign", function ()
	local parser = TestLib.assert(ParserTestUtils.getTestParser())
	local ast, errors, comments = ParserTestUtils.parse(parser, [[
		local _local_novalue
		local _local_value = nil
		_global_value = nil
	]])
	TestLib.assert(ast ~= nil, "ast ~= nil")
	TestLib.assert(#errors <= 0, "#errors <= 0")
	TestLib.assert(#comments <= 0, "#comments <= 0")
end)
