local TestLib = require "testlib"

local AST = require "SelenScript.parser.ast"


local ParserTestUtils = {}


--- local parser = TestLib.assert(ParserTestUtils.getTestParser())
---@type Parser
local testParser
function ParserTestUtils.getTestParser()
	return testParser, "No test parser available."
end
---@param parser Parser
function ParserTestUtils.setTestParser(parser)
	testParser = parser
end

---@param parser Parser
---@param source string
function ParserTestUtils.parse(parser, source)
	local ast, errors, comments = parser:parse(source)
	print_info("-- Parsed AST: --")
	print_info(AST.tostring_ast(ast))
	if #errors > 0 then
		print_info("-- Parse Errors: " .. #errors .. " --")
		for _, v in ipairs(errors) do
			print_info(v.id .. ": " .. v.msg)
		end
	end
	return ast, errors, comments
end


return ParserTestUtils
