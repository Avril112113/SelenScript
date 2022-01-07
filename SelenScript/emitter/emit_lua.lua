local Precedence = require "SelenScript.parser.precedence"


---@type Emitter
local EmitterDefs = {}


function EmitterDefs:chunk(node)
	self:visit(node.block)
end

function EmitterDefs:block(node)
	for i, v in ipairs(node) do
		self:visit(v)
		if i ~= #node then
			self:new_line()
		end
	end
end
function EmitterDefs:_indented_block(node)
	self:indent()
	self:new_line()
	self:visit(node.block)
	self:unindent()
	self:new_line()
end

EmitterDefs["assign"] = function(self, node)
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

EmitterDefs["label"] = function(self, node)
	self:add_part("::")
	self:visit(node.name)
	self:add_part("::")
end

EmitterDefs["goto"] = function(self, node)
	self:add_part("goto")
	self:add_space()
	self:visit(node.name)
end

EmitterDefs["do"] = function(self, node)
	self:add_part("do")
	self:_visit("_indented_block", node)
	self:add_part("end")
end

EmitterDefs["while"] = function(self, node)
	self:add_part("while")
	self:add_space()
	self:visit(node.expr)
	self:add_space()
	self:_visit("do", node)
end

EmitterDefs["repeat"] = function(self, node)
	self:add_part("repeat")
	self:indent()
	self:new_line()
	self:visit(node.block)
	self:unindent()
	self:new_line()
	self:add_part("until")
	self:add_space()
	self:visit(node.expr)
end

EmitterDefs["if"] = function(self, node)
	self:add_part(node.type)  -- "if" or "elseif" or "else"
	if node.type ~= "else" then
		self:add_space()
		self:visit(node.condition)
		self:add_space()
		self:add_part("then")
	end
	self:_visit("_indented_block", node)
	if node["else"] ~= nil then
		self:visit(node["else"])
	end
	if node.type == "if" then
		self:add_part("end")
	end
end
EmitterDefs["elseif"] = EmitterDefs["if"]
EmitterDefs["else"] = EmitterDefs["if"]

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
	self:_visit("do", node)
end

EmitterDefs["foriter"] = function(self, node)
	self:add_part("for")
	self:add_space()
	self:visit(node.namelist)
	self:add_space()
	self:add_part("in")
	self:add_space()
	self:visit(node.values)
	self:add_space()
	self:_visit("do", node)
end

EmitterDefs["functiondef"] = function(self, node)
	if node.scope == "local" then
		self:add_part(node.scope)
		self:add_space()
	elseif node.scope ~= nil then
		print_warn("Invalid scope \"" .. node.scope .. "\"")
	end
	self:add_part("function")
	self:add_space()
	self:visit(node.name)
	self:visit(node.funcbody)
	if self.config.space_after_function then
		self:new_line(false)
	end
end

EmitterDefs["break"] = function(self, node)
	self:add_part("break")
end

EmitterDefs["return"] = function(self, node)
	self:add_part("return")
	if #node.values > 0 then
		self:add_space()
		self:visit(node.values)
	end
end

function EmitterDefs:index(node)
	if node.how ~= nil then
		self:add_part(node.how)
	end
	self:visit(node.expr)
	if node.how == "[" then
		self:add_part("]")
	end
	if node.index ~= nil then
		self:visit(node.index)
	end
end

function EmitterDefs:call(node)
	self:add_part("(")
	self:visit(node.args)
	self:add_part(")")
end

function EmitterDefs:funcbody(node)
	self:add_part("(")
	self:visit(node.args)
	self:add_part(")")
	self:indent()
	self:new_line()
	self:visit(node.block)
	self:unindent()
	self:new_line()
	self:add_part("end")
end

function EmitterDefs:name(node)
	self:add_part(node.name)
end

function EmitterDefs:attributename(node)
	self:visit(node.name)
	if node.attribute ~= nil then
		self:add_part("<")
		self:visit(node.attribute)
		self:add_part(">")
	end
end

function EmitterDefs:_list(node)
	local compact = self.config[node.type.."_compact"]
	if compact == nil then compact = true end
	if not compact then
		self:indent()
	end
	for i,v in ipairs(node) do
		if not compact then
			self:new_line()
		end
		self:visit(v)
		if i ~= #node or self.config[node.type.."_trail_comma"] then
			self:add_part(",")
			if i ~= #node and compact then
				self:add_space()
			end
		end
	end
	if not compact then
		self:unindent()
		self:new_line()
	end
end
EmitterDefs.expressionlist = EmitterDefs._list
EmitterDefs.namelist = EmitterDefs._list
EmitterDefs.parlist = EmitterDefs._list
EmitterDefs.fieldlist = EmitterDefs._list
EmitterDefs.varlist = EmitterDefs._list
EmitterDefs.attributenamelist = EmitterDefs._list

EmitterDefs["nil"] = function(self, node)
	self:add_part("nil")
end

function EmitterDefs:var_args(node)
	self:add_part("...")
end

function EmitterDefs:numeral(node)
	self:add_part(node.value)
end

function EmitterDefs:string(node)
	self:add_part(node.value)
end

function EmitterDefs:boolean(node)
	self:add_part(node.value)
end

EmitterDefs["function"] = function(self, node)
	self:add_part("function")
	self:visit(node.funcbody)
end

function EmitterDefs:table(node)
	self:add_part("{")
	self:visit(node.fields)
	self:add_part("}")
end
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
	end
	if brackets then
		self:add_part("(")
	end
	if node.lhs ~= nil then
		self:visit(node.lhs)
		self:add_space(self:is_space_required_boundary(node.op))
	end
	self:add_part(node.op)
	self:add_space(self:is_space_required_boundary(node.rhs))
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
