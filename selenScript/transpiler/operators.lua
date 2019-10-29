local operators = {}
operators.__index = operators


function operators.new(transpiler)
	local self = setmetatable({}, operators)
	self.transpiler = transpiler
	return self
end


function operators:binary_op(ast)
	local str = {}
	str[#str+1] = self.transpiler:transpile(ast.lhs)
	str[#str+1] = " "
	str[#str+1] = ast.operator
	str[#str+1] = " "
	str[#str+1] = self.transpiler:transpile(ast.rhs)
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
