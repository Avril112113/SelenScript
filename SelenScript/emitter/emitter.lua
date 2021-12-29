local Utils = require "SelenScript.utils"


---@class EmitterConfig
local EmitterConfig = {
	--- All Emitters
	newline = "\n",
	--- All Emitters
	indent = "\t",

	--- Lua Emitter
	fieldlist_trail_comma = true,
	--- Lua Emitter
	fieldlist_compact = false,
	--- Lua Emitter
	field_assign_space = true,
	--- Lua Emitter
	space_after_function = true,
	--- Lua Emitter
	math_always_parenthesised = false,
}
function EmitterConfig.create(from)
	return Utils.merge(EmitterConfig, Utils.deepcopy(from), false)
end


---@class Emitter
---@field args table<string, any> @ Used for creating a copy emitter
---@field defs table<string, fun(node:ASTNode):any>
---@field parts string[]
---@field config table<string, string>
local Emitter = {
	Emitters = {
		lua = require "SelenScript.emitter.emit_lua"
	},
}
Emitter.__index = Emitter


---@param target string @ The emitter to use
---@param config EmitterConfig @ Config modifications, any un-suppied values use defaults
function Emitter.new(target, config)
	config = config or {}
	local self = setmetatable({
		args={target, config},
		defs = assert(Emitter.Emitters[target], "Unknown emitter output target \"" .. tostring(target) .. "\""),
		parts = nil,
		indent_depth = nil,
		config = EmitterConfig.create(config)
	}, Emitter)
	return self
end

---@param node ASTNode
function Emitter:visit(node)
	return self:_visit(node.type, node)
end

--- Used by EmitterDef to reduce code duplication
---@param node ASTNode
function Emitter:_visit(name, node)
	if type(node) ~= "table" or node.type == nil then
		print_error("_visit(node) didn't get a node but instead \"" .. tostring(node) .. "\"")
		return
	end
	if self.defs[name] == nil then
		print_warn("Missing emitter method for node type \"" .. name .. "\"")
	else
		table.insert(self.visit_path, name)
		self.defs[name](self.self_proxy, node)
		local t = table.remove(self.visit_path)
		assert(t == name, "Removed \"" .. t .. "\" from visit_path but expected \"" .. name .. "\"")
	end
end

function Emitter:add_part(s)
	table.insert(self.parts, s)
end

function Emitter:new_line(use_indent)
	table.insert(self.parts, self.config.newline)
	if use_indent == nil or use_indent then
		self:add_indent()
	end
end

function Emitter:add_indent()
	table.insert(self.parts, string.rep(self.config.indent, self.indent_depth))
end

function Emitter:add_space(b)
	if b == nil or b then
		table.insert(self.parts, " ")
	end
end

function Emitter:is_space_required_boundary(s)
	if type(s) == "table" and s.type ~= nil then
		local emitter = Emitter.new(unpack(self.args))
		s = emitter:generate(s)
	end
	local char = s:sub(1, 1)
	return self:last_is_word() and char:gmatch("%w")() == char
end

function Emitter:last_is_word()
	local part = self.parts[#self.parts]
	local char = part:sub(#part)
	return char:gmatch("%w")() == char
end

function Emitter:indent()
	self.indent_depth = self.indent_depth + 1
end

function Emitter:unindent()
	self.indent_depth = self.indent_depth - 1
end

function Emitter:generate(ast)
	self.parts = {}
	self.visit_path = {}  -- For debugging errors
	self.indent_depth = 0
	self.self_proxy = setmetatable({}, {__index=self})
	self:visit(ast)
	self.self_proxy = nil
	return table.concat(self.parts)
end


return Emitter
