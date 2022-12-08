local TestLib = require "testlib"

local ParserTestUtils = require "tests.1_parser.parserTestUtils"


TestLib.test("while", function ()
	local parser = TestLib.assert(ParserTestUtils.getTestParser())
	local ast, errors, comments = ParserTestUtils.parse(parser, [[
		_ = while true do
			break 123, 456
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
				type = "assign",
				values = {
					type = "expressionlist",
					{
						type = "stmt_expr",
						stmt = {
							type = "while",
							block = {
								type = "block",
								{
									type = "break",
									values = {
										type = "expressionlist",
										{
											type = "numeral"
										},
										{
											type = "numeral"
										},
									}
								}
							}
						}
					}
				}
			}
		}
	})
end)

TestLib.test("do", function ()
	local parser = TestLib.assert(ParserTestUtils.getTestParser())
	local ast, errors, comments = ParserTestUtils.parse(parser, [[
		_ = do
			return 123, 456
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
				type = "assign",
				values = {
					type = "expressionlist",
					{
						type = "stmt_expr",
						stmt = {
							type = "do",
							block = {
								type = "block",
								{
									type = "return",
									values = {
										type = "expressionlist",
										{
											type = "numeral"
										},
										{
											type = "numeral"
										},
									}
								}
							}
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
		_ = for i=1,10,2 do
			break i
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
				type = "assign",
				values = {
					type = "expressionlist",
					{
						type = "stmt_expr",
						stmt = {
							type = "forrange",
							block = {
								type = "block",
								{
									type = "break",
									values = {
										type = "expressionlist",
										{
											type = "index",
											expr = {type = "name", name = "i"},
										},
									}
								}
							}
						}
					}
				}
			}
		}
	})
end)

TestLib.test("foriter", function ()
	local parser = TestLib.assert(ParserTestUtils.getTestParser())
	local ast, errors, comments = ParserTestUtils.parse(parser, [[
		_ = for i,v in iter do
			break i, v
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
				type = "assign",
				values = {
					type = "expressionlist",
					{
						type = "stmt_expr",
						stmt = {
							type = "foriter",
							block = {
								type = "block",
								{
									type = "break",
									values = {
										type = "expressionlist",
										{
											type = "index",
											expr = {type = "name", name = "i"},
										},
										{
											type = "index",
											expr = {type = "name", name = "v"},
										},
									}
								}
							}
						}
					}
				}
			}
		}
	})
end)

-- TODO: Add "very complex" tests:
--       Expression `do` and `while` (or any breakables) WITHOUT a `break` with an inner breakable WITH a `break`
