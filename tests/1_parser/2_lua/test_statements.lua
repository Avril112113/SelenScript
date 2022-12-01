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
	TestLib.assert_table_match(ast.block, {
		type = "chunk",
		block = {
			type = "block",
			{
				type = "assign",
				scope = "local",
				values = {},
				names = {
					type = "attributenamelist",
					{
						type = "attributename",
						name = { name="_local_novalue" }
					},
				},
			},
			{
				type = "assign",
				scope = "local",
				values = {
					type = "expressionlist",
					{ type="nil" }
				},
				names = {
					type = "attributenamelist",
					{
						type = "attributename",
						name = { name="_local_value" }
					},
				},
			},
			{
				type = "assign",
				values = {
					type = "expressionlist",
					{ type="nil" }
				},
				names = {
					type = "varlist",
					{
						type = "index",
						expr = { name="_global_value" }
					},
				},
			},
		}
	})
end)

TestLib.test("call", function ()
	local parser = TestLib.assert(ParserTestUtils.getTestParser())
	local ast, errors, comments = ParserTestUtils.parse(parser, [[
		foo()
	]])
	TestLib.assert(ast ~= nil, "ast ~= nil")
	TestLib.assert(#errors <= 0, "#errors <= 0")
	TestLib.assert(#comments <= 0, "#comments <= 0")
	TestLib.assert_table_match(ast.block, {
		type = "chunk",
		block = {
			type = "block",
			{
				type = "index",
				expr = { type="name", name="foo" }
			}
		}
	})
end)

TestLib.test("label", function ()
	local parser = TestLib.assert(ParserTestUtils.getTestParser())
	local ast, errors, comments = ParserTestUtils.parse(parser, [[
		::testlabel::
	]])
	TestLib.assert(ast ~= nil, "ast ~= nil")
	TestLib.assert(#errors <= 0, "#errors <= 0")
	TestLib.assert(#comments <= 0, "#comments <= 0")
	TestLib.assert_table_match(ast.block, {
		type = "chunk",
		block = {
			type = "block",
			{
				type = "label",
				name = { type="name", name="testlabel" }
			}
		}
	})
end)

TestLib.test("break", function ()
	local parser = TestLib.assert(ParserTestUtils.getTestParser())
	local ast, errors, comments = ParserTestUtils.parse(parser, [[
		break
	]])
	TestLib.assert(ast ~= nil, "ast ~= nil")
	TestLib.assert(#errors <= 0, "#errors <= 0")
	TestLib.assert(#comments <= 0, "#comments <= 0")
	TestLib.assert_table_match(ast.block, {
		type = "chunk",
		block = {
			type = "block",
			{
				type = "break"
			}
		}
	})
end)

TestLib.test("goto", function ()
	local parser = TestLib.assert(ParserTestUtils.getTestParser())
	local ast, errors, comments = ParserTestUtils.parse(parser, [[
		goto testlabel
	]])
	TestLib.assert(ast ~= nil, "ast ~= nil")
	TestLib.assert(#errors <= 0, "#errors <= 0")
	TestLib.assert(#comments <= 0, "#comments <= 0")
	TestLib.assert_table_match(ast.block, {
		type = "chunk",
		block = {
			type = "block",
			{
				type = "goto",
				name = { type="name", name="testlabel" }
			}
		}
	})
end)

TestLib.test("do", function ()
	local parser = TestLib.assert(ParserTestUtils.getTestParser())
	local ast, errors, comments = ParserTestUtils.parse(parser, [[
		do
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
				type = "do",
				block = { type="block" }
			}
		}
	})
end)

TestLib.test("while", function ()
	local parser = TestLib.assert(ParserTestUtils.getTestParser())
	local ast, errors, comments = ParserTestUtils.parse(parser, [[
		while true do
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
				type = "while",
				expr = { type="boolean" },
				block = { type="block" }
			}
		}
	})
end)

TestLib.test("repeat", function ()
	local parser = TestLib.assert(ParserTestUtils.getTestParser())
	local ast, errors, comments = ParserTestUtils.parse(parser, [[
		repeat
		until true
	]])
	TestLib.assert(ast ~= nil, "ast ~= nil")
	TestLib.assert(#errors <= 0, "#errors <= 0")
	TestLib.assert(#comments <= 0, "#comments <= 0")
	TestLib.assert_table_match(ast.block, {
		type = "chunk",
		block = {
			type = "block",
			{
				block = { type="block" },
				expr = { type="boolean" }
			}
		}
	})
end)

TestLib.test("if", function ()
	local parser = TestLib.assert(ParserTestUtils.getTestParser())
	local ast, errors, comments = ParserTestUtils.parse(parser, [[
		if true then
		elseif true then
		elseif true then
		else
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
				type = "if",
				condition = { type="boolean" },
				block = { type="block" },
				["else"] = {
					type = "elseif",
					condition = { type="boolean" },
					block = { type="block" },
					["else"] = {
						type = "elseif",
						condition = { type="boolean" },
						block = { type="block" },
						["else"] = {
							type = "else",
							block = { type="block" }
						}
					}
				}
			}
		}
	})
end)

TestLib.test("forrange", function ()
	local parser = TestLib.assert(ParserTestUtils.getTestParser())
	local ast, errors, comments = ParserTestUtils.parse(parser, [[
		for i=1,10,2 do
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
				type = "forrange",
				name = { type="name", name="i" },
				value_start = { type="numeral", value="1" },
				value_finish = { type="numeral", value="10" },
				increment = { type="numeral", value="2" },
				block = { type="block" }
			}
		}
	})
end)

TestLib.test("foriter", function ()
	local parser = TestLib.assert(ParserTestUtils.getTestParser())
	local ast, errors, comments = ParserTestUtils.parse(parser, [[
		for i, v in iter do
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
				namelist = {
					type = "namelist",
					{ type="name", name="i" },
					{ type="name", name="v" }
				},
				values = {
					type = "expressionlist",
					{
						type = "index",
						expr = { type="name", name="iter" }
					}
				},
				block = { type="block" }
			}
		}
	})
end)

TestLib.test("function", function ()
	local parser = TestLib.assert(ParserTestUtils.getTestParser())
	local ast, errors, comments = ParserTestUtils.parse(parser, [[
		local function func_local(a, b)
		end
		function func_global(c, d)
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
				type = "functiondef",
				scope = "local",
				name = { type="name", name="func_local" },
				funcbody = {
					type = "funcbody",
					args = {
						type = "parlist",
						{ type="name", name="a" },
						{ type="name", name="b" }
					},
					block = { type="block" }
				}
			},
			{
				type = "functiondef",
				name = { type="index", expr={ type="name", name="func_global" } },
				funcbody = {
					type = "funcbody",
					args = {
						type = "parlist",
						{ type="name", name="c" },
						{ type="name", name="d" }
					},
					block = { type="block" }
				}
			}
		}
	})
end)
