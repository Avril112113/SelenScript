local Utils = require "SelenScript.utils"
local TransformerErrors = require "SelenScript.transformer.errors"


---@class SelenScript.Transformer
---@field defs table<string, fun(self:SelenScript.Transformer, node:SelenScript.ASTNodes.Node):any>
-- self_proxy fields
---@field errors SelenScript.Error[]
---@field node_parents table<any,SelenScript.ASTNodes.Node>
---@field visit_path string[] # For debugging errors
---@field var_names table<string, number> # A table for the amount of times a SS variable name has been used
---@field ast SelenScript.ASTNodes.Source
local Transformer = {
	VAR_NAME_BASE = "___SS_",
	Transformers = {
		ss_to_lua = require "SelenScript.transformer.transform_ss_to_lua",
	},
}
Transformer.__index = Transformer


---@param target "ss_to_lua"|SelenScript.Transformer # The transformer to use
function Transformer.new(target)
	if type(target) == "string" then
		target = assert(Transformer.Transformers[target], "Unknown transformer \"" .. tostring(target) .. "\"")
	end
	assert(type(target) == "table", "Invalid transformer defs, expected table.")
	local self = setmetatable({
		defs = target,
	}, Transformer)
	return self
end

--- Starting from the far-most nodes working back-to-front, transform each node
---@param node SelenScript.ASTNodes.Node
function Transformer:visit(node)
	local indices_to_remove = {}
	-- The keys of the node can be changed during transformation, doing so can cause undefined behaviour.
	local node_cpy = Utils.shallowcopy(node)
	local dirty_index = false
	for i, v in pairs(node_cpy) do
		self.node_parents[v] = node
		if type(v) == "table" and v.type ~= nil then
			local old_length = #node
			local new_v = self:visit(v)
			if type(i) == "number" then
				-- If length was changed, something was inserted and/or removed and the index for all number based indicies are now incorrect.
				-- TODO: There may be a more efficent way to track these changes. 
				dirty_index = dirty_index or #node ~= old_length
				if dirty_index then
					i = Utils.find_key(node, v, ipairs)
				end
			end
			if new_v == nil then
				if type(i) == "number" then
					table.insert(indices_to_remove, 1, i)
				else
					node[i] = nil
				end
			elseif type(new_v) == "table" and new_v.type ~= nil then
				node[i] = new_v
			end
		end
	end
	for _, i in ipairs(indices_to_remove) do
		table.remove(node, i)
	end
	return self:_visit(node.type, node)
end

--- Used by TransformerDef to reduce code duplication
---@param node SelenScript.ASTNodes.Node
function Transformer:_visit(name, node)
	if type(node) ~= "table" or node.type == nil then
		print_error("_visit(node) didn't get a node but instead \"" .. tostring(node) .. "\"")
		return false
	end
	if self.defs[name] ~= nil then
		table.insert(self.visit_path, name)
		local result = self.defs[name](self, node)
		local t = table.remove(self.visit_path)
		assert(t == name, "Removed \"" .. t .. "\" from visit_path but expected \"" .. name .. "\"")
		return result
	end
	-- If the visit function isn't in the defs, we just skip transforming this node
	return false
end

---@param idOrErrorBase string|SelenScript.ErrorBase
---@param node SelenScript.ASTNodes.Node # The node at which the error appeared
---@param ... string
function Transformer:add_error(idOrErrorBase, node, ...)
	local errorBase = type(idOrErrorBase) == "table" and idOrErrorBase or TransformerErrors[idOrErrorBase]
	if errorBase == nil then
		table.insert(self.errors, errorBase)
	else
		local ln, col = re.calcline(self.ast.source, node.start)
		table.insert(self.errors, errorBase({
			start = node.start,
			finish = node.finish,
			src = self.ast.source
		}, ln, col, ...))
	end
end

--- NOTE: parent nodes will not have been transformed yet!
---@param node SelenScript.ASTNodes.Node # The node to get parent of
function Transformer:get_parent(node)
	return self.node_parents[node]
end

--- Recursively gets the parent of a node until it reaches a specific type of node and returns
---@param node SelenScript.ASTNodes.Node
---@param node_type string|fun(node:SelenScript.ASTNodes.Node):boolean
---@return SelenScript.ASTNodes.Node?, SelenScript.ASTNodes.Node, number # Node matches node_type, child of parent that matched node_type
function Transformer:find_parent_of_type(node, node_type, depth)
	depth = depth or 0
	local parent = self:get_parent(node)
	if parent == nil or type(node_type) == "function" and node_type(parent) or parent.type == node_type then
		return parent, node, depth
	end
	return self:find_parent_of_type(parent, node_type, depth+1)
end

function Transformer:get_var(name)
	local var_name = self.VAR_NAME_BASE .. (name or "") .. "_"
	local n = self.var_names[var_name] or 0
	self.var_names[var_name] = n+1
	return var_name..n
end

--- Creates a proxy of self, with the required limited lifetime variables for transformation.
---@param ast SelenScript.ASTNodes.Source
---@param env table? # Copied into the proxied transformer object.
function Transformer:_create_proxy(ast, env)
	local self_proxy = setmetatable({
		errors = {},
		node_parents = {},
		visit_path = {},  -- For debugging errors
		---@type table<string, number> # A table for the amount of times a SS variable name has been used
		var_names = {},
		ast = ast,
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

--- Runs a transformer though the `ast`, mutating the input parameter.
---@param ast SelenScript.ASTNodes.Source # WARNING: Mutated
---@param env table? # Copied into the proxied transformer object.
function Transformer:transform(ast, env)
	-- NOTE: The `ast` param shouldn't be transformed, as that will replace it, causing potentially untransformed ast nodes.
	local self_proxy = self:_create_proxy(ast, env)
	self_proxy:visit(assert(ast, "Missing `ast` argument."))
	return self_proxy.errors
end


return Transformer
