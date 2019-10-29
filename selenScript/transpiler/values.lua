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
function values:call(ast)
	local str = {}
	local needsParens = not (ast.args.type == "table" or ast.args.type == "String")
	if needsParens then
		str[#str+1] = "("
	else
		str[#str+1] = " "
	end
	str[#str+1] = self.transpiler:transpile(ast.args)
	if needsParens then
		str[#str+1] = ")"
	end
	if ast.index ~= nil then
		str[#str+1] = self.transpiler:transpile(ast.index)
	end
	return table.concat(str)
end

function values:var_args(ast)
	return "..."
end
values["nil"] = function(self, ast)
	return "nil"
end
function values:bool(ast)
	return tostring(ast.value)
end
function values:String(ast)
	local str = {}
	str[#str+1] = ast.quote
	str[#str+1] = ast.value
	str[#str+1] = ast.quote
	return table.concat(str)
end
function values:LongString(ast)
	local str = {}
	str[#str+1] = ast.quote
	if ast.startNewline then
		str[#str+1] = "\n"
	end
	str[#str+1] = ast.value
	str[#str+1] = ast.endQuote
	return table.concat(str)
end
function values:Int(ast)
	return ast.value
end
function values:Float(ast)
	return ast.value
end
function values:Hex(ast)
	local str = {}
	str[#str+1] = "0x"
	str[#str+1] = ast.value
	return table.concat(str)
end
function values:table(ast)
	local str = {}
	str[#str+1] = "{"
	str[#str+1] = self.transpiler:transpile(ast.field_list)
	str[#str+1] = "}"
	return table.concat(str)
end
function values:anon_function(ast)
	local str = {}
	str[#str+1] = "function"
	str[#str+1] = self.transpiler:transpile(ast.body)
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

function values:field(ast)
	if ast.value.type == "var_args" then
		return self.transpiler:transpile(ast.value)
	end
	local str = {}
	if ast.key.type == "String" and ast.key.quote == "" then
		str[#str+1] = self.transpiler:transpile(ast.key)
	else
		str[#str+1] = "["
		str[#str+1] = self.transpiler:transpile(ast.key)
		str[#str+1] = "]"
	end
	str[#str+1] = "="
	str[#str+1] = self.transpiler:transpile(ast.value)
	return table.concat(str)
end
function values:field_list(ast)
	local str = {}
	for i, var in ipairs(ast) do
		if i > 1 then
			str[#str+1] = ", "
		end
		str[#str+1] = self.transpiler:transpile(var)
	end
	return table.concat(str)
end

function values:param(ast)
	return self.transpiler:transpile(ast.name)
end
function values:par_list(ast)
	local str = {}
	for i, param in ipairs(ast) do
		if i > 1 then
			str[#str+1] = ", "
		end
		str[#str+1] = self.transpiler:transpile(param)
	end
	return table.concat(str)
end


return values
