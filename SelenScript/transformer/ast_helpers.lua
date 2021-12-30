--- This file is a collection on functions to aid in transforming
--- NOTE: If the AST changes, these function might need updating
local ASTHelpers = {}


local ASTNodes = {}
ASTHelpers.Nodes = ASTNodes

---@param node ASTNode @ Used for source position info
---@param name string
---@return ASTNode
function ASTNodes.name(node, name)
	return {
		type = "name",
		start = node.start,
		name = name,
		finish = node.finish
	}
end

---@param node ASTNode @ Used for source position info
---@param name string|ASTNode
---@return ASTNode
function ASTNodes.label(node, name)
	return {
		type = "label",
		start = node.start,
		name = type(name) == "string" and ASTNodes.name(node, name) or name,
		finish = node.finish
	}
end

---@param node ASTNode @ Used for source position info
---@param name string|ASTNode
---@return ASTNode
ASTNodes["goto"] = function(node, name)
	return {
		type = "goto",
		start = node.start,
		name = type(name) == "string" and ASTNodes.name(node, name) or name,
		finish = node.finish
	}
end


return ASTHelpers
