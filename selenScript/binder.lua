---@class SS_Binder
local Binder = {}
Binder.__index = Binder


---@class SS_Symbol
local Symbol = {
	---@type any[]
	values=nil,
}
Symbol.__index = Symbol


---@param name string
function Symbol.new(name)
	return setmetatable({
		key = name or error("Missing arg name")
	}, Symbol)
end

function Symbol:addDeclaration(ast)
	self.declarations = self.declarations or {}
	table.insert(self.declarations, ast)
end

function Symbol:addValue(ast)
	self.values = self.values or {}
	table.insert(self.values, ast)
end

function Symbol:addType(ast)
	self.types = self.types or {}
	table.insert(self.types, ast)
end


function Binder.getLocals(ast)
	while ast.locals == nil or ast == nil do
		ast = ast.parent
	end
	return ast.locals
end

function Binder.new(source_file)
	local diagnostics = {}
	return setmetatable({source_file=source_file, diagnostics=diagnostics}, Binder)
end


function Binder:bind(ast, parent)
	ast.parent = parent
	local binderFunc = self["bind_" .. ast.type]
	if binderFunc == nil then
		table.insert(self.diagnostics, {
			msg="Missing binder function for node type '" .. ast.type .. "'",
			start=ast.start,
			finish=ast.finish
		})
		return
	end
	binderFunc(self, ast)
end

function Binder:bind_Comment(ast)
end

function Binder:bind_block(ast)
	ast.locals = {}
	for i, stmt in ipairs(ast) do
		self:bind(stmt, ast)
	end
end

function Binder:bind_assign(ast)
	local locals = Binder.getLocals(ast)

	local type_list = ast.type_list or {}
	local expr_list = ast.expr_list or {}
	for i, var in ipairs(ast.var_list) do
		if var.index ~= nil then
			table.insert(self.diagnostics, {
				msg="Binder support for node type '" .. ast.type .. "' missing; non-locals not supported yet.",
				start=ast.start,
				finish=ast.finish
			})
			goto continue
		end
		local typ = type_list[i]
		local val = expr_list[i]
		local name = var.value or (var.expr and var.expr.value)
		if name == nil then
			table.insert(self.diagnostics, {
				msg="Binder support for node type '" .. ast.type .. "' missing; failed to get symbol name from '" .. var.type .. "'.",
				start=ast.start,
				finish=ast.finish
			})
			goto continue
		end
		local symbol = Symbol.new(name)
		symbol:addDeclaration(ast)
		if val ~= nil then
			symbol:addValue(val)
			-- symbol:addType(inferedType)  -- TODO: get infered type
		end
		if typ ~= nil then
			symbol:addType(typ)
		end
		locals[#locals+1] = symbol
		::continue::
	end
end


return Binder
