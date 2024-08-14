if print_warn then
	print_warn(("'%s' is depricated, use 'SelenScript.parser.ast_nodes' instead."):format(...))
else
	print(("WARN: '%s' is depricated, use 'SelenScript.parser.ast_nodes' instead."):format(...))
end


local Utils = require "SelenScript.utils"


--- This file is a collection on functions to aid in transforming
--- NOTE: If the AST changes, these function might need updating
local ASTHelpers = {}


local ASTNodes = {}
ASTHelpers.Nodes = ASTNodes

---@param node SelenScript.ASTNodes.Node # Used for source position info
---@param prefix string?
---@param value string
---@return SelenScript.ASTNodes.LineComment
function ASTNodes.LineComment(node, prefix, value)
	return {
		type = "LineComment",
		start = node.start,
		prefix = prefix or "--",
		value = value,
		finish = node.finish,
	}
end

---@param node SelenScript.ASTNodes.Node # Used for source position info
---@param prefix string?
---@param value string
---@return SelenScript.ASTNodes.LongComment
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

---@param node SelenScript.ASTNodes.Node # Used for source position info
---@param ... SelenScript.ASTNodes.Node
---@return SelenScript.ASTNodes.block
function ASTNodes.block(node, ...)
	return {
		type = "block",
		start = node.start,
		finish = node.finish,
		...
	}
end

---@param node SelenScript.ASTNodes.Node # Used for source position info
---@param name string
---@return SelenScript.ASTNodes.name
function ASTNodes.name(node, name)
	return {
		type = "name",
		start = node.start,
		name = name,
		finish = node.finish
	}
end

---@param node SelenScript.ASTNodes.Node # Used for source position info
---@param value string
---@return SelenScript.ASTNodes.numeral
function ASTNodes.numeral(node, value)
	return {
		type = "numeral",
		start = node.start,
		value = value,
		finish = node.finish
	}
end

---@param node SelenScript.ASTNodes.Node # Used for source position info
---@param value string
---@param prefix string?
---@param suffix string?
---@return SelenScript.ASTNodes.string
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

---@param node SelenScript.ASTNodes.Node # Used for source position info
---@param ... SelenScript.ASTNodes.Node
---@return SelenScript.ASTNodes.namelist
function ASTNodes.namelist(node, ...)
	return {
		type = "namelist",
		start = node.start,
		finish = node.finish,
		...
	}
end

---@param node SelenScript.ASTNodes.Node # Used for source position info
---@param how string?
---@param expr SelenScript.ASTNodes.Node
---@param index SelenScript.ASTNodes.Node?
---@param braces string?
---@return SelenScript.ASTNodes.index
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

---@param node SelenScript.ASTNodes.Node # Used for source position info
---@param args any[]|table|string
---@param self nil|boolean
---@return SelenScript.ASTNodes.call
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

---@param node SelenScript.ASTNodes.Node # Used for source position info
---@param name string|SelenScript.ASTNodes.Node
---@return SelenScript.ASTNodes.label
function ASTNodes.label(node, name)
	return {
		type = "label",
		start = node.start,
		name = type(name) == "string" and ASTNodes.name(node, name) or name,
		finish = node.finish
	}
end

---@param node SelenScript.ASTNodes.Node # Used for source position info
---@param name string|SelenScript.ASTNodes.Node
---@return SelenScript.ASTNodes.goto
ASTNodes["goto"] = function(node, name)
	return {
		type = "goto",
		start = node.start,
		name = type(name) == "string" and ASTNodes.name(node, name) or name,
		finish = node.finish
	}
end

---@param node SelenScript.ASTNodes.Node # Used for source position info
---@param condition SelenScript.ASTNodes.Node
---@param block SelenScript.ASTNodes.Node
---@param _else SelenScript.ASTNodes.Node?
---@return SelenScript.ASTNodes.if
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

---@param node SelenScript.ASTNodes.Node # Used for source position info
---@param condition SelenScript.ASTNodes.Node
---@param block SelenScript.ASTNodes.Node
---@param _else SelenScript.ASTNodes.Node?
---@return SelenScript.ASTNodes.elseif
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

---@param node SelenScript.ASTNodes.Node # Used for source position info
---@param block SelenScript.ASTNodes.Node
---@return SelenScript.ASTNodes.else
ASTNodes["else"] = function(node, block)
	return {
		type = "else",
		start = node.start,
		block = block,
		finish = node.finish
	}
end

---@param node SelenScript.ASTNodes.Node # Used for source position info
---@param scope "local"?
---@param names SelenScript.ASTNodes.Node # `varlist` or `attributenamelist`
---@param values SelenScript.ASTNodes.Node? # `expressionlist`
---@return SelenScript.ASTNodes.assign
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

---@param node SelenScript.ASTNodes.Node # Used for source position info
---@param ... SelenScript.ASTNodes.Node
---@return SelenScript.ASTNodes.expressionlist
function ASTNodes.expressionlist(node, ...)
	return {
		type = "expressionlist",
		start = node.start,
		finish = node.finish,
		...
	}
end

---@param node SelenScript.ASTNodes.Node # Used for source position info
---@param ... SelenScript.ASTNodes.Node
---@return SelenScript.ASTNodes.varlist
function ASTNodes.varlist(node, ...)
	return {
		type = "varlist",
		start = node.start,
		finish = node.finish,
		...
	}
end

---@param node SelenScript.ASTNodes.Node # Used for source position info
---@param ... SelenScript.ASTNodes.Node
---@return SelenScript.ASTNodes.attributenamelist
function ASTNodes.attributenamelist(node, ...)
	return {
		type = "attributenamelist",
		start = node.start,
		finish = node.finish,
		...
	}
end

---@param node SelenScript.ASTNodes.Node # Used for source position info
---@param ... SelenScript.ASTNodes.Node
---@return SelenScript.ASTNodes.fieldlist
function ASTNodes.fieldlist(node, ...)
	return {
		type = "fieldlist",
		start = node.start,
		finish = node.finish,
		...
	}
end

---@param node SelenScript.ASTNodes.Node # Used for source position info
---@param key SelenScript.ASTNodes.Node? # Expression or name
---@param value SelenScript.ASTNodes.Node
---@return SelenScript.ASTNodes.field
function ASTNodes.field(node, key, value)
	return {
		type = "field",
		start = node.start,
		key = key,
		value = value,
		finish = node.finish,
	}
end

---@param node SelenScript.ASTNodes.Node # Used for source position info
---@param name string
---@param attribute string?
---@return SelenScript.ASTNodes.attributename
function ASTNodes.attributename(node, name, attribute)
	return {
		type = "attributename",
		start = node.start,
		name = ASTNodes.name(node, name),
		attribute = attribute and ASTNodes.name(node, attribute) or nil,
		finish = node.finish
	}
end

---@param node SelenScript.ASTNodes.Node # Used for source position info
---@param fieldlist SelenScript.ASTNodes.Node
---@return SelenScript.ASTNodes.table
function ASTNodes.table(node, fieldlist)
	return {
		type = "table",
		start = node.start,
		fields = fieldlist,
		finish = node.finish
	}
end

---@param node SelenScript.ASTNodes.Node # Used for source position info
---@param ... SelenScript.ASTNodes.parlist
function ASTNodes.parlist(node, ...)
	return {
		type = "parlist",
		start = node.start,
		finish = node.finish,
		...
	}
end

---@param node SelenScript.ASTNodes.Node # Used for source position info
---@param args SelenScript.ASTNodes.Node
---@param block SelenScript.ASTNodes.block
function ASTNodes.funcbody(node, args, block)
	return {
		type = "funcbody",
		start = node.start,
		args = args,
		block = block,
		finish = node.finish
	}
end

---@param node SelenScript.ASTNodes.Node # Used for source position info
---@param funcbody SelenScript.ASTNodes.funcbody
ASTNodes["function"] = function(node, funcbody)
	return {
		type = "function",
		start = node.start,
		funcbody = funcbody,
		finish = node.finish
	}
end

---@param node SelenScript.ASTNodes.Node # Used for source position info
---@param values SelenScript.ASTNodes.expressionlist
ASTNodes["return"] = function(node, values)
	return {
		type = "return",
		start = node.start,
		values = values,
		finish = node.finish,
	}
end


return ASTHelpers
