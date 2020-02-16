local precedence = require "selenscript.precedence"


local operators = {}
operators.__index = operators


---@param transpiler SS_Transpiler
function operators.new(transpiler)
	local self = setmetatable({}, operators)
	self.transpiler = transpiler
	---@type number|nil
	self.last_precedence = nil
	return self
end


function operators:binary_op(ast)
	local str = {}

	local opData = precedence.binaryOpData[ast.operator]
	local prev_precedence = self.last_precedence ~= nil and self.last_precedence + 1 or self.last_precedence
	if opData[3] and prev_precedence ~= nil then
		prev_precedence = prev_precedence + 1
	end
	local surround_brackets = self.last_precedence ~= nil and opData[1] < self.last_precedence
	if surround_brackets then
		str[#str+1] = "("
	end

	self.last_precedence = opData[1]

	str[#str+1] = self.transpiler:transpile(ast.lhs)
	str[#str+1] = " "
	str[#str+1] = ast.operator
	str[#str+1] = " "
	str[#str+1] = self.transpiler:transpile(ast.rhs)

	if surround_brackets then
		str[#str+1] = ")"
	end
	self.last_precedence = prev_precedence

	return table.concat(str)
end
operators.add = operators.binary_op
operators.mul = operators.binary_op
operators.exp = operators.binary_op
operators.eq = operators.binary_op
operators.neq = operators.binary_op
operators.concat = operators.binary_op
operators["and"] = operators.binary_op
operators["or"] = operators.binary_op
operators.bit_shift = operators.binary_op
operators.bit_and = operators.binary_op

function operators:unary_op(ast)
	local str = {}
	str[#str+1] = ast.operator
	str[#str+1] = " "
	str[#str+1] = self.transpiler:transpile(ast.rhs)
	return table.concat(str)
end
operators.neg = operators.unary_op
operators.len = operators.unary_op
operators["not"] = operators.unary_op


return operators
