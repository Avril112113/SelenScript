local helpers = require "selenScript.helpers"

local values = {}
values.__index = values


function values.new(transpiler)
	local self = setmetatable({}, values)
	self.transpiler = transpiler
	return self
end


function values:index(ast)
	local str = {}
	str[#str+1] = ast.op
	str[#str+1] = self.transpiler:transpile(ast.expr)
	if ast.index ~= nil then
		str[#str+1] = self.transpiler:transpile(ast.index)
	end
	return table.concat(str)
end

values["nil"] = function(self, ast)
	return "nil"
end
function values:String(ast)
	local str = {}
	str[#str+1] = ast.quote
	str[#str+1] = ast.value
	str[#str+1] = ast.quote
	return table.concat(str)
end
function values:Int(ast)
	local str = {}
	str[#str+1] = ast.value
	return table.concat(str)
end

function values:name_list(ast)
	local str = {}
	for i, name in ipairs(ast) do
		if i > 1 then
			str[#str+1] = ", "
		end
		str[#str+1] = self.transpiler:transpile(name)
	end
	return table.concat(str)
end
function values:expr_list(ast)
	local str = {}
	for i, expr in ipairs(ast) do
		if i > 1 then
			str[#str+1] = ", "
		end
		str[#str+1] = self.transpiler:transpile(expr)
	end
	return table.concat(str)
end
function values:var_list(ast)
	local str = {}
	for i, var in ipairs(ast) do
		if i > 1 then
			str[#str+1] = ", "
		end
		str[#str+1] = self.transpiler:transpile(var)
	end
	return table.concat(str)
end


return values
