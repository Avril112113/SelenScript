local Grammar = require "SelenScript.parser.grammar"
local Parser = require "SelenScript.parser.parser"
local TransformerErrors = require "SelenScript.transformer.errors"


---@class Transformer
---@field defs table<string, fun(self:Transformer, node:ASTNode):any>
local Transformer = {
	VAR_NAME_BASE = "___SS_",
	Transformers = {
		ss_to_lua = require "SelenScript.transformer.transform_ss_to_lua"
	},
}
Transformer.__index = Transformer


---@param target string @ The emitter to use
function Transformer.new(target)
	local self = setmetatable({
		defs = assert(Transformer.Transformers[target], "Unknown transformer \"" .. tostring(target) .. "\""),
	}, Transformer)
	return self
end

--- Starting from the far-most nodes working back-to-front, transform each node
---@param node ASTNode
function Transformer:visit(node)
	local indices_to_remove = {}
	for i, v in pairs(node) do
		self.node_parents[v] = node
		if type(v) == "table" and v.type ~= nil then
			local new_v = self:visit(v)
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
---@param node ASTNode
function Transformer:_visit(name, node)
	if type(node) ~= "table" or node.type == nil then
		print_error("_visit(node) didn't get a node but instead \"" .. tostring(node) .. "\"")
		return false
	end
	if self.defs[name] ~= nil then
		table.insert(self.visit_path, name)
		local result = self.defs[name](self.self_proxy, node)
		local t = table.remove(self.visit_path)
		assert(t == name, "Removed \"" .. t .. "\" from visit_path but expected \"" .. name .. "\"")
		return result
	end
	-- If the visit function isn't in the defs, we just skip transforming this node
	return false
end

---@param idOrErrorBase string|ErrorBase
---@param node ASTNode @ The node at which the error appeared
---@param ... string
function Transformer:add_error(idOrErrorBase, node, ...)
	local errorBase = type(idOrErrorBase) == "table" and idOrErrorBase or TransformerErrors[idOrErrorBase]
	if errorBase == nil then
		table.insert(self.errors, errorBase)
	else
		local ln, col = re.calcline(self.source, node.start)
		table.insert(self.errors, errorBase({start=node.start,finish=node.finish,src=self.source}, ln, col, ...))
	end
end

--- NOTE: parent nodes will not have been transformed yet!
---@param node ASTNode @ The node to get parent of
function Transformer:get_parent(node)
	return self.node_parents[node]
end

--- Recursively gets the parent of a node until it reaches a specific type of node and returns
---@param node ASTNode
---@param node_type string|fun(node:ASTNode):boolean
---@return ASTNode?, ASTNode @ Node matches node_type, child of parent that matched node_type
function Transformer:find_parent_of_type(node, node_type, depth)
	depth = depth or 0
	local parent = self:get_parent(node)
	if parent == nil or type(node_type) == "function" and node_type(parent) or parent.type == node_type then
		return parent, node
	end
	return self:find_parent_of_type(parent, node_type, depth+1)
end

function Transformer:get_var(name)
	local var_name = self.VAR_NAME_BASE .. (name or "") .. "_"
	local n = self.var_names[var_name] or 0
	self.var_names[var_name] = n+1
	return var_name..n
end

--- Runs a transformer thought an AST in-place
--- NOTE: make sure that the base node being transformed does not get replaced (`ast` param)
---@param ast ASTNode @ WARNING: Modified
---@param source string @ Required for error message position calculations
function Transformer:transform(ast, source)
	self.source = assert(source, "Missing source argument.")
	self.errors = {}
	self.node_parents = {}
	self.visit_path = {}  -- For debugging errors
	---@type table<string, number> @ A table for the amount of times a SS variable name has been used
	self.var_names = {}
	self.self_proxy = setmetatable({}, {__index=self})
	self:visit(assert(ast, "Missing `ast` argument."))
	self.self_proxy = nil
	return self.errors
end


return Transformer
