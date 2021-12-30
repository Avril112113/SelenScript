--- This file is a collection on functions to aid in transforming
--- NOTE: If the AST changes, these function might need updating
local ASTHelpers = {}


local ASTNodes = {}
ASTHelpers.Nodes = ASTNodes

---@param node ASTNode @ Used for source position info
---@param ... ASTNode
---@return ASTNode
function ASTNodes.block(node, ...)
	return {
		type = "block",
		start = node.start,
		finish = node.finish,
		...
	}
end

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
---@param how string
---@param expr ASTNode
---@param index ASTNode|nil
---@return ASTNode
function ASTNodes.index(node, how, expr, index)
	return {
		type = "index",
		start = node.start,
		how = how,
		expr = expr,
		index = index,
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

---@param node ASTNode @ Used for source position info
---@param condition ASTNode
---@param block ASTNode
---@param _else ASTNode|nil
---@return ASTNode
ASTNodes["if"] = function(node, condition, block, _else)
	return {
		type = "if",
		start = node.start,
		condition = condition,
		block = block,
		["else"] = _else,
		finish = node.finish
	}
end

---@param node ASTNode @ Used for source position info
---@param condition ASTNode
---@param block ASTNode
---@param _else ASTNode|nil
---@return ASTNode
ASTNodes["elseif"] = function(node, condition, block, _else)
	return {
		type = "elseif",
		start = node.start,
		condition = condition,
		block = block,
		["else"] = _else,
		finish = node.finish
	}
end

---@param node ASTNode @ Used for source position info
---@param block ASTNode
---@return ASTNode
ASTNodes["else"] = function(node, block)
	return {
		type = "else",
		start = node.start,
		block = block,
		finish = node.finish
	}
end

---@param node ASTNode @ Used for source position info
---@param names ASTNode @ `varlist` or `attributenamelist`
---@param values ASTNode|nil @ `expressionlist`
---@return ASTNode
ASTNodes["assign"] = function(node, scope, names, values)
	return {
		type = "assign",
		start = node.start,
		scope = scope,
		names = names,
		values = values or ASTNodes.expressionlist(node),
		finish = node.finish
	}
end

---@param node ASTNode @ Used for source position info
---@param ... ASTNode
---@return ASTNode
ASTNodes["expressionlist"] = function(node, ...)
	return {
		type = "expressionlist",
		start = node.start,
		finish = node.finish,
		...
	}
end

---@param node ASTNode @ Used for source position info
---@param ... ASTNode
---@return ASTNode
ASTNodes["varlist"] = function(node, ...)
	return {
		type = "varlist",
		start = node.start,
		finish = node.finish,
		...
	}
end

---@param node ASTNode @ Used for source position info
---@param ... ASTNode
---@return ASTNode
ASTNodes["attributenamelist"] = function(node, ...)
	return {
		type = "attributenamelist",
		start = node.start,
		finish = node.finish,
		...
	}
end

---@param node ASTNode @ Used for source position info
---@param name string
---@param attribute string|nil
---@return ASTNode
ASTNodes["attributename"] = function(node, name, attribute)
	return {
		type = "attributename",
		start = node.start,
		name = ASTNodes.name(node, name),
		attribute = attribute and ASTNodes.name(node, attribute) or nil,
		finish = node.finish
	}
end


return ASTHelpers
