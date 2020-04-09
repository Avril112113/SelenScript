local lpl = require "lpeglabel"
local re = require "relabel"

local precedence = require "selenScript.precedence"

local unpack = table.unpack or unpack


local __file_path__ = debug.getinfo(1).source:match("@(.*)$"):gsub("\\", "/"):gsub("/parser.lua$", "")
local grammarPath = __file_path__.."/grammar.relabel"
local grammarFile = io.open(grammarPath, "r")
local grammarStr = grammarFile:read("*a"):gsub("/%*[^\n]*%*/", "")
grammarFile:close()

local errors

--- Convenience function
local function setParent(parent, child)
	if type(child) == "table" and child.type ~= nil then
		child.parent = parent
	end
end
--- Convenience function
local function setParentForReturn(tbl)
	for _, v in pairs(tbl) do
		setParent(tbl, v)
	end
	return tbl
end
--- Convenience function
local function setParentForReturnRecursive(tbl)
	for i, v in pairs(tbl) do
		if type(v) == "table" and v.type ~= nil and i ~= "parent" then
			setParentForReturnRecursive(v)
		end
		setParent(tbl, v)
	end
	return tbl
end

--- Used to add an error to the errors list
--- this is a function for syntactic sugar
--- pusherror {pos=number, msg=string}
---@param err table
local function pusherror(err)
	table.insert(errors, err)
end


local unaryOpData = precedence.unaryOpData
local binaryOpData = precedence.binaryOpData
---@param data any
---@param min_precedence number
local function _climbPrecedence(data, min_precedence)
	local lhs = table.remove(data, 1)
	if lhs.type == "math_op" then
		local opData = unaryOpData[lhs.op]
		if opData == nil then
			error("Invalid op, was unary '" .. lhs .. "' but expected a valid operator")
		end
		if #opData ~= 2 then
			error("Invalid opData, data for unary '" .. lhs .. "' does not contain 2 values")
		end
		local rhs = _climbPrecedence(data, opData[1])
		lhs = {
			type=opData[2],
			start=lhs.start,
			finish=rhs.finish,
			operator=lhs.op,
			rhs=rhs
		}
	end
	while #data > 0 do
		local lahead = data[1]
		if lahead.type ~= "math_op" then break end

		local op = lahead.op:lower()
		local opData = binaryOpData[op]
		if opData == nil then
			error("Invalid op, was binary '" .. op .. "' but expected a valid operator")
		end
		if #opData ~= 3 then
			error("Invalid opData, data for binary '" .. op .. "' does not contain 3 values")
		end

		if opData[1] < min_precedence then
			break
		end

		lahead = table.remove(data, 1)

		local nextPrecedence = opData[1]
		if opData[3] == false then
			nextPrecedence = nextPrecedence + 1
		end
		local rhs = _climbPrecedence(data, nextPrecedence)
		lhs = {
			type=opData[2],
			start=lhs.start,
			finish=rhs.finish,
			lhs=lhs,
			operator=op,
			rhs=rhs
		}
	end
	return lhs
end
---@param data any
---@param min_precedence number
local function climbPrecedence(data, min_precedence)
	min_precedence = min_precedence or 1
	local result = _climbPrecedence(data, min_precedence)
	if #data > 0 then
		pusherror {
			type="internal_climbPrecedence_unparsed",
			start=-1,
			finish=-1,
			msg="INTERNAL: climbPrecedence error, unparsed data",
			ast={type="<climbPrecedence:DATA>", data}  -- not really AST but, its close ;)
		}
	end
	return result
end

local stringTypes = {
	String=true,
	LongString=true,
	FormatString=true
}
---@class SS_DEFS
local defs = {
	-- Errors (handled so we can continue parsing)
	UNPARSED_INPUT=function(pos, str, name)
		pusherror {
			type="unparsed",
			start=pos,
			finish=pos,
			msg=("Unparsed input in '" .. tostring(name) .. "'\n" .. str:gsub("^[\n\r]*", "")):gsub("[\n\r]*$", "")
		}
	end,
	MISSING=function(pos, missing)
		pusherror {
			type="missing",
			start=pos,
			finish=pos,
			msg="Missing '" .. missing .. "'.",
			fix=missing
		}
	end,
	MISS_LONG_BRACKET=function(pos)
		pusherror {
			type="miss_long_bracket",
			start=pos,
			finish=pos,
			msg="Missing long string closing."
		}
	end,
	MISS_EXPR=function(pos)
		pusherror {
			type="miss_expr",
			start=pos,
			finish=pos,
			msg="Expecting an expression."
		}
	end,
	-- MISS DECorator or function
	MISS_DEC=function(pos)
		pusherror {
			type="miss_dec",
			start=pos,
			finish=pos,
			msg="Missing another decorator or function."
		}
	end,
	MISS_DEC_ARGS=function(pos)
		pusherror {
			type="miss_dec_arg",
			start=pos,
			finish=pos,
			msg="Call to decorator must have arguments or no arguments at all."
		}
	end,
	-- MISS CALL After Colon
	MISS_CALL_AC=function(pos)
		pusherror {
			type="miss_call_ac",
			start=pos,
			finish=pos,
			msg="Expected a call after `:`."
		}
	end,
	MISS_FUNCNAME=function(pos)
		pusherror {
			type="miss_funcname",
			start=pos,
			finish=pos,
			msg="Expected a function name."
		}
	end,
	MISS_NAME=function(pos)
		pusherror {
			type="miss_name",
			start=pos,
			finish=pos,
			msg="Expected a name."
		}
	end,
	MISS_TYPE=function(pos)
		pusherror {
			type="miss_type",
			start=pos,
			finish=pos,
			msg="Expected a type."
		}
	end,
	MISS_TYPE_ATTRIBUTES=function(pos)
		pusherror {
			type="miss_type",
			start=pos,
			finish=pos,
			msg="Expected type attributes."
		}
	end,
	EXPECT_DO=function(start, got, finish)
		pusherror {
			type="expect_do",
			start=start,
			finish=finish,
			got=got,
			msg="Expected 'do' but found '" .. got .. "' instead.",
			fix="do"
		}
	end,
	EXPECT_THEN=function(start, got, finish)
		pusherror {
			type="expect_then",
			start=start,
			finish=finish,
			got=got,
			msg="Expected 'then' but found '" .. got .. "' instead.",
			fix="then"
		}
	end,
	INVALID_ESC=function(pos)
		pusherror {
			type="invalid_esc",
			start=pos,
			finish=pos,
			msg="Invalid escape sequence."
		}
	end,
	STMT_EXPR=function(expr, pos)
		pusherror {
			type="stmt_expr",
			start=pos,
			finish=pos,
			msg="Unexpected expression.",
			expr=expr
		}
	end,

	-- Other
	esc_t="\t",
	nl=lpl.P'\r\n' + lpl.S'\r\n',
	dbg=function(...)
		print("dbg:", ...)
	end
}
--- AST Building
-- `source_file` see parse()
function defs.block(...)
	local t = {...}
	local start, finish = table.remove(t, 1), table.remove(t, #t)
	return setParentForReturn {
		type="block",
		start=start,
		finish=finish,
		unpack(t)
	}
end

function defs.assign(start, scope, varlist, typelist, exprlist, finish)
	return setParentForReturn {
		type="assign",
		start=start,
		finish=finish,
		scope=scope,
		var_list=varlist,
		type_list=typelist,
		expr_list=exprlist
	}
end
function defs.attrib_assign(start, scope, name, attrib, startTypedef, typedef, finishTypedef, startExpr, expr, finish)
	return setParentForReturn {
		type="assign",
		start=start,
		finish=finish,
		scope=scope,
		var_list=name,
		attrib=attrib,
		type_list=defs.type_list(startTypedef, typedef, finishTypedef),
		expr_list=defs.expr_list(startExpr, expr, finish)
	}
end
function defs.label(start, label, finish)
	return setParentForReturn {
		type="label",
		start=start,
		finish=finish,
		label=label
	}
end
defs["break"] = function(start, exprlist, stmt_if, finish)
	return setParentForReturn {
		type="break",
		start=start,
		finish=finish,
		expr_list=exprlist,
		stmt_if=stmt_if
	}
end
function defs.continue(start, stmt_if, finish)
	return setParentForReturn {
		type="continue",
		start=start,
		finish=finish,
		stmt_if=stmt_if
	}
end
defs["goto"] = function(start, label, stmt_if, finish)
	return setParentForReturn {
		type="goto",
		start=start,
		finish=finish,
		label=label,
		stmt_if=stmt_if
	}
end
defs["do"] = function(start, block, finish)
	return setParentForReturn {
		type="do",
		start=start,
		finish=finish,
		block=block
	}
end
defs["do_expr"] = function(ast)
	ast.is_expr = true
	return ast
end
defs["while"] = function(start, condition, block, finish)
	return setParentForReturn {
		type="while",
		start=start,
		finish=finish,
		condition=condition,
		block=block
	}
end
defs["while_expr"] = function(ast)
	ast.is_expr = true
	return ast
end
defs["repeat"] = function(start, block, condition, finish)
	return setParentForReturn {
		type="repeat",
		start=start,
		finish=finish,
		block=block,
		condition=condition
	}
end
defs["elseif"] = function(start, condition, block, finish)
	return setParentForReturn {
		type="elseif",
		start=start,
		finish=finish,
		condition=condition,
		block=block
	}
end
defs["else"] = function(start, block, finish)
	return setParentForReturn {
		type="else",
		start=start,
		finish=finish,
		block=block
	}
end
defs["if"] = function(start, condition, block, ...)
	local t = {...}
	local finish = table.remove(t, #t)
	local last = table.remove(t, 1)
	local next = last
	while #t > 0 do
		local ast = table.remove(t, 1)
		last.next = ast
		last = ast
	end
	return setParentForReturn {
		type="if",
		start=start,
		finish=finish,
		condition=condition,
		block=block,
		next=next
	}
end
function defs.decorator(start, index, call, finish)
	-- Unknown cause of bug
	if type(call) == "number" then finish = call; call = nil end
	return setParentForReturn {
		type="decorator",
		start=start,
		finish=finish,
		index=index,
		call=call
	}
end
function defs.decorate(start, decoratorlist, expr, finish)
	return setParentForReturn {
		type="decorate",
		start=start,
		finish=finish,
		decorators=decoratorlist,
		expr=expr
	}
end
defs["function"] = function(start, scope, startFuncname, funcname, finishFuncname, body, finish)
	if type(funcname) == "string" then
		funcname = defs.String(startFuncname, "", funcname, finishFuncname)
	end
	return setParentForReturn {
		type="function",
		start=start,
		finish=finish,
		scope=scope,
		funcname=funcname,
		body=body
	}
end
function defs.for_range(start, startVarname, varname, finishVarname, from, to, step, block, finish)
	return setParentForReturn {
		type="for_range",
		start=start,
		finish=finish,
		varname=defs.String(startVarname, "", varname, finishVarname),
		from=from,
		to=to,
		step=step,
		block=block
	}
end
function defs.for_range_expr(ast)
	ast.is_expr = true
	return ast
end
function defs.for_each(start, namelist, exprlist, block, finish)
	return setParentForReturn {
		type="for_each",
		start=start,
		finish=finish,
		name_list=namelist,
		expr_list=exprlist,
		block=block
	}
end
function defs.for_each_expr(ast)
	ast.is_expr = true
	return ast
end
function defs.interface(start, scope, name, typeAttributes, ...)
	local t = {...}
	local finish = table.remove(t, #t)
	return setParentForReturn {
		type="interface",
		start=start,
		finish=finish,
		scope=scope,
		name=name,
		typeAttributes=typeAttributes,
		unpack(t)
	}
end

function defs.if_expr(start, condition, trueExpr, falseExpr, finish)
	return setParentForReturn {
		type="if_expr",
		start=start,
		finish=finish,
		trueExpr=trueExpr,
		condition=condition,
		falseExpr=falseExpr
	}
end
function defs.String(start, quote, value, finish)  -- NOTE: used by Comment as well
	return setParentForReturn {
		type="String",
		start=start,
		finish=finish,
		quote=quote,
		value=value,
		toString=function(self, parent)
			return self.quote .. self.value .. self.quote
		end,
		isEqual=function(self, other)
			return stringTypes[other.type] == true and self.value == other.value
		end
	}
end
function defs.LongString(start, eqStart, eqFinish, startNewline, value, finish)  -- NOTE: used by LongComment as well
	local quoteEqLen = eqFinish-eqStart
	local quote = "[" .. string.rep("=", quoteEqLen) .. "["
	local endQuote = "]" .. string.rep("=", quoteEqLen) .. "]"
	return setParentForReturn {
		type="LongString",
		start=start,
		finish=finish,
		quote=quote,
		endQuote=endQuote,
		quoteEqLen=quoteEqLen,
		startNewline=startNewline ~= nil,
		value=value,
		toString=function(self, parent)
			return self.quote .. self.value .. self.endQuote
		end,
		isEqual=function(self, other)
			return stringTypes[other.type] == true and self.value == other.value
		end
	}
end
function defs.FormatString(start, quote, ...)
	local parts = {...}
	local finish = table.remove(parts, #parts)
	for i, v in pairs(parts) do
		if type(v) == "string" then
			parts[i] = v:gsub("{{", "{"):gsub("}}", "}")
		end
	end
	return setParentForReturn {
		type="FormatString",
		start=start,
		finish=finish,
		quote=quote,
		parts=parts
	}
end
function defs.STRFormat(expr)
	return setParentForReturn {
		type="STRFormat",
		expr=expr
	}
end
function defs.Int(start, value, finish)
	return setParentForReturn {
		type="Int",
		start=start,
		finish=finish,
		value=value,
		toString=function(self, parent)
			return tostring(self.value)
		end,
		isEqual=function(self, other)
			-- TODO: check where `e+` or `e-` is used and could still mean the same value (currently does not)
			return self.type == other.type and self.value:lower() == other.value:lower()
		end
	}
end
function defs.Float(start, value, finish)
	return setParentForReturn {
		type="Float",
		start=start,
		finish=finish,
		value=value,
		toString=function(self, parent)
			return tostring(self.value)
		end,
		isEqual=function(self, other)
			-- TODO: check where `e+` or `e-` is used and could still mean the same value (currently does not)
			return self.type == other.type and self.value:lower() == other.value:lower()
		end
	}
end
function defs.Hex(start, value, finish)
	return setParentForReturn {
		type="Hex",
		start=start,
		finish=finish,
		value=value,
		toString=function(self, parent)
			return tostring(self.value)
		end,
		isEqual=function(self, other)
			return self.type == other.type and self.value:lower() == other.value:lower()
		end
	}
end
defs["nil"] = function(start, finish)
	return setParentForReturn {
		type="nil",
		start=start,
		finish=finish,
		toString=function(self, parent)
			return "nil"
		end,
		isEqual=function(self, other)
			return self.type == other.type
		end
	}
end
function defs.bool(start, valueStr, finish)
	local value
	if valueStr == "true" then
		value = true
	else
		value = false
	end
	return setParentForReturn {
		type="bool",
		start=start,
		finish=finish,
		value=value,
		toString=function(self, parent)
			return tostring(self.value)
		end,
		isEqual=function(self, other)
			return self.type == other.type and self.value:lower() == other.value:lower()
		end
	}
end
function defs.table(start, fieldlist, finish)
	local index = 0
	for i, field in ipairs(fieldlist) do
		if field.key == nil and field.value and field.value.type ~= "var_args" then
			index = index + 1
			field.key = defs.Int(field.start, tostring(index), field.finish)
		end
	end
	return setParentForReturn {
		type="table",
		start=start,
		finish=finish,
		field_list=fieldlist
	}
end
function defs.anon_function(start, body, finish)
	return setParentForReturn {
		type="anon_function",
		start=start,
		finish=finish,
		body=body
	}
end
function defs.var_args(start, finish)
	return setParentForReturn {
		type="var_args",
		start=start,
		finish=finish,
		isEqual=function(self, other)
			return self.type == other.type
		end
	}
end

function defs.index(start, op, exprStart, expr, exprFinish, index, finish)
	if type(expr) == "string" then
		expr = defs.String(exprStart, "", expr, exprFinish)
	else
		expr = expr
	end
	return setParentForReturn {
		type="index",
		start=start,
		finish=finish,
		op=op,
		expr=expr,
		index=index,
		toString=function(self, parent)
			local str = ""
			if parent ~= nil and parent.type == "index" then
				str = str .. "."
			end
			if self.expr ~= nil then
				if self.expr.toString ~= nil then
					str = str .. self.expr:toString(self)
				else
					return "<type " .. tostring(self.expr.type) .. " is missing toString()>"
				end
			else
				return "<index missing expr>"
			end
			if self.index ~= nil then
				if self.index.toString ~= nil then
					str = str .. self.index:toString(self)
				else
					return "<type " .. tostring(self.index.type) .. " is missing toString()>"
				end
			end
			return str
		end,
		isEqual=function(self, other)
			return self.type == other.type and self.expr:isEqual(other.expr) and ((self.index == nil and other.index == nil) or (self.index ~= nil and other.index ~= nil and self.index:isEqual(other.index)))
		end
	}
end
function defs.call(start, args, index, finish)
	if index == "" then index = nil end
	return setParentForReturn {
		type="call",
		start=start,
		finish=finish,
		args=args,
		index=index,
		toString=function(self, parent)
			local str = ""
			if self.expr ~= nil then
				if self.expr.toString ~= nil then
					str = str .. "()"
				else
					return "<type " .. tostring(self.expr.type) .. " is missing toString()>"
				end
			else
				return "<index missing expr>"
			end
			if self.index ~= nil then
				if self.index.toString ~= nil then
					str = str .. self.index:toString(self)
				else
					return "<type " .. tostring(self.index.type) .. " is missing toString()>"
				end
			end
			return str
		end
	}
end
function defs.field(...)
	local t = {...}
	local key, value
	local start, finish = table.remove(t, 1), table.remove(t, #t)
	if #t == 1 then
		value = t[1]
	else
		key, value = t[1], t[2]
	end
	return setParentForReturn {
		type="field",
		start=start,
		finish=finish,
		key=key,
		value=value
	}
end

function defs.funcbody(start, args, whereTypes, return_type, block, finish)
	return setParentForReturn {
		type="funcbody",
		start=start,
		finish=finish,
		args=args,
		whereTypes=whereTypes,
		return_type=return_type,
		block=block
	}
end
defs["return"] = function(start, exprlist, stmt_if, finish)
	return setParentForReturn {
		type="return",
		start=start,
		finish=finish,
		expr_list=exprlist,
		stmt_if=stmt_if
	}
end

function defs.math(...)
	return setParentForReturnRecursive(climbPrecedence({...}))
end
function defs.math_op(start, op, finish)
	return setParentForReturn {
		type="math_op",
		op=op,
		start=start,
		finish=finish
	}
end

function defs.var_list(...)
	local t = {...}
	local start, finish = table.remove(t, 1), table.remove(t, #t)
	return setParentForReturn {
		type="var_list",
		start=start,
		finish=finish,
		unpack(t)
	}
end
function defs.expr_list(...)
	local t = {...}
	local start, finish = table.remove(t, 1), table.remove(t, #t)
	return setParentForReturn {
		type="expr_list",
		start=start,
		finish=finish,
		unpack(t)
	}
end
function defs.name_list(...)
	local t = {...}
	local start, finish = table.remove(t, 1), table.remove(t, #t)
	return setParentForReturn {
		type="name_list",
		start=start,
		finish=finish,
		unpack(t)
	}
end
function defs.field_list(...)
	local t = {...}
	local start, finish = table.remove(t, 1), table.remove(t, #t)
	return setParentForReturn {
		type="field_list",
		start=start,
		finish=finish,
		unpack(t)
	}
end
function defs.decorator_list(...)
	local t = {...}
	local start, finish = table.remove(t, 1), table.remove(t, #t)
	return setParentForReturn {
		type="decorator_list",
		start=start,
		finish=finish,
		unpack(t)
	}
end

function defs.param(start, name, nameFinish, param_type, finish)
	return setParentForReturn {
		type="param",
		start=start,
		finish=finish,
		name=defs.String(start, "", name, nameFinish),
		param_type=param_type
	}
end
function defs.par_list(...)
	local t = {...}
	local start, finish = table.remove(t, 1), table.remove(t, #t)
	return setParentForReturn {
		type="par_list",
		start=start,
		finish=finish,
		unpack(t)
	}
end

function defs.Comment(start, comment, finish)
	return setParentForReturn {
		type="Comment",
		start=start,
		finish=finish,
		comment=comment
	}
end
function defs.LongComment(start, comment, finish)
	return setParentForReturn {
		type="LongComment",
		start=start,
		finish=finish,
		comment=comment
	}
end

-- Typing
function defs.type(start, name, attributes, finish)
	return setParentForReturn {
		type="type",
		start=start,
		finish=finish,
		name=name,
		attributes=attributes
	}
end
function defs.type_list(...)
	local t = {...}
	local start, finish = table.remove(t, 1), table.remove(t, #t)
	return setParentForReturn {
		type="type_list",
		start=start,
		finish=finish,
		unpack(t)
	}
end
function defs.type_function(start, name, args_par_list, return_type_list, finish)
	local args_field_list = defs.field_list(args_par_list.start, args_par_list.finish)
	for i, v in ipairs(args_par_list) do
		table.insert(args_field_list, defs.field(v.start, v.name, v.param_type, v.finish))
	end
	local args_table = defs.table(args_par_list.start, defs.field_list(args_par_list.start, args_field_list, args_par_list.finish), args_par_list.finish)
	local attributes = defs.type_list(args_par_list.start, args_table, return_type_list, args_par_list.finish)
	return setParentForReturn {
		type="type",
		start=start,
		finish=finish,
		name=name,
		attributes=attributes
	}
end
function defs.type_where_list(...)
	local t = {...}
	local start, finish = table.remove(t, 1), table.remove(t, #t)
	local wheres = {}
	while #t > 0 do
		local wstart = table.remove(t, 1)
		local name = table.remove(t, 1)
		local type_expr = table.remove(t, 1)
		local wfinish = table.remove(t, 1)
		table.insert(wheres, defs.type_where(wstart, name, type_expr, wfinish))
	end
	return setParentForReturn {
		type="type_where_list",
		start=start,
		finish=finish,
		unpack(wheres)
	}
end
function defs.type_where(start, name, type_expr, finish)
	return setParentForReturn {
		type="type_where",
		start=start,
		finish=finish,
		name=name,
		type_expr=type_expr
	}
end
function defs.type_implements(start, name, finish)
	return setParentForReturn {
		type="type_implements",
		start=start,
		finish=finish,
		name=name
	}
end
function defs.type_metaimplements(start, name, finish)
	return setParentForReturn {
		type="type_metaimplements",
		start=start,
		finish=finish,
		name=name
	}
end
local grammar = re.compile(grammarStr, defs)


local function SetParentNodes(ast)
	for key, child in pairs(ast) do
		if key ~= "parent" and type(child) == "table" and child.type ~= nil then
			child.parent = ast
			SetParentNodes(child)
		end
	end
end
---@param filePath string
---@param src string
---@param setParentNodes boolean
local function parse(filePath, src, setParentNodes)
	---@class SS_SourceFile
	local source_file = {
		type="source_file",
		filePath=filePath,
		start=1,
		finish=#src,
		-- typing
		---@type table
		parseErrors=nil,
		---@type SS_Binder
		binder=nil,
		---@type SS_Transformer
		transformer=nil,
		---@type SS_Transpiler
		transpiler=nil
	}

	errors = {}
	local startTime = os.clock()
	local ast, errMsg, errPos = grammar:match(src)
	local endTime = os.clock()

	source_file.block = ast
	source_file.parseTime = endTime-startTime
	source_file.parseErrors = errors

	errors = nil

	return source_file
end

return {
	defs=defs,
	parse=parse
}
