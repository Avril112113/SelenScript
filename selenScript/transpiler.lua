local transpiler = {
	expr_stmts={
		["while"]=true, for_range=true, for_each=true,
		["do"]=true, if_expr=true
	}
}
transpiler.__index = transpiler
local function add(name, f)
	transpiler[name] = f
end
function transpiler.transpile(ast)
	local self = setmetatable({}, transpiler)
	self.block_depth = 0
	self.reserve_var_idx = -1

	self.doreturn_depth = 0
	---@type table<number,string>
	self.doreturn = {}

	self.continuelabel_depth = 0
	---@type table<number,string>
	self.continuelabel = {}

	self.expr_stmt_depth = -1
	---@type string[][]
	self.expr_stmt_names = {}  -- LIFO
	---@type string[]
	self.expr_stmt_codes = {}
	return self:tostring(ast)
end
function transpiler:getReserveName()
	self.reserve_var_idx = self.reserve_var_idx + 1
	return "__sls" .. tostring(self.reserve_var_idx)
end
function transpiler:tostring(value, ...)
	if type(value) == "table" and value.type ~= nil then
		local f = self[value.type]
		if f == nil then
			print("ERROR: missing transpile function '" .. tostring(value.type) .. "'")
			return " "
		else
			return f(self, value, ...)
		end
	else
		return tostring(value)
	end
end
function transpiler:strexpr(value, ...)
	local result
	if transpiler.expr_stmts[value.type] ~= nil then
		self.expr_stmt_depth = self.block_depth
		local prefixStmt = self:tostring(value, ...)
		self.expr_stmt_depth = self.block_depth-1
		local names = table.remove(self.expr_stmt_names) or {}
		if #names <= 0 then
			result = "nil"
		else
			prefixStmt = "local " .. table.concat(names) .. "\n" .. prefixStmt
			result = table.concat(names, ",")
		end
		table.insert(self.expr_stmt_codes, prefixStmt)
		return result
	else
		return self:tostring(value, ...)
	end
end
function transpiler:getExprStmtCode()
	local t = self.expr_stmt_codes
	self.expr_stmt_codes = {}
	return table.concat(t)
end

add("block", function(self, ast)
	local str = ""
	self.block_depth = self.block_depth + 1
	for i, v in ipairs(ast) do
		str = str .. self:tostring(v)
	end
	self.block_depth = self.block_depth - 1
	if #self.expr_stmt_codes > 0 then
		print("WARNING: unexpected results may be caused by expr_stmt_codes not being empty at end of block.")
	end
	return str
end)

add("index", function(self, ast)
	local str = ""
	if ast.op ~= nil then
		str = str .. ast.op
	end
	if ast.name ~= nil then
		str = str .. self:tostring(ast.name)
	-- special case `({})[1]` or `(""):f()` ect
	elseif ast.index ~= nil and (ast.expr.type == "table" or ast.expr.type == "String" or ast.expr.type == "LongString" or ast.expr.type == "anon_function") then
		str = str .. "(" .. self:strexpr(ast.expr) .. ")"
	else
		str = str .. self:strexpr(ast.expr)
	end
	if ast.op == "[" then
		str = str .. "]"
	end
	if ast.index ~= nil then
		str = str .. self:tostring(ast.index)
	end
	return str
end)
add("call", function(self, ast)
	local str = "(" .. self:tostring(ast.args) .. ")"
	if ast.index ~= nil then
		str = str .. self:tostring(ast.index)
	end
	return self:getExprStmtCode() .. str
end)
add("field", function(self, ast)
	if ast.name ~= nil then
		return self:tostring(ast.name)
	else
		return self:strexpr(ast.expr)
	end
end)

add("funcbody", function(self, ast)
	return "(" .. self:tostring(ast.args) .. ")" .. self:tostring(ast.block) .. "end"
end)
add("return", function(self, ast)
	local str = ""
	if self.expr_stmt_depth+1 == self.block_depth then
		if ast.exprlist ~= nil then
			local exprs = self:tostring(ast.exprlist)
			local names = {}
			for i=1,#ast.exprlist do
				names[i] = self:getReserveName()
			end
			local assigns = table.concat(names, ",") .. "=" .. exprs .. ";"
			table.insert(self.expr_stmt_names, names)
			str = assigns .. str
		end
		local name = "doreturn" .. tostring(self.doreturn_depth)
		self.doreturn[self.doreturn_depth] = name
		str = str .. "goto " .. name
	else
		str = "return " .. self:tostring(ast.exprlist)
	end
	if ast.stmt_if ~= nil then
		str = "if " .. self:tostring(ast.stmt_if) .. " then " .. str .. " end"
	end
	return self:getExprStmtCode() .. str .. "\n"
end)

add("assign", function(self, ast)
	local str = ""
	-- if its a global variable that has a type and no value (invalid Lua syntax)
	if #ast.scope ~= "local" and ast.exprlist == nil then
		return ""
	end
	if ast.scope == "local" then
		str = str .. "local "
	end
	str = str .. self:tostring(ast.varlist)
	if ast.exprlist ~= nil then
		str = str .. "=" .. self:tostring(ast.exprlist)
	end
	return self:getExprStmtCode() .. str .. "\n"
end)
add("label", function(self, ast)
	return self:getExprStmtCode() .. "::" .. self:tostring(ast.label) .. "::\n"
end)
add("break", function(self, ast)
	local str = "break"
	if self.expr_stmt_depth+1 == self.block_depth then
		if ast.exprlist ~= nil then
			local exprs = self:tostring(ast.exprlist)
			local names = {}
			for i=1,#ast.exprlist do
				names[i] = self:getReserveName()
			end
			local assigns = table.concat(names, ",") .. "=" .. exprs .. ";"
			table.insert(self.expr_stmt_names, names)
			str = assigns .. str
		end
	end
	if ast.stmt_if ~= nil then
		str = "if " .. self:tostring(ast.stmt_if) .. " then " .. str .. " end"
	end
	return self:getExprStmtCode() .. str .. "\n"
end)
add("continue", function(self, ast)
	local name = "continue" .. tostring(self.continuelabel_depth)
	self.continuelabel[self.continuelabel_depth] = name
	local str = "goto " .. name
	if ast.stmt_if ~= nil then
		str = "if " .. self:tostring(ast.stmt_if) .. " then " .. str .. " end"
	end
	return self:getExprStmtCode() .. str .. "\n"
end)
add("goto", function(self, ast)
	local str = "goto " .. self:tostring(ast.label)
	if ast.stmt_if ~= nil then
		str = "if " .. self:tostring(ast.stmt_if) .. " then " .. str .. " end"
	end
	return self:getExprStmtCode() .. str .. "\n"
end)
add("do", function(self, ast)
	local old_doreturn_depth = self.doreturn_depth
	self.doreturn_depth = self.block_depth
	local str = self:getExprStmtCode() .. "do\n" .. self:tostring(ast.block)
	if self.doreturn[self.doreturn_depth] ~= nil then
		str = str .. "::" .. self.doreturn[self.doreturn_depth] .. ":: "
		table.remove(self.doreturn, self.doreturn_depth)
	end
	self.doreturn_depth = old_doreturn_depth
	return str .. "end\n"
end)
add("while", function(self, ast)
	local old_continuelabel_depth = self.continuelabel_depth
	self.continuelabel_depth = self.block_depth
	local str = "while " .. self:tostring(ast.condition) .. " do " .. self:tostring(ast.block)
	if self.continuelabel[self.continuelabel_depth] ~= nil then
		str = str .. "::" .. self.continuelabel[self.continuelabel_depth] .. ":: "
		table.remove(self.continuelabel, self.continuelabel_depth)
	end
	self.continuelabel_depth = old_continuelabel_depth
	return self:getExprStmtCode() .. str .. "end\n"
end)
add("repeat", function(self, ast)
	local old_continuelabel_depth = self.continuelabel_depth
	self.continuelabel_depth = self.block_depth
	local str = "repeat " .. self:tostring(ast.block) .. "until " .. self:tostring(ast.condition)
	if self.continuelabel[self.continuelabel_depth] ~= nil then
		str = str .. "::" .. self.continuelabel[self.continuelabel_depth] .. ":: "
		table.remove(self.continuelabel, self.continuelabel_depth)
	end
	self.continuelabel_depth = old_continuelabel_depth
	return self:getExprStmtCode() .. str .. "\n"
end)
add("else", function(self, ast)
	local str = "else " .. self:tostring(ast.block)
	if ast.next ~= nil then
		str = str .. self:tostring(ast.next)
	end
	return str
end)
add("elseif", function(self, ast)
	local str = "elseif " .. self:tostring(ast.condition) .. " then " .. self:tostring(ast.block)
	if ast.next ~= nil then
		str = str .. self:tostring(ast.next)
	end
	return str
end)
add("if", function(self, ast)
	local str = "if " .. self:tostring(ast.condition) .. " then\n" .. self:tostring(ast.block)
	if ast.next ~= nil then
		str = str .. self:tostring(ast.next)
	end
	return self:getExprStmtCode() .. str .. "end\n"
end)
add("for_range", function(self, ast)
	local old_continuelabel_depth = self.continuelabel_depth
	self.continuelabel_depth = self.block_depth
	local str = "for " .. self:tostring(ast.varname) .. "=" .. self:tostring(ast.from) .. "," .. self:tostring(ast.to)
	if ast.step ~= nil then
		str = str .. "," .. self:tostring(ast.step)
	end
	str = str .. " do\n" .. self:tostring(ast.block)
	if self.continuelabel[self.continuelabel_depth] ~= nil then
		str = str .. "::" .. self.continuelabel[self.continuelabel_depth] .. ":: "
		table.remove(self.continuelabel, self.continuelabel_depth)
	end
	self.continuelabel_depth = old_continuelabel_depth
	return self:getExprStmtCode() .. str .. "end\n"
end)
add("for_each", function(self, ast)
	local old_continuelabel_depth = self.continuelabel_depth
	self.continuelabel_depth = self.block_depth
	local str = "for " .. self:tostring(ast.namelist) .. " in " .. self:tostring(ast.exprlist) .. " do\n" .. self:tostring(ast.block)
	if self.continuelabel[self.continuelabel_depth] ~= nil then
		str = str .. "::" .. self.continuelabel[self.continuelabel_depth] .. ":: "
		table.remove(self.continuelabel, self.continuelabel_depth)
	end
	self.continuelabel_depth = old_continuelabel_depth
	return self:getExprStmtCode() .. str .. "end\n"
end)
add("interface", function(self, ast)
	return ""
end)
add("function", function(self, ast)
	local str = ""
	if ast.scope == "local" then
		str = str .. "local "
	end
	return self:getExprStmtCode() .. str .. "function " .. self:tostring(ast.funcname) .. self:tostring(ast.body) .. "\n"
end)
add("decorate", function(self, ast)
	local str = self:strexpr(ast.expr)
	assert(type(ast.expr) == "table")
	assert(ast.expr.type == "function")
	local funcname = self:tostring(ast.expr.funcname)
	local decoratorsStr = funcname
	for i=#ast.decorators,1,-1 do
		local dec = ast.decorators[i]
		decoratorsStr = self:tostring(dec.index) .. "(" .. decoratorsStr
		if dec.call ~= nil then
			for _, arg in ipairs(dec.call) do
				decoratorsStr = decoratorsStr .. "," .. self:tostring(arg)
			end
		end
		decoratorsStr = decoratorsStr  .. ")"
	end
	return self:getExprStmtCode() .. str .. funcname .. "=" .. decoratorsStr
end)

add("exprlist", function(self, ast)
	local str = ""
	for i, v in ipairs(ast) do
		-- TODO
		str = str .. self:strexpr(v)
		if i ~= #ast then
			str = str .. ","
		end
	end
	return str
end)
add("varlist", function(self, ast)
	local str = ""
	for i, v in ipairs(ast) do
		str = str .. self:tostring(v)
		if i ~= #ast then
			str = str .. ","
		end
	end
	return str
end)
add("namelist", function(self, ast)
	local str = ""
	for i, v in ipairs(ast) do
		str = str .. self:tostring(v)
		if i ~= #ast then
			str = str .. ","
		end
	end
	return str
end)
add("fieldlist", function(self, ast)
	local str = ""
	for i, v in ipairs(ast) do
		str = str .. self:tostring(v)
		if i ~= #ast then
			str = str .. ","
		end
	end
	return str
end)


add("param", function(self, ast)
	return self:tostring(ast.name)
end)
add("parlist", function(self, ast)
	local str = ""
	for i, v in ipairs(ast) do
		str = str .. self:tostring(v)
		if i ~= #ast then
			str = str .. ","
		end
	end
	return str
end)

add("if_expr", function(self, ast)
	local name = self:getReserveName()
	local str = "if " .. self:strexpr(ast.condition) .. " then " ..
				name .. "=" .. self:strexpr(ast.lhs) .. " else " ..
				name .. "=" .. self:strexpr(ast.rhs) .. " end\n"
	table.insert(self.expr_stmt_names, {name})
	return str
end)
add("String", function(self, ast)
	return ast.quote .. ast.value .. ast.quote
end)
add("LongString", function(self, ast)
	local eqStr = string.rep("=", ast.quoteEqLen)
	return "[" .. eqStr .. "[" .. ast.value .. "]" .. eqStr .. "]"
end)
add("FormatString", function(self, ast)
	local value = ""
	local skipStart, skipEnd = false, false
	for i, v in ipairs(ast.parts) do
		if type(v) == "table" then
			if i > 1 then
				value = value  .. ast.quote .. ".."
			else
				skipStart = true
			end
			value = value .. "tostring(" .. self:tostring(v) .. ")"
			if i < #ast.parts then
				value = value  .. ".." .. ast.quote
			else
				skipEnd = true
			end
		else
			value = value .. v
		end
	end
	if not skipStart then
		value = ast.quote .. value
	end
	if not skipEnd then
		value = value .. ast.quote
	end
	return value
end)
add("STRFormat", function(self, ast)
	return self:tostring(ast.expr)
end)
add("Int", function(self, ast)
	return self:tostring(ast.value)
end)
add("Float", function(self, ast)
	return self:tostring(ast.value)
end)
add("Hex", function(self, ast)
	return "0x" .. self:tostring(ast.value)
end)
add("bool", function(self, ast)
	return "(" .. self:tostring(ast.value) .. ")"
end)
add("nil", function(self, ast)
	return "(" .. self:tostring(ast.value) .. ")"
end)
add("table", function(self, ast)
	return "{" .. self:tostring(ast.fieldlist) .. "}"
end)
add("anon_function", function(self, ast)
	return "function" .. self:tostring(ast.body)
end)
add("var_args", function(self)
	return "..."
end)

-- Operators
local binaryOperator = function(self, ast)
	return "(" .. self:tostring(ast.lhs) .. ast.operator .. self:tostring(ast.rhs) .. ")"
end
local binaryOperatorSp = function(self, ast)
	return "(" .. self:tostring(ast.lhs) .. " " .. ast.operator .. " " .. self:tostring(ast.rhs) .. ")"
end
local postfixOperator = function(self, ast)
	return "(" .. ast.operator .. self:tostring(ast.rhs) .. ")"
end
add("eq", binaryOperator)
add("add", binaryOperator)
add("mul", binaryOperator)
add("exp", binaryOperator)
add("concat", binaryOperator)
add("bit_shift", binaryOperator)
add("bit_and", binaryOperator)
add("bit_or", binaryOperator)
add("bit_eor", binaryOperator)
add("and", binaryOperatorSp)
add("or", binaryOperatorSp)

add("not", postfixOperator)
add("neg", postfixOperator)
add("len", postfixOperator)
add("bit_not", postfixOperator)

-- Comments
add("Comment", function(self, ast) return "" end)
add("LongComment", function(self, ast) return "" end)

-- Types
add("type", function(self, ast) return "" end)
add("typelist", function(self, ast) return "" end)
add("type_and", function(self, ast) return "" end)
add("type_or", function(self, ast) return "" end)

return transpiler
