local TestUtils = require "tests.test_utils"


TEST.addTest("while", function ()
	local parser = TestUtils.CreateNewParser(TEST)
	local ast, errors, comments = parser:parse([[
		_ = while true do
			break 123, 456
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
	}, true)
end)

TEST.addTest("do", function ()
	local parser = TestUtils.CreateNewParser(TEST)
	local ast, errors, comments = parser:parse([[
		_ = do
			return 123, 456
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
	}, true)
end)

TEST.addTest("forrange", function ()
	local parser = TestUtils.CreateNewParser(TEST)
	local ast, errors, comments = parser:parse([[
		_ = for i=1,10,2 do
			break i
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
	}, true)
end)

TEST.addTest("foriter", function ()
	local parser = TestUtils.CreateNewParser(TEST)
	local ast, errors, comments = parser:parse([[
		_ = for i,v in iter do
			break i, v
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
	}, true)
end)


-- TODO: Add "very complex" tests:
--       Expression `do` and `while` (or any breakables) WITHOUT a `break` with an inner breakable WITH a `break`
