local Utils = require "SelenScript.utils"
local SourceMap = require "SelenScript.emitter.node_linked_source_map"


-- TODO: Make emitter config seperated for each emitter type
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
---@field args table<string, any> # Used for creating a copy emitter
---@field defs table<string, fun(self:Emitter, node:ASTNode):any>
---@field config table<string, any>
-- self_proxy fields
---@field parts string[]
---@field char_position integer
---@field indent_depth integer
---@field source_map NodeLinkedSourceMap
---@field visit_path string[] # For debugging errors
local Emitter = {
	Emitters = {
		lua = require "SelenScript.emitter.emit_lua",
	},
}
Emitter.__index = Emitter


---@param target string # The emitter to use
---@param config EmitterConfig # Config modifications, any un-supplied values use defaults
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
	return self:visit_type(node.type, node)
end

--- Used by EmitterDef's to reduce code duplication
---@param name string
---@param node ASTNode
function Emitter:visit_type(name, node)
	if type(node) ~= "table" or node.type == nil then
		print_error("_visit(node) didn't get a node but instead \"" .. tostring(node) .. "\"")
		return
	end
	if self.defs[name] == nil then
		print_warn("Missing emitter method for node type \"" .. name .. "\"")
	else
		local start = self.char_position
		table.insert(self.visit_path, name)
		self.defs[name](self, node)
		self.source_map:link(node, start, self.char_position)
		local t = table.remove(self.visit_path)
		assert(t == name, "Removed \"" .. t .. "\" from visit_path but expected \"" .. name .. "\"")
	end
end

function Emitter:add_part(s)
	table.insert(self.parts, s)
	self.char_position = self.char_position + #s
end

--- Adds a new line, optionally adding indentation.
---@param use_indent boolean? # Defaults `true`, Adds indention to the new line if true.
function Emitter:new_line(use_indent)
	self:add_part(self.config.newline)
	if use_indent == nil or use_indent then
		self:add_indent()
	end
end

--- Adds current indentation
function Emitter:add_indent()
	self:add_part(string.rep(self.config.indent, self.indent_depth))
end

--- Adds a space
---@param b boolean? # Defaults `true`, weather or not to actually add a space, or `false` to skip.
function Emitter:add_space(b)
	if b == nil or b then
		self:add_part(" ")
	end
end

function Emitter:is_space_required_boundary(s)
	if type(s) == "table" and s.type ~= nil then
		---@diagnostic disable-next-line: missing-parameter # Idk why it's complaining with `unpack` :/
		local emitter = Emitter.new(unpack(self.args))
		s = emitter:generate(s)
	end
	local char = s:sub(1, 1)
	return self:last_is_word() and char:gmatch("%w")() == char
end

--- Weather or not the last added character (from the last part) is a word character
function Emitter:last_is_word()
	local part = self.parts[#self.parts]
	local char = part:sub(#part)
	return char:gmatch("%w")() == char
end

--- Increases the indent depth
function Emitter:indent()
	self.indent_depth = self.indent_depth + 1
end

--- Decreases the indent depth
function Emitter:unindent()
	self.indent_depth = self.indent_depth - 1
end

---@param ast ASTNode
---@return string, NodeLinkedSourceMap
function Emitter:generate(ast)
	local self_proxy = setmetatable({
		parts = {},
		char_position = 1,
		indent_depth = 0,
		source_map = SourceMap.new(),
		visit_path = {},
		ast = ast,
	}, {__index=self})
	self_proxy:visit(ast)
	local output = table.concat(self_proxy.parts)
	return output, self_proxy.source_map
end


return Emitter
