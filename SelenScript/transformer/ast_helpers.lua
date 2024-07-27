local Utils = require "SelenScript.utils"


--- This file is a collection on functions to aid in transforming
--- NOTE: If the AST changes, these function might need updating
local ASTHelpers = {}


local ASTNodes = {}
ASTHelpers.Nodes = ASTNodes

---@param node SelenScript.ASTNode # Used for source position info
---@param prefix string?
---@param value string
---@return SelenScript.ASTNode
function ASTNodes.LineComment(node, prefix, value)
	return {
		type = "LineComment",
		start = node.start,
		prefix = prefix or "--",
		value = value,
		finish = node.finish,
	}
end

---@param node SelenScript.ASTNode # Used for source position info
---@param prefix string?
---@param value string
---@return SelenScript.ASTNode
function ASTNodes.LongComment(node, prefix, value, suffix)
	return {
		type = "LongComment",
		start = node.start,
		prefix = prefix or "[[",
		suffix = suffix or "]]",
		value = value,
		finish = node.finish,
	}
end

---@param node SelenScript.ASTNode # Used for source position info
---@param ... SelenScript.ASTNode
---@return SelenScript.ASTNode
function ASTNodes.block(node, ...)
	return {
		type = "block",
		start = node.start,
		finish = node.finish,
		...
	}
end

---@param node SelenScript.ASTNode # Used for source position info
---@param name string
---@return SelenScript.ASTNode
function ASTNodes.name(node, name)
	return {
		type = "name",
		start = node.start,
		name = name,
		finish = node.finish
	}
end

---@param node SelenScript.ASTNode # Used for source position info
---@param value string
---@return SelenScript.ASTNode
function ASTNodes.numeral(node, value)
	return {
		type = "numeral",
		start = node.start,
		value = value,
		finish = node.finish
	}
end

---@param node SelenScript.ASTNode # Used for source position info
---@param value string
---@param prefix string?
---@param suffix string?
---@return SelenScript.ASTNode
function ASTNodes.string(node, value, prefix, suffix)
	-- `prefix` might be a number if `value:gsub()` for example was used. 
	if type(prefix) ~= "string" then
		prefix = "\""
		if value:find(prefix) then
			prefix = "'"
		end
		if value:find(prefix) then
			prefix = "[["
		end
		local i = 1
		while value:find(Utils.escape_pattern(prefix)) do
			prefix = "[" .. string.rep("=", i) .. "["
			i = i + 1
		end
	end
	if suffix == nil then
		if prefix:match("%[=*%[") then
			suffix = prefix:gsub("%[", "%]")
		else
			suffix = prefix
		end
	end
	return {
		type = "string",
		start = node.start,
		prefix = prefix,
		value = value,
		suffix = suffix,
		finish = node.finish
	}
end

---@param node SelenScript.ASTNode # Used for source position info
---@param ... SelenScript.ASTNode
---@return SelenScript.ASTNode
function ASTNodes.namelist(node, ...)
	return {
		type = "namelist",
		start = node.start,
		finish = node.finish,
		...
	}
end

---@param node SelenScript.ASTNode # Used for source position info
---@param how string?
---@param expr SelenScript.ASTNode
---@param index SelenScript.ASTNode?
---@param braces string?
---@return SelenScript.ASTNode
function ASTNodes.index(node, how, expr, index, braces)
	return {
		type = "index",
		start = node.start,
		how = how,
		expr = expr,
		index = index,
		braces = braces,
		finish = node.finish
	}
end

---@param node SelenScript.ASTNode # Used for source position info
---@param args any[]|table|string
---@param self nil|boolean
---@return SelenScript.ASTNode
function ASTNodes.call(node, args, self)
	return {
		type = "call",
		start = node.start,
		args = args,
		self = self and "true",
		finish = node.finish
	}
end

function ASTNodes.var_args(node)
	return {
		type = "var_args",
		start = node.start,
		value = "...",
		finish = node.finish,
	}
end

---@param node SelenScript.ASTNode # Used for source position info
---@param name string|SelenScript.ASTNode
---@return SelenScript.ASTNode
function ASTNodes.label(node, name)
	return {
		type = "label",
		start = node.start,
		name = type(name) == "string" and ASTNodes.name(node, name) or name,
		finish = node.finish
	}
end

---@param node SelenScript.ASTNode # Used for source position info
---@param name string|SelenScript.ASTNode
---@return SelenScript.ASTNode
ASTNodes["goto"] = function(node, name)
	return {
		type = "goto",
		start = node.start,
		name = type(name) == "string" and ASTNodes.name(node, name) or name,
		finish = node.finish
	}
end

---@param node SelenScript.ASTNode # Used for source position info
---@param condition SelenScript.ASTNode
---@param block SelenScript.ASTNode
---@param _else SelenScript.ASTNode?
---@return SelenScript.ASTNode
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

---@param node SelenScript.ASTNode # Used for source position info
---@param condition SelenScript.ASTNode
---@param block SelenScript.ASTNode
---@param _else SelenScript.ASTNode?
---@return SelenScript.ASTNode
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

---@param node SelenScript.ASTNode # Used for source position info
---@param block SelenScript.ASTNode
---@return SelenScript.ASTNode
ASTNodes["else"] = function(node, block)
	return {
		type = "else",
		start = node.start,
		block = block,
		finish = node.finish
	}
end

---@param node SelenScript.ASTNode # Used for source position info
---@param scope "local"?
---@param names SelenScript.ASTNode # `varlist` or `attributenamelist`
---@param values SelenScript.ASTNode? # `expressionlist`
---@return SelenScript.ASTNode
function ASTNodes.assign(node, scope, names, values)
	return {
		type = "assign",
		start = node.start,
		scope = scope,
		names = names,
		values = values or ASTNodes.expressionlist(node),
		finish = node.finish
	}
end

---@param node SelenScript.ASTNode # Used for source position info
---@param ... SelenScript.ASTNode
---@return SelenScript.ASTNode
function ASTNodes.expressionlist(node, ...)
	return {
		type = "expressionlist",
		start = node.start,
		finish = node.finish,
		...
	}
end

---@param node SelenScript.ASTNode # Used for source position info
---@param ... SelenScript.ASTNode
---@return SelenScript.ASTNode
function ASTNodes.varlist(node, ...)
	return {
		type = "varlist",
		start = node.start,
		finish = node.finish,
		...
	}
end

---@param node SelenScript.ASTNode # Used for source position info
---@param ... SelenScript.ASTNode
---@return SelenScript.ASTNode
function ASTNodes.attributenamelist(node, ...)
	return {
		type = "attributenamelist",
		start = node.start,
		finish = node.finish,
		...
	}
end

---@param node SelenScript.ASTNode # Used for source position info
---@param ... SelenScript.ASTNode
---@return SelenScript.ASTNode
function ASTNodes.fieldlist(node, ...)
	return {
		type = "fieldlist",
		start = node.start,
		finish = node.finish,
		...
	}
end

---@param node SelenScript.ASTNode # Used for source position info
---@param key SelenScript.ASTNode? # Expression or name
---@param value SelenScript.ASTNode
---@return SelenScript.ASTNode
function ASTNodes.field(node, key, value)
	return {
		type = "field",
		start = node.start,
		key = key,
		value = value,
		finish = node.finish,
	}
end

---@param node SelenScript.ASTNode # Used for source position info
---@param name string
---@param attribute string?
---@return SelenScript.ASTNode
function ASTNodes.attributename(node, name, attribute)
	return {
		type = "attributename",
		start = node.start,
		name = ASTNodes.name(node, name),
		attribute = attribute and ASTNodes.name(node, attribute) or nil,
		finish = node.finish
	}
end

---@param node SelenScript.ASTNode # Used for source position info
---@param fieldlist SelenScript.ASTNode
---@return SelenScript.ASTNode
function ASTNodes.table(node, fieldlist)
	return {
		type = "table",
		start = node.start,
		fields = fieldlist,
		finish = node.finish
	}
end

---@param node SelenScript.ASTNode # Used for source position info
---@param ... SelenScript.ASTNode
function ASTNodes.parlist(node, ...)
	return {
		type = "parlist",
		start = node.start,
		finish = node.finish,
		...
	}
end

---@param node SelenScript.ASTNode # Used for source position info
---@param args SelenScript.ASTNode
---@param block SelenScript.ASTNode
function ASTNodes.funcbody(node, args, block)
	return {
		type = "funcbody",
		start = node.start,
		args = args,
		block = block,
		finish = node.finish
	}
end

---@param node SelenScript.ASTNode # Used for source position info
---@param funcbody SelenScript.ASTNode
ASTNodes["function"] = function(node, funcbody)
	return {
		type = "function",
		start = node.start,
		funcbody = funcbody,
		finish = node.finish
	}
end

---@param node SelenScript.ASTNode # Used for source position info
---@param values SelenScript.ASTNode
ASTNodes["return"] = function(node, values)
	return {
		type = "return",
		start = node.start,
		values = values,
		finish = node.finish,
	}
end


return ASTHelpers
