local helpers = require "selenScript.helpers"

local statements = {}
statements.__index = statements


function statements.new(transpiler)
	local self = setmetatable({}, statements)
	self.transpiler = transpiler
	self.block_depth = -1
	return self
end


function statements:block(ast)
	local str = {}
	self.block_depth = self.block_depth + 1
	for _, stmt in ipairs(ast) do
		str[#str+1] = string.rep(self.transpiler.settings.indent, self.block_depth)
		str[#str+1] = self.transpiler:transpile(stmt)
		str[#str+1] = ";"
		str[#str+1] = "\n"
	end
	self.block_depth = self.block_depth - 1
	return table.concat(str)
end

function statements:assign(ast)
	local str = {}
	local isLocal = ast.scope == "local" or (ast.scope == "" and self.transpiler.settings.defaultLocals)
	if isLocal then
		str[#str+1] = "local "
	end
	str[#str+1] = self.transpiler:transpile(ast.var_list)
	if ast.expr_list ~= nil then
		str[#str+1] = " = "
		str[#str+1] = self.transpiler:transpile(ast.expr_list)
	end
	return table.concat(str)
end


return statements
