---@class SS_Binder
local Binder = {}
Binder.__index = Binder


---@class SS_Symbol
local Symbol = {}
Symbol.__index = Symbol


function Symbol.new(name, flags)
	return setmetatable({
		key = name or error("Missing arg name"),
		flags=flags
	}, Symbol)
end

function Symbol:addDeclaration(ast)
	self.declarations = self.declarations or {}
	ast.symbol = self
	table.insert(self.declarations, ast)
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
 	for i, stmt in ipairs(ast) do
		self:bind(stmt, ast)
	end
end


return Binder
