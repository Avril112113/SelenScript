local Utils = require "SelenScript.utils"
local SourceMap = require "SelenScript.emitter.source_map"


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
	space_before_function = false,
	--- Lua Emitter
	space_after_function = false,
	--- Lua Emitter
	math_always_parenthesised = false,
}
function EmitterConfig.create(from)
	return Utils.merge(EmitterConfig, Utils.deepcopy(from), false)
end


---@class Emitter
---@field args table<string, any> @ Used for creating a copy emitter
---@field defs table<string, fun(self:Emitter, node:ASTNode):any>
---@field parts string[]
---@field config table<string, any>
local Emitter = {
	Emitters = {
		lua = require "SelenScript.emitter.emit_lua",
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
		local start = self.char_position
		table.insert(self.visit_path, name)
		self.defs[name](self.self_proxy, node)
		self.source_map:link(node, start, self.char_position)
		local t = table.remove(self.visit_path)
		assert(t == name, "Removed \"" .. t .. "\" from visit_path but expected \"" .. name .. "\"")
	end
end

function Emitter:add_part(s)
	table.insert(self.parts, s)
	self.char_position = self.char_position + #s
end

function Emitter:new_line(use_indent)
	self:add_part(self.config.newline)
	if use_indent == nil or use_indent then
		self:add_indent()
	end
end

function Emitter:add_indent()
	self:add_part(string.rep(self.config.indent, self.indent_depth))
end

function Emitter:add_space(b)
	if b == nil or b then
		self:add_part(" ")
	end
end

function Emitter:is_space_required_boundary(s)
	if type(s) == "table" and s.type ~= nil then
		---@diagnostic disable-next-line: missing-parameter @ Idk why it's complaining with `unpack` :/
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
	self.char_position = 1
	self.visit_path = {}  -- For debugging errors
	self.indent_depth = 0
	self.source_map = SourceMap.new()
	self.self_proxy = setmetatable({}, {__index=self})
	self:visit(ast)
	self.self_proxy = nil
	local output = table.concat(self.parts)
	return output, self.source_map
end


return Emitter
