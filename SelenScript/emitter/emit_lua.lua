local Utils = require "SelenScript.utils"
local Precedence = require "SelenScript.parser.precedence"


---@class LuaEmitter : Emitter
---@field get_source_path (fun(src_path:string):string)?
---@field _sources ASTNodeSource[]
local EmitterDefs = {}
---@class LuaEmitterConfig : EmitterConfig
EmitterDefs.DefaultConfig = {
	fieldlist_trail_comma = true,
	fieldlist_compact = false,
	field_assign_space = true,
	space_before_function = false,
	space_after_function = false,
	space_between_math = true,
	math_always_parenthesised = false,
	luacats_source = true,  -- https://github.com/sumneko/lua-language-server/wiki/Annotations#source
}


EmitterDefs._BRACE_REQUIRED_TYPES = {
	["string"]=true,
	["numeral"]=true,
	["table"]=true,
	["function"]=true,
	["var_args"]=true,
}
for op, data in pairs(Precedence.binaryOpData) do
	EmitterDefs._BRACE_REQUIRED_TYPES[data[2]] = true
end
for op, data in pairs(Precedence.unaryOpData) do
	EmitterDefs._BRACE_REQUIRED_TYPES[data[2]] = true
end


---@param node ASTNode
function EmitterDefs:add_luacats_source_comment(node)
	if self._sources == nil then
		return
	end
	local source_node = self._sources[#self._sources]
	if source_node ~= nil and source_node.file then
		local file = source_node.file:gsub("\\", "/"):gsub("^./", "")
		if self.get_source_path then
			file = self.get_source_path(file) or file
		end
		local ln, col = source_node:calcline(node.start)
		self:add_part(("---@source %s:%i:%i"):format(file, ln, col-1))
		self:add_new_line()
	end
end


---@param node ASTNodeSource
function EmitterDefs:source(node)
	self._sources = self._sources or {}
	table.insert(self._sources, #self._sources+1, node)
	self:visit(node.block)
	table.remove(self._sources, #self._sources)
end

---@param node ASTNode # TODO: Node types
function EmitterDefs:chunk(node)
	self:visit(node.block)
end

---@param node ASTNode # TODO: Node types
function EmitterDefs:block(node)
	for i, v in ipairs(node) do
		self:visit(v)
		if i ~= #node then
			self:add_new_line()
		end
	end
end
---@param node ASTNode # TODO: Node types
function EmitterDefs:_indented_block(node)
	self:indent()
	self:add_new_line()
	self:visit(node.block)
	self:unindent()
	self:add_new_line()
end

---@param node ASTNode # TODO: Node types
function EmitterDefs:LineComment(node)
	self:string(node)
end

---@param node ASTNode # TODO: Node types
function EmitterDefs:LongComment(node)
	self:string(node)
end

---@param self LuaEmitter
---@param node ASTNode # TODO: Node types
EmitterDefs["assign"] = function(self, node)
	if self.config.luacats_source then
		self:add_luacats_source_comment(node)
	end
	if node.scope == "local" then
		self:add_part(node.scope)
		self:add_space()
	elseif node.scope ~= nil then
		print_warn("Invalid scope \"" .. node.scope .. "\"")
	end
	self:visit(node.names)
	if #node.values > 0 then
		self:add_space()
		self:add_part("=")
		self:add_space()
		self:visit(node.values)
	end
end

---@param self LuaEmitter
---@param node ASTNode # TODO: Node types
EmitterDefs["label"] = function(self, node)
	self:add_part("::")
	self:visit(node.name)
	self:add_part("::")
end

---@param self LuaEmitter
---@param node ASTNode # TODO: Node types
EmitterDefs["goto"] = function(self, node)
	self:add_part("goto")
	self:add_space()
	self:visit(node.name)
end

---@param self LuaEmitter
---@param node ASTNode # TODO: Node types
EmitterDefs["do"] = function(self, node)
	self:add_part("do")
	self:visit_type("_indented_block", node)
	self:add_part("end")
end

---@param self LuaEmitter
---@param node ASTNode # TODO: Node types
EmitterDefs["while"] = function(self, node)
	self:add_part("while")
	self:add_space()
	self:visit(node.expr)
	self:add_space()
	self:visit_type("do", node)
end

---@param self LuaEmitter
---@param node ASTNode # TODO: Node types
EmitterDefs["repeat"] = function(self, node)
	self:add_part("repeat")
	self:indent()
	self:add_new_line()
	self:visit(node.block)
	self:unindent()
	self:add_new_line()
	self:add_part("until")
	self:add_space()
	self:visit(node.expr)
end

---@param self LuaEmitter
---@param node ASTNode # TODO: Node types
EmitterDefs["if"] = function(self, node)
	self:add_part(node.type)  -- "if" or "elseif" or "else"
	if node.type ~= "else" then
		self:add_space()
		self:visit(node.condition)
		self:add_space()
		self:add_part("then")
	end
	self:visit_type("_indented_block", node)
	if node["else"] ~= nil then
		self:visit(node["else"])
	end
	if node.type == "if" then
		self:add_part("end")
	end
end
EmitterDefs["elseif"] = EmitterDefs["if"]
EmitterDefs["else"] = EmitterDefs["if"]

---@param self LuaEmitter
---@param node ASTNode # TODO: Node types
EmitterDefs["forrange"] = function(self, node)
	self:add_part("for")
	self:add_space()
	self:visit(node.name)
	self:add_part("=")
	self:visit(node.value_start)
	self:add_part(",")
	self:visit(node.value_finish)
	if node.increment ~= nil then
		self:add_part(",")
		self:visit(node.increment)
	end
	self:add_space()
	self:visit_type("do", node)
end

---@param self LuaEmitter
---@param node ASTNode # TODO: Node types
EmitterDefs["foriter"] = function(self, node)
	self:add_part("for")
	self:add_space()
	self:visit(node.namelist)
	self:add_space()
	self:add_part("in")
	self:add_space()
	self:visit(node.values)
	self:add_space()
	self:visit_type("do", node)
end

---@param self LuaEmitter
---@param node ASTNode # TODO: Node types
EmitterDefs["functiondef"] = function(self, node)
	if self.config.luacats_source then
		self:add_luacats_source_comment(node)
	end
	if node.scope == "local" then
		self:add_part(node.scope)
		self:add_space()
	elseif node.scope ~= nil then
		print_warn("Invalid scope \"" .. node.scope .. "\"")
	end
	if self.config.space_before_function then
		self:add_new_line(false)
	end
	self:add_part("function")
	self:add_space()
	self:visit(node.name)
	self:visit(node.funcbody)
	if self.config.space_after_function then
		self:add_new_line(false)
	end
end

---@param self LuaEmitter
---@param node ASTNode # TODO: Node types
EmitterDefs["break"] = function(self, node)
	self:add_part("break")
end

---@param self LuaEmitter
---@param node ASTNode # TODO: Node types
EmitterDefs["return"] = function(self, node)
	self:add_part("return")
	if #node.values > 0 then
		self:add_space()
		self:visit(node.values)
	end
end

---@param node ASTNode # TODO: Node types
local function is_indexing_multi_value(node)
	return (node.expr and node.expr.type == "call" and not node.index) or (node.index and is_indexing_multi_value(node.index))
end
---@param node ASTNode # TODO: Node types
function EmitterDefs:index(node)
	local braces = node.how == nil and node.braces ~= nil and is_indexing_multi_value(node.expr)
	if braces and node.braces == "(" then
		self:add_part("(")
	end
	if node.how ~= nil then
		self:add_part(node.how)
	end
	local needs_parens = node.index ~= nil and EmitterDefs._BRACE_REQUIRED_TYPES[node.expr.type]
	if needs_parens then
		self:add_part("(")
	end
	self:visit(node.expr)
	if needs_parens then
		self:add_part(")")
	end
	if node.how == "[" then
		self:add_part("]")
	end
	if node.index ~= nil then
		self:visit(node.index)
	end
	if braces and node.braces == "(" then
		self:add_part(")")
	end
end

---@param node ASTNode # TODO: Node types
function EmitterDefs:call(node)
	self:add_part("(")
	self:visit(node.args)
	self:add_part(")")
end

---@param node ASTNode # TODO: Node types
function EmitterDefs:funcbody(node)
	self:add_part("(")
	self:visit(node.args)
	self:add_part(")")
	self:indent()
	self:add_new_line()
	self:visit(node.block)
	self:unindent()
	self:add_new_line()
	self:add_part("end")
end

---@param node ASTNode # TODO: Node types
function EmitterDefs:name(node)
	self:add_part(node.name)
end

---@param node ASTNode # TODO: Node types
function EmitterDefs:attributename(node)
	self:visit(node.name)
	if node.attribute ~= nil then
		self:add_part("<")
		self:visit(node.attribute)
		self:add_part(">")
	end
end

---@param node ASTNode # TODO: Node types
function EmitterDefs:_list(node)
	local compact = self.config[node.type.."_compact"]
	if compact == nil then compact = true end
	local hasElements = #node > 0
	if not compact and hasElements then
		self:indent()
	end
	for i,v in ipairs(node) do
		if not compact then
			self:add_new_line()
		end
		self:visit(v)
		if i ~= #node or self.config[node.type.."_trail_comma"] then
			self:add_part(",")
			if i ~= #node and compact then
				self:add_space()
			end
		end
	end
	if not compact and hasElements then
		self:unindent()
		self:add_new_line()
	end
end
EmitterDefs.expressionlist = EmitterDefs._list
EmitterDefs.namelist = EmitterDefs._list
EmitterDefs.parlist = EmitterDefs._list
EmitterDefs.fieldlist = EmitterDefs._list
EmitterDefs.varlist = EmitterDefs._list
EmitterDefs.attributenamelist = EmitterDefs._list

---@param self LuaEmitter
---@param node ASTNode # TODO: Node types
EmitterDefs["nil"] = function(self, node)
	self:add_part("nil")
end

---@param node ASTNode # TODO: Node types
function EmitterDefs:var_args(node)
	self:add_part("...")
end

---@param node ASTNode # TODO: Node types
function EmitterDefs:numeral(node)
	self:add_part(node.value)
end

---@param node ASTNode # TODO: Node types
function EmitterDefs:string(node)
	-- Temp workaround for being unable to capture `=` in prefix field.
	if node.prefix == "[[" and node.suffix then
		self:add_part(node.suffix:gsub("%]", "["))
	else
		self:add_part(node.prefix)
	end
	self:add_part(node.value)
	if node.suffix then
		self:add_part(node.suffix)
	end
end

---@param node ASTNode # TODO: Node types
function EmitterDefs:boolean(node)
	self:add_part(node.value)
end

---@param self LuaEmitter
---@param node ASTNode # TODO: Node types
EmitterDefs["function"] = function(self, node)
	self:add_part("function")
	self:visit(node.funcbody)
end

---@param node ASTNode # TODO: Node types
function EmitterDefs:table(node)
	self:add_part("{")
	self:visit(node.fields)
	self:add_part("}")
end
---@param node ASTNode # TODO: Node types
function EmitterDefs:field(node)
	if node.key ~= nil and node.key.type == "name" then
		self:visit(node.key)
	elseif node.key ~= nil then
		self:add_part("[")
		self:visit(node.key)
		self:add_part("]")
	end
	if node.key ~= nil then
		self:add_space(self.config.field_assign_space)
		self:add_part("=")
		self:add_space(self.config.field_assign_space)
	end
	self:visit(node.value)
end

---@param node ASTNode # TODO: Node types
function EmitterDefs:_math(node)
	-- TODO: check if this can cause extra brackets in nested math sections (seperated sections of math)
	local old_precedence = self._math_precedence
	local brackets = self.config.math_always_parenthesised and old_precedence ~= nil
	if node.lhs ~= nil then
		local opData = assert(Precedence.binaryOpData[node.op])
		self._math_precedence = opData[1]
		if node.lhs ~= nil and not self.config.math_always_parenthesised then
			brackets = (old_precedence or -math.huge) > self._math_precedence
		end
	elseif node.rhs ~= nil then
		local opData = assert(Precedence.unaryOpData[node.op])
		self._math_precedence = opData[1]
	end
	if brackets then
		self:add_part("(")
	end
	if node.lhs ~= nil then
		self:visit(node.lhs)
		self:add_space(self.config.space_between_math or self:is_space_required_boundary(node.op))
	end
	self:add_part(node.op)
	self:add_space((node.lhs ~= nil and self.config.space_between_math) or self:is_space_required_boundary(node.rhs))
	self:visit(node.rhs)
	if brackets then
		self:add_part(")")
	end
	self._math_precedence = old_precedence
end

for _, opType in pairs(Precedence.types) do
	EmitterDefs[opType] = EmitterDefs._math
end


return EmitterDefs
