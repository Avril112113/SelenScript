--- This file is a collection on functions to aid in transforming
--- NOTE: If the AST changes, these function might need updating
local ASTHelpers = {}


local ASTNodes = {}
ASTHelpers.Nodes = ASTNodes

---@param node ASTNode # Used for source position info
---@param prefix string?
---@param value string
---@return ASTNode
function ASTNodes.LineComment(node, prefix, value)
	return {
		type = "LineComment",
		start = node.start,
		prefix = prefix or "--",
		value = value,
		finish = node.finish,
	}
end

---@param node ASTNode # Used for source position info
---@param prefix string?
---@param value string
---@return ASTNode
function ASTNodes.LongComment(node, prefix, value)
	return {
		type = "LongComment",
		start = node.start,
		prefix = prefix or "[[",
		value = value,
		finish = node.finish,
	}
end

---@param node ASTNode # Used for source position info
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

---@param node ASTNode # Used for source position info
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

---@param node ASTNode # Used for source position info
---@param value string
---@return ASTNode
function ASTNodes.numeral(node, value)
	return {
		type = "numeral",
		start = node.start,
		value = value,
		finish = node.finish
	}
end

---@param node ASTNode # Used for source position info
---@param value string
---@param add_quotes boolean?  # Add quotes to value.
---@return ASTNode
function ASTNodes.string(node, value, add_quotes)
	if add_quotes then
		if not value:find("\"") then
			value = "\"" .. value .. "\""
		elseif not value:find("'") then
			value = "'" .. value .. "'"
		else
			local i = 0
			while true do
				local eqs = string.rep("=", i)
				local open = "[" .. eqs .. "["
				local close = "]"  .. eqs ..  "]"
				if not value:find(open) and not value:find(close) then
					value = open .. value .. close
					break
				end
				i = i + 0
			end
		end
	end
	return {
		type = "string",
		start = node.start,
		value = value,
		finish = node.finish
	}
end

---@param node ASTNode # Used for source position info
---@param ... ASTNode
---@return ASTNode
function ASTNodes.namelist(node, ...)
	return {
		type = "namelist",
		start = node.start,
		finish = node.finish,
		...
	}
end

---@param node ASTNode # Used for source position info
---@param how string?
---@param expr ASTNode
---@param index ASTNode?
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

---@param node ASTNode # Used for source position info
---@param args any[]|table|string
---@param self nil|boolean
---@return ASTNode
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

---@param node ASTNode # Used for source position info
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

---@param node ASTNode # Used for source position info
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

---@param node ASTNode # Used for source position info
---@param condition ASTNode
---@param block ASTNode
---@param _else ASTNode?
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

---@param node ASTNode # Used for source position info
---@param condition ASTNode
---@param block ASTNode
---@param _else ASTNode?
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

---@param node ASTNode # Used for source position info
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

---@param node ASTNode # Used for source position info
---@param scope "local"?
---@param names ASTNode # `varlist` or `attributenamelist`
---@param values ASTNode? # `expressionlist`
---@return ASTNode
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

---@param node ASTNode # Used for source position info
---@param ... ASTNode
---@return ASTNode
function ASTNodes.expressionlist(node, ...)
	return {
		type = "expressionlist",
		start = node.start,
		finish = node.finish,
		...
	}
end

---@param node ASTNode # Used for source position info
---@param ... ASTNode
---@return ASTNode
function ASTNodes.varlist(node, ...)
	return {
		type = "varlist",
		start = node.start,
		finish = node.finish,
		...
	}
end

---@param node ASTNode # Used for source position info
---@param ... ASTNode
---@return ASTNode
function ASTNodes.attributenamelist(node, ...)
	return {
		type = "attributenamelist",
		start = node.start,
		finish = node.finish,
		...
	}
end

---@param node ASTNode # Used for source position info
---@param ... ASTNode
---@return ASTNode
function ASTNodes.fieldlist(node, ...)
	return {
		type = "fieldlist",
		start = node.start,
		finish = node.finish,
		...
	}
end

---@param node ASTNode # Used for source position info
---@param key ASTNode? # Expression or name
---@param value ASTNode
---@return ASTNode
function ASTNodes.field(node, key, value)
	return {
		type = "field",
		start = node.start,
		key = key,
		value = value,
		finish = node.finish,
	}
end

---@param node ASTNode # Used for source position info
---@param name string
---@param attribute string?
---@return ASTNode
function ASTNodes.attributename(node, name, attribute)
	return {
		type = "attributename",
		start = node.start,
		name = ASTNodes.name(node, name),
		attribute = attribute and ASTNodes.name(node, attribute) or nil,
		finish = node.finish
	}
end

---@param node ASTNode # Used for source position info
---@param fieldlist ASTNode
---@return ASTNode
function ASTNodes.table(node, fieldlist)
	return {
		type = "table",
		start = node.start,
		fields = fieldlist,
		finish = node.finish
	}
end

---@param node ASTNode # Used for source position info
---@param ... ASTNode
function ASTNodes.parlist(node, ...)
	return {
		type = "parlist",
		start = node.start,
		finish = node.finish,
		...
	}
end

---@param node ASTNode # Used for source position info
---@param args ASTNode
---@param block ASTNode
function ASTNodes.funcbody(node, args, block)
	return {
		type = "funcbody",
		start = node.start,
		args = args,
		block = block,
		finish = node.finish
	}
end

---@param node ASTNode # Used for source position info
---@param funcbody ASTNode
ASTNodes["function"] = function(node, funcbody)
	return {
		type = "function",
		start = node.start,
		funcbody = funcbody,
		finish = node.finish
	}
end

---@param node ASTNode # Used for source position info
---@param values ASTNode
ASTNodes["return"] = function(node, values)
	return {
		type = "return",
		start = node.start,
		values = values,
		finish = node.finish,
	}
end


return ASTHelpers
