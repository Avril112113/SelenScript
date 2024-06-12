local Utils = require "SelenScript.utils"
local SourceMap = require "SelenScript.emitter.node_linked_source_map"


-- TODO: Make emitter config seperated for each emitter type
---@class EmitterConfig
local EmitterConfig = {
	--- All Emitters
	newline = "\n",
	indent = "\t",
}
---@param from table
---@param emitter Emitter
local function create_config(from, emitter)
	local config = Utils.deepcopy(from)
	Utils.merge(EmitterConfig, config, false)
	if emitter.DefaultConfig then
		Utils.merge(emitter.DefaultConfig, config, false)
	end
	return config
end


---@class Emitter
---@field DefaultConfig EmitterConfig
---@field args table<string, any> # Used for creating a copy emitter
---@field defs table<string, fun(self:Emitter, node:ASTNode):any>
---@field config table<string, any>
-- self_proxy fields
---@field ast ASTNodeSource
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


---@param target "lua"|Emitter # The emitter to use
---@param config EmitterConfig # Config modifications, any ommited values use defaults
function Emitter.new(target, config)
	config = config or {}
	if type(target) == "string" then
		target = assert(Emitter.Emitters[target], "Unknown emitter \"" .. tostring(target) .. "\"")
	end
	assert(type(target) == "table", "Invalid emitter defs, expected table.")
	local self = setmetatable({
		args = {target, config},
		defs = target,
		parts = nil,
		indent_depth = nil,
		config = create_config(config, target),
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
		table.insert(self.visit_path, name)
		local prev_node = self.last_node
		self.last_node = node
		self.defs[name](self, node)
		self.last_node = prev_node
		local t = table.remove(self.visit_path)
		assert(t == name, "Removed \"" .. t .. "\" from visit_path but expected \"" .. name .. "\"")
	end
end

---@param s string
function Emitter:add_part(s)
	if #s > 0 and not s:match("^[\n \t]+$") then
		self.source_map:link(self.last_node, self.last_node.start, self.char_position)
	end
	table.insert(self.parts, s)
	self.char_position = self.char_position + #s
end

--- Adds a new line, optionally adding indentation.
---@param use_indent boolean? # Defaults `true`, Adds indention to the new line if true.
function Emitter:add_new_line(use_indent)
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

--- Checks if a space is required to separate the last character and `s`
--- Checks for word chars [%w_] and digits followed by [%d.]
---@param s string|ASTNode
function Emitter:is_space_required_boundary(s)
	if type(s) == "table" and s.type ~= nil then
		local emitter = self:_create_proxy(self.ast)
		s = emitter:generate(s)
	end
	local char = s:sub(1, 1)
	return (self:last_is_word() and char:match("[%w_]") ~= nil) or (self:last_is_digit() and char:match("[%d.]") ~= nil)
end

--- Weather or not the last added character (from the last part) is a word character
function Emitter:last_is_word()
	local part = self.parts[#self.parts]
	local char = part:sub(#part)
	return char:match("[%w_]") ~= nil
end

--- Weather or not the last added character (from the last part) is a word character
function Emitter:last_is_digit()
	local part = self.parts[#self.parts]
	local char = part:sub(#part)
	return char:match("%d") ~= nil
end

--- Increases the indent depth
function Emitter:indent()
	self.indent_depth = self.indent_depth + 1
end

--- Decreases the indent depth
function Emitter:unindent()
	self.indent_depth = self.indent_depth - 1
end

--- Creates a proxy of self, with the required limited lifetime variables for emitting.
---@param ast ASTNodeSource
---@param env table? # Copied into the proxied emitter object.
function Emitter:_create_proxy(ast, env)
	local self_proxy = setmetatable({
		ast = ast,
		parts = {},
		char_position = 1,
		indent_depth = 0,
		source_map = SourceMap.new(),
		visit_path = {},
	}, {__index=function(mt, index)
		local value = rawget(self.defs, index)
		if value ~= nil then return value end
		value = self[index]
		if value ~= nil then return value end
	end})
	if env then
		for i, v in pairs(env) do
			self_proxy[i] = v
		end
	end
	return self_proxy
end

--- Run the emitter to generate the output.
---@param ast ASTNodeSource
---@return string, NodeLinkedSourceMap
---@param env table? # Copied into the proxied emitter object.
function Emitter:generate(ast, env)
	local self_proxy = self:_create_proxy(ast, env)
	self_proxy:visit(ast)
	local output = table.concat(self_proxy.parts)
	return output, self_proxy.source_map
end


return Emitter
