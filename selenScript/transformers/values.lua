local helpers = require "selenScript.helpers"
local parser = require "selenScript.parser"

local values = {}
values.__index = values


---@param transformer SS_Transformer
function values.new(transformer)
	local self = setmetatable({}, values)
	self.transformer = transformer
	return self
end

function values:if_expr(ast)
	local varName = self.transformer:getVarName()
	local varExpr = parser.defs.index(-1, "", nil, varName, nil, nil, -1)

	local assignStmt = parser.defs.assign(-1, "local", parser.defs.var_list(-1, varExpr, -1), nil, nil, -1)
	table.insert(self.transformer.prefix_stmts[#self.transformer.prefix_stmts], assignStmt)

	local ifStmt = parser.defs["if"](-1, ast.condition,
		parser.defs.block(-1,
			parser.defs.assign(-1, "", parser.defs.var_list(-1, varExpr, -1), nil, parser.defs.expr_list(-1, ast.trueExpr, -1), -1),
		-1),
		parser.defs["else"](-1,
			parser.defs.block(-1,
				parser.defs.assign(-1, "", parser.defs.var_list(-1, varExpr, -1), nil, parser.defs.expr_list(-1, ast.falseExpr, -1), -1),
			-1),
		-1),
	-1)
	table.insert(self.transformer.prefix_stmts[#self.transformer.prefix_stmts], ifStmt)
	return varExpr
end


return values
