local lpl = require "lpeglabel"
local re = require "relabel"

local precedence = require "selenScript.precedence"

local unpack = table.unpack or unpack


local grammarPath = "selenScript/grammar.relabel"
local grammarFile = io.open(grammarPath, "r")
local grammarStr = grammarFile:read("*a"):gsub("/%*[^\n]*%*/", "")
grammarFile:close()

local errors

--- Used to add an error to the errors list
--- this is a function for syntatic sugar
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
			msg="Expecting an expresion."
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
			msg="Call to decorator must have aguments or no arguments at all."
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
			msg="Unexpected expresion.",
			expr=expr
		}
	end,

	-- Other
	esc_t="\t",
	nl=lpl.P'\r\n' + lpl.S'\r\n',
	dbg=function(...)
		print("dbg:", ...)
	end,

	-- AST Building
	block=function(...)
		local t = {...}
		local start, finish = table.remove(t, 1), table.remove(t, #t)
		return {
			type="block",
			start=start,
			finish=finish,
			unpack(t)
		}
	end,

	assign=function(start, scope, varlist, typelist, exprlist, finish)
		return {
			type="assign",
			start=start,
			finish=finish,
			scope=scope,
			var_list=varlist,
			type_list=typelist,
			expr_list=exprlist
		}
	end,
	attrib_assign=function(start, scope, startName, name, finishName, attrib, startTypedef, typedef, finishTypedef, startExpr, expr, finish)
		return {
			type="assign",
			start=start,
			finish=finish,
			scope=scope,
			var_list={
				type="name_list",
				start=startName,
				finish=finishName,
				name
			},
			attrib=attrib,
			type_list={
				type="type_list",
				start=startTypedef,
				finish=finishTypedef,
				typedef
			},
			expr_list={
				type="expr_list",
				start=startExpr,
				finish=finish,
				expr
			}
		}
	end,
	label=function(start, label, finish)
		return {
			type="label",
			start=start,
			finish=finish,
			label=label
		}
	end,
	["break"]=function(start, exprlist, stmt_if, finish)
		return {
			type="break",
			start=start,
			finish=finish,
			expr_list=exprlist,
			stmt_if=stmt_if
		}
	end,
	["continue"]=function(start, stmt_if, finish)
		return {
			type="continue",
			start=start,
			finish=finish,
			stmt_if=stmt_if
		}
	end,
	["goto"]=function(start, label, stmt_if, finish)
		return {
			type="goto",
			start=start,
			finish=finish,
			label=label,
			stmt_if=stmt_if
		}
	end,
	["do"]=function(start, block, finish)
		return {
			type="do",
				start=start,
				finish=finish,
			block=block
		}
	end,
	["while"]=function(start, condition, block, finish)
		return {
			type="while",
			start=start,
			finish=finish,
			condition=condition,
			block=block
		}
	end,
	["repeat"]=function(start, block, condition, finish)
		return {
			type="repeat",
			start=start,
			finish=finish,
			block=block,
			condition=condition
		}
	end,
	["elseif"]=function(start, condition, block, finish)
		return {
			type="elseif",
			start=start,
			finish=finish,
			condition=condition,
			block=block
		}
	end,
	["else"]=function(start, block, finish)
		return {
			type="else",
			start=start,
			finish=finish,
			block=block
		}
	end,
	["if"]=function(start, condition, block, ...)
		local t = {...}
		local finish = table.remove(t, #t)
		local last = table.remove(t, 1)
		local next = last
		while #t > 0 do
			local ast = table.remove(t, 1)
			last.next = ast
			last = ast
		end
		return {
			type="if",
			start=start,
			finish=finish,
			condition=condition,
			block=block,
			next=next
		}
	end,
	decorator=function(start, index, call, finish)
		return {
			type="decorator",
			start=start,
			finish=finish,
			index=index,
			call=call
		}
	end,
	decorate=function(start, decoratorlist, expr, finish)
		return {
			type="decorate",
			start=start,
			finish=finish,
			decorators=decoratorlist,
			expr=expr
		}
	end,
	["function"]=function(start, scope, funcname, body, finish)
		return {
			type="function",
			start=start,
			finish=finish,
			scope=scope,
			funcname=funcname,
			body=body
		}
	end,
	for_range=function(start, varname, from, to, step, block, finish)
		return {
			type="for_range",
			start=start,
			finish=finish,
			varname=varname,
			from=from,
			to=to,
			step=step,
			block=block
		}
	end,
	for_each=function(start, namelist, exprlist, block, finish)
		return {
			type="for_each",
			start=start,
			finish=finish,
			name_list=namelist,
			expr_list=exprlist,
			block=block
		}
	end,
	interface=function(start, scope, name, ...)
		local t = {...}
		local finish = table.remove(t, #t)
		return {
			type="interface",
			start=start,
			finish=finish,
			scope=scope,
			name=name,
			unpack(t)
		}
	end,

	if_expr=function(start, condition, trueExpr, falseExpr, finish)
		return {
			type="if_expr",
			start=start,
			finish=finish,
			trueExpr=trueExpr,
			condition=condition,
			falseExpr=falseExpr
		}
	end,
	String=function(start, quote, value, finish)  -- NOTE: used by Comment as well
		return {
			type="String",
			start=start,
			finish=finish,
			quote=quote,
			value=value
		}
	end,
	LongString=function(start, eqStart, eqFinish, value, finish)  -- NOTE: used by LongComment as well
		local quoteEqLen = eqFinish-eqStart
		local quote = "[" .. string.rep("=", quoteEqLen) .. "["
		return {
			type="LongString",
			start=start,
			finish=finish,
			quote=quote,
			quoteEqLen=quoteEqLen,
			value=value
		}
	end,
	FormatString=function(start, quote, ...)
		local parts = {...}
		local finish = table.remove(parts, #parts)
		for i, v in pairs(parts) do
			if type(v) == "string" then
				parts[i] = v:gsub("{{", "{"):gsub("}}", "}")
			end
		end
		return {
			type="FormatString",
			start=start,
			finish=finish,
			quote=quote,
			parts=parts
		}
	end,
	STRFormat=function(expr)
		return {
			type="STRFormat",
			expr=expr
		}
	end,
	Int=function(start, value, finish)
		return {
			type="Int",
			start=start,
			finish=finish,
			value=value
		}
	end,
	Float=function(start, value, finish)
		return {
			type="Float",
			start=start,
			finish=finish,
			value=value
		}
	end,
	Hex=function(start, value, finish)
		return {
			type="Hex",
			start=start,
			finish=finish,
			value=value
		}
	end,
	["nil"]=function(start, finish)
		return {
			type="nil",
			start=start,
			finish=finish,
		}
	end,
	bool=function(start, valueStr, finish)
		local value
		if valueStr == "true" then
			value = true
		else
			value = false
		end
		return {
			type="bool",
			start=start,
			finish=finish,
			value=value
		}
	end,
	table=function(start, fieldlist, finish)
		local index = 0
		for i, field in ipairs(fieldlist) do
			if field.name == nil and field.expr.type ~= "var_args" then
				index = index + 1
				field.name = {
					type="Int",
					start=field.start,
					finish=field.finish,
					value=tostring(index)
				}
			end
		end
		return {
			type="table",
			start=start,
			finish=finish,
			field_list=fieldlist
		}
	end,
	["anon_function"]=function(start, body, finish)
		return {
			type="anon_function",
			start=start,
			finish=finish,
			body=body
		}
	end,
	var_args=function(start, finish)
		return {
			type="var_args",
			start=start,
			finish=finish
		}
	end,

	index=function(start, op, nameOrExpr, index, finish)
		local name
		local expr
		if type(nameOrExpr) == "string" then
			name = nameOrExpr
		else
			expr = nameOrExpr
		end
		return {
			type="index",
			start=start,
			finish=finish,
			op=op,
			name=name,
			expr=expr,
			index=index
		}
	end,
	call=function(start, args, index, finish)
		if index == "" then index = nil end
		return {
			type="call",
			start=start,
			finish=finish,
			args=args,
			index=index
		}
	end,
	field=function(...)
		local t = {...}
		local name, expr
		local start, finish = table.remove(t, 1), table.remove(t, #t)
		if #t == 1 then
			expr = t[1]
		else
			name, expr = t[1], t[2]
		end
		return {
			type="field",
			start=start,
			finish=finish,
			name=name,
			expr=expr
		}
	end,

	funcbody=function(start, args, return_type, block, finish)
		return {
			type="funcbody",
			start=start,
			finish=finish,
			args=args,
			return_type=return_type,
			block=block
		}
	end,
	["return"]=function(start, exprlist, stmt_if, finish)
		return {
			type="return",
			start=start,
			finish=finish,
			expr_list=exprlist,
			stmt_if=stmt_if
		}
	end,

	math=function(...)
		return climbPrecedence({...})
	end,
	math_op=function(start, op, finish)
		return {
			type="math_op",
			op=op,
			start=start,
			finish=finish
		}
	end,

	var_list=function(...)
		local t = {...}
		local start, finish = table.remove(t, 1), table.remove(t, #t)
		return {
			type="var_list",
			start=start,
			finish=finish,
			unpack(t)
		}
	end,
	expr_list=function(...)
		local t = {...}
		local start, finish = table.remove(t, 1), table.remove(t, #t)
		return {
			type="expr_list",
			start=start,
			finish=finish,
			unpack(t)
		}
	end,
	name_list=function(...)
		local t = {...}
		local start, finish = table.remove(t, 1), table.remove(t, #t)
		return {
			type="name_list",
			start=start,
			finish=finish,
			unpack(t)
		}
	end,
	field_list=function(...)
		local t = {...}
		local start, finish = table.remove(t, 1), table.remove(t, #t)
		return {
			type="field_list",
			start=start,
			finish=finish,
			unpack(t)
		}
	end,
	decorator_list=function(...)
		local t = {...}
		local start, finish = table.remove(t, 1), table.remove(t, #t)
		return {
			type="decorator_list",
			start=start,
			finish=finish,
			unpack(t)
		}
	end,

	param=function(start, name, param_type, finish)
		return {
			type="param",
			start=start,
			finish=finish,
			name=name,
			param_type=param_type
		}
	end,
	par_list=function(...)
		local t = {...}
		local start, finish = table.remove(t, 1), table.remove(t, #t)
		return {
			type="par_list",
			start=start,
			finish=finish,
			unpack(t)
		}
	end,

	Comment=function(start, comment, finish)
		return {
			type="Comment",
			start=start,
			finish=finish,
			comment=comment
		}
	end,
	LongComment=function(start, comment, finish)
		return {
			type="LongComment",
			start=start,
			finish=finish,
			comment=comment
		}
	end,

	-- Typeing
	type_list=function(...)
		local t = {...}
		local start, finish = table.remove(t, 1), table.remove(t, #t)
		return {
			type="type_list",
			start=start,
			finish=finish,
			unpack(t)
		}
	end,
	type=function(start, name, finish)
		return {
			type="type",
			start=start,
			finish=finish,
			name=name
		}
	end,
	type_array=function(start, name, valuetype, finish)
		return {
			type="type_array",
			start=start,
			finish=finish,
			name=name,
			valuetype=valuetype
		}
	end,
	type_table=function(start, name, keytype, valuetype, finish)
		return {
			type="type_table",
			start=start,
			finish=finish,
			name=name,
			keytype=keytype,
			valuetype=valuetype
		}
	end,
	type_function=function(start, type_args, type_return, finish)
		return {
			type="type_function",
			start=start,
			finish=finish,
			type_args=type_args,
			type_return=type_return
		}
	end,
	type_or=function(start, a, b, finish)
		return {
			type="type_or",
			start=start,
			finish=finish,
			a=a,
			b=b
		}
	end,
}
local grammar = re.compile(grammarStr, defs)


---@param file SS_File
local function parse(file)
	errors = {}

	local startTime = os.clock()
	local ast, errMsg, errPos = grammar:match(file.code)
	local endTime = os.clock()

	-- add parent to all nodes
	local function setExtraData(_ast)
		for i, v in pairs(_ast) do
			if type(v) == "table" and v.type ~= nil and v.parent == nil then
				v.parent = _ast
				v.filepath = file.code
				setExtraData(v)
			end
		end
	end
	setExtraData(ast)
	ast.parent = nil  -- strange bug... this is set to the first item in the ast :/

	local errors_ = errors
	errors = nil
	return {
		errors=errors_,
		ast=ast,
		parseTime=endTime-startTime,
		errMsg=errMsg,  -- this should always be nil
		errPos=errPos  -- this should always be nil
	}
end

return {
	defs=defs,
	parse=parse
}
