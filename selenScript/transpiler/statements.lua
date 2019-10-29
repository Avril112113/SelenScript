local statements = {}
statements.__index = statements


function statements.new(transpiler)
	local self = setmetatable({}, statements)
	self.transpiler = transpiler

	self.block_depth = -1
	
	return self
end


function statements:isLocal(scope)
	return scope == "local" or (scope == "" and self.transpiler.settings.defaultLocals)
end


local noSemicolonEndingTypes = {
	Comment=true, LongComment=true
}
function statements:block(ast)
	local str = {}
	self.block_depth = self.block_depth + 1
	for _, stmt in ipairs(ast) do
		str[#str+1] = string.rep(self.transpiler.settings.indent, self.block_depth)
		str[#str+1] = self.transpiler:transpile(stmt)
		if noSemicolonEndingTypes[stmt.type] == nil then
			str[#str+1] = ";"
		end
		str[#str+1] = "\n"
	end
	self.block_depth = self.block_depth - 1
	return table.concat(str)
end

statements["do"] = function(self, ast)
	local str = {}
	str[#str+1] = "do\n"
	str[#str+1] = self.transpiler:transpile(ast.block)
	str[#str+1] = string.rep(self.transpiler.settings.indent, self.block_depth)
	str[#str+1] = "end"
	return table.concat(str)
end
statements["if"] = function(self, ast)
	local str = {}
	str[#str+1] = "if "
	str[#str+1] = self.transpiler:transpile(ast.condition)
	str[#str+1] = " then\n"
	str[#str+1] = self.transpiler:transpile(ast.block)
	if ast.next ~= nil then
		str[#str+1] = self.transpiler:transpile(ast.next)
	end
	str[#str+1] = string.rep(self.transpiler.settings.indent, self.block_depth)
	str[#str+1] = "end"
	return table.concat(str)
end
statements["elseif"] = function(self, ast)
	local str = {}
	str[#str+1] = "elseif "
	str[#str+1] = self.transpiler:transpile(ast.condition)
	str[#str+1] = " then\n"
	str[#str+1] = self.transpiler:transpile(ast.block)
	if ast.next ~= nil then
		str[#str+1] = self.transpiler:transpile(ast.next)
	end
	return table.concat(str)
end
statements["else"] = function(self, ast)
	local str = {}
	str[#str+1] = "else\n"
	str[#str+1] = self.transpiler:transpile(ast.block)
	return table.concat(str)
end
statements["while"] = function(self, ast)
	local str = {}
	str[#str+1] = "while "
	str[#str+1] = self.transpiler:transpile(ast.condition)
	str[#str+1] = " do\n"
	str[#str+1] = self.transpiler:transpile(ast.block)
	str[#str+1] = string.rep(self.transpiler.settings.indent, self.block_depth)
	str[#str+1] = "end"
	return table.concat(str)
end
statements["repeat"] = function(self, ast)
	local str = {}
	str[#str+1] = "repeat\n"
	str[#str+1] = self.transpiler:transpile(ast.block)
	str[#str+1] = string.rep(self.transpiler.settings.indent, self.block_depth)
	str[#str+1] = "until "
	str[#str+1] = self.transpiler:transpile(ast.condition)
	return table.concat(str)
end
function statements:for_each(ast)
	local str = {}
	str[#str+1] = "for "
	str[#str+1] = self.transpiler:transpile(ast.name_list)
	str[#str+1] = " in "
	str[#str+1] = self.transpiler:transpile(ast.expr_list)
	str[#str+1] = " do\n"
	str[#str+1] = self.transpiler:transpile(ast.block)
	str[#str+1] = string.rep(self.transpiler.settings.indent, self.block_depth)
	str[#str+1] = "end"
	return table.concat(str)
end
function statements:for_range(ast)
	local str = {}
	str[#str+1] = "for "
	str[#str+1] = self.transpiler:transpile(ast.varname)
	str[#str+1] = "="
	str[#str+1] = self.transpiler:transpile(ast.from)
	str[#str+1] = ","
	str[#str+1] = self.transpiler:transpile(ast.to)
	if ast.step ~= nil then
		str[#str+1] = ","
		str[#str+1] = self.transpiler:transpile(ast.step)
	end
	str[#str+1] = " do\n"
	str[#str+1] = self.transpiler:transpile(ast.block)
	str[#str+1] = string.rep(self.transpiler.settings.indent, self.block_depth)
	str[#str+1] = "end"
	return table.concat(str)
end
statements["goto"] = function(self, ast)
	local str = {}
	str[#str+1] = "goto "
	str[#str+1] = ast.label
	return table.concat(str)
end
statements["label"] = function(self, ast)
	local str = {}
	str[#str+1] = "::"
	str[#str+1] = ast.label
	str[#str+1] = "::"
	return table.concat(str)
end

statements["function"] = function(self, ast)
	local str = {}
	str[#str+1] = "function "
	str[#str+1] = self.transpiler:transpile(ast.funcname)
	str[#str+1] = self.transpiler:transpile(ast.body)
	return table.concat(str)
end
function statements:funcbody(ast)
	local str = {}
	str[#str+1] = "("
	str[#str+1] = self.transpiler:transpile(ast.args)
	str[#str+1] = ")"
	str[#str+1] = self.transpiler:transpile(ast.block)
	str[#str+1] = string.rep(self.transpiler.settings.indent, self.block_depth)
	str[#str+1] = "end"
	return table.concat(str)
end

function statements:assign(ast)
	local str = {}
	if self:isLocal(ast.scope) then
		str[#str+1] = "local "
	end
	str[#str+1] = self.transpiler:transpile(ast.var_list)
	if ast.attrib ~= nil then
		str[#str+1] = "<"
		str[#str+1] = ast.attrib
		str[#str+1] = ">"
	end
	if ast.expr_list ~= nil then
		str[#str+1] = " = "
		str[#str+1] = self.transpiler:transpile(ast.expr_list)
	end
	return table.concat(str)
end

statements["return"] = function(self, ast)
	local str = {}
	str[#str+1] = "return"
	if ast.expr_list ~= nil then
		str[#str+1] = " "
		str[#str+1] = self.transpiler:transpile(ast.expr_list)
	end
	return table.concat(str)
end
statements["break"] = function(self, ast)
	return "break"
end

function statements:Comment(ast)
	local str = {}
	str[#str+1] = "--"
	str[#str+1] = ast.comment
	return table.concat(str)
end
function statements:LongComment(ast)
	local str = {}
	str[#str+1] = "--"
	str[#str+1] = self.transpiler:transpile(ast.comment)
	return table.concat(str)
end


return statements
