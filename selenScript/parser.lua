local lpl = require "lpeglabel"
local re = require "relabel"


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


local unaryOpData = {
	-- ["OPERATOR"]={Precedence, TypeName}
	["not"]={10, "not"},
	["-"]={10, "neg"},
	["#"]={10, "len"},
	["~"]={10, "bit_not"},
}
local binaryOpData = {
	-- ["OPERATOR"]={Precedence, TypeName, RightAssoc}
	["^"]={11, "exp", true},

	-- UNARY

	["*"]={9, "mul", false},
	["/"]={9, "mul", false},
	["//"]={9, "mul", false},
	["%"]={9, "mul", false},

	["+"]={8, "add", false},
	["-"]={8, "add", false},

	[".."]={7, "concat", true},

	["<<"]={6, "bit_shift", false},
	[">>"]={6, "bit_shift", false},

	["&"]={5, "bit_and", false},

	["~"]={4, "bit_eor", false},

	["|"]={3, "bit_or", false},

	["<="]={2, "eq", false},
	[">="]={2, "eq", false},
	["<"]={2, "eq", false},
	[">"]={2, "eq", false},
	["~="]={2, "eq", false},
	["=="]={2, "eq", false},

	["and"]={1, "and", false},

	["or"]={1, "or", false},
}
---@param data any
---@param min_precedence number
local function climbPrecedence(data, min_precedence)
	local lhs = table.remove(data, 1)
	if type(lhs) == "string" then
		local opData = unaryOpData[lhs]
		return {
			type=opData[2],
			operator=lhs,
			rhs=climbPrecedence(data, opData[1])
		}
	end
	while #data > 0 do
		local lahead = data[1]
		if type(lahead) ~= "string" then break end

		local op = lahead:lower()
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
		lhs = {
			type=opData[2],
			lhs=lhs,
			operator=op,
			rhs=climbPrecedence(data, nextPrecedence)
		}
	end
	return lhs
end

---@class SS_DEFS
local defs = {
	-- Errors (handled so we can continue parsing)
	UNPARSED_INPUT=function(pos, str, name)
		pusherror {
			start=pos,
			finish=pos,
			msg="Unparsed input in '" .. tostring(name) .. "'\n" .. str .. "\n"
		}
	end,
	MISS_QUOTE_D=function(pos)
		pusherror {
			start=pos,
			finish=pos,
			msg="Missing double quote.",
			fix="\""
		}
	end,
	MISS_QUOTE_S=function(pos)
		pusherror {
			start=pos,
			finish=pos,
			msg="Missing single quote.",
			fix="'"
		}
	end,
	MISS_BRACKET=function(pos)
		pusherror {
			start=pos,
			finish=pos,
			msg="Missing closing bracket."
		}
	end,
	MISS_LONG_BRACKET=function(pos)
		pusherror {
			start=pos,
			finish=pos,
			msg="Missing long string closing."
		}
	end,
	MISS_SQUARE_BRACKET=function(pos)
		pusherror {
			start=pos,
			finish=pos,
			msg="Missing closing square bracket.",
			fix="]"
		}
	end,
	MISS_EXPR=function(pos)
		pusherror {
			start=pos,
			finish=pos,
			msg="Expecting an expresion."
		}
	end,
	MISS_DEC=function(pos)
		pusherror {
			start=pos,
			finish=pos,
			msg="Missing another decorator or function."
		}
	end,
	MISS_DEC_ARGS=function(pos)
		pusherror {
			start=pos,
			finish=pos,
			msg="Call to decorator must have aguments or no arguments at all."
		}
	end,
	MISS_CALL_AC=function(pos)
		pusherror {
			start=pos,
			finish=pos,
			msg="Expected a call after `:`."
		}
	end,
	EXPECT_DO=function(start, got, finish)
		pusherror {
			start=start,
			finish=finish,
			msg="Expected 'do' but found '" .. got .. "' instead.",
			fix="do"
		}
	end,
	EXPECT_THEN=function(start, got, finish)
		pusherror {
			start=start,
			finish=finish,
			msg="Expected 'then' but found '" .. got .. "' instead.",
			fix="then"
		}
	end,
	INVALID_ESC=function(pos)
		pusherror {
			start=pos,
			finish=pos,
			msg="Invalid escape sequence."
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
		if t[1] == '' and #t == 1 then return {type="block"} end
		return {
			type="block",
			...
		}
	end,

	assign=function(scope, varlist, typelist, exprlist)
		if typelist == "" then typelist = nil end
		if exprlist == "" then exprlist = nil end
		return {
			type="assign",
			varlist=varlist,
			typelist=typelist,
			exprlist=exprlist,
			scope=scope
		}
	end,
	label=function(label)
		return {
			type="label",
			label=label
		}
	end,
	["break"]=function(exprlist, stmt_if)
		if exprlist == "" then exprlist = {type="exprlist"} end
		return {
			type="break",
			exprlist=exprlist,
			stmt_if=stmt_if
		}
	end,
	["continue"]=function(stmt_if)
		return {
			type="continue",
			stmt_if=stmt_if
		}
	end,
	["goto"]=function(label, stmt_if)
		return {
			type="goto",
			label=label,
			stmt_if=stmt_if
		}
	end,
	["do"]=function(block)
		return {
			type="do",
			block=block
		}
	end,
	["while"]=function(condition, block)
		return {
			type="while",
			condition=condition,
			block=block
		}
	end,
	["repeat"]=function(block, condition)
		return {
			type="repeat",
			block=block,
			condition=condition
		}
	end,
	["elseif"]=function(condition, block)
		return {
			type="elseif",
			condition=condition,
			block=block
		}
	end,
	["else"]=function(block)
		return {
			type="else",
			block=block
		}
	end,
	["if"]=function(condition, block, ...)
		local t = {...}
		local last = table.remove(t, 1)
		local next = last
		while #t > 0 do
			local ast = table.remove(t, 1)
			last.next = ast
			last = ast
		end
		return {
			type="if",
			condition=condition,
			block=block,
			next=next
		}
	end,
	decorator=function(index, call)
		return {
			type="decorator",
			index=index,
			call=call
		}
	end,
	decorate=function(decoratorlist, expr)
		return {
			type="decorate",
			decorators=decoratorlist,
			expr=expr
		}
	end,
	["function"]=function(scope, funcname, body)
		return {
			type="function",
			scope=scope,
			funcname=funcname,
			body=body
		}
	end,
	for_range=function(varname, from, to, step, block)
		if step == "" then step = nil end
		return {
			type="for_range",
			varname=varname,
			from=from,
			to=to,
			step=step,
			block=block
		}
	end,
	for_each=function(namelist, exprlist, block)
		return {
			type="for_each",
			namelist=namelist,
			exprlist=exprlist,
			block=block
		}
	end,
	interface=function(name, ...)
		return {
			type="interface",
			name=name,
			...
		}
	end,
	class=function(...)
		
	end,

	if_expr=function(condition, lhs, rhs, ...)
		local t = {...}
		rhs = {
			type="if_expr",
			lhs=lhs,
			condition=condition,
			rhs=rhs
		}
		while #t > 0 do
			rhs = {
				type="if_expr",
				lhs=table.remove(t, 1),
				condition=table.remove(t, 1),
				rhs=rhs
			}
		end
		return rhs
	end,
	String=function(quote, value)  -- NOTE: used by Comment as well
		return {
			type="String",
			quote=quote,
			value=value
		}
	end,
	LongString=function(eqStart, eqFinish, value)  -- NOTE: used by LongComment as well
		local quoteEqLen = eqFinish-eqStart
		local quote = "[" .. string.rep("=", quoteEqLen) .. "["
		return {
			type="LongString",
			quote=quote,
			quoteEqLen=quoteEqLen,
			value=value
		}
	end,
	FormatString=function(quote, ...)
		local parts = {...}
		for i, v in pairs(parts) do
			if type(v) == "string" then
				parts[i] = v:gsub("{{", "{"):gsub("}}", "}")
			end
		end
		return {
			type="FormatString",
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
	Int=function(value)
		return {
			type="Int",
			value=value
		}
	end,
	Float=function(value)
		return {
			type="Float",
			value=value
		}
	end,
	Hex=function(value)
		return {
			type="Hex",
			value=value
		}
	end,
	["nil"]=function()
		return {type="nil"}
	end,
	bool=function(valueStr)
		local value
		if valueStr == "true" then
			value = true
		else
			value = false
		end
		return {type="bool", value=value}
	end,
	table=function(fieldlist)
		local index = 0
		for i, field in ipairs(fieldlist) do
			if field.name == nil and field.expr.type ~= "var_args" then
				index = index + 1
				field.name = {type="Int", value=tostring(index)}
			end
		end
		return {
			type="table",
			fieldlist=fieldlist
		}
	end,
	["anon_function"]=function(body)
		return {
			type="anon_function",
			body=body
		}
	end,
	var_args=function()
		return {
			type="var_args"
		}
	end,

	index=function(op, nameOrExpr, index)
		local name
		local expr
		if type(nameOrExpr) == "string" then
			name = nameOrExpr
		else
			expr = nameOrExpr
		end
		return {
			type="index",
			op=op,
			name=name,
			expr=expr,
			index=index
		}
	end,
	call=function(args, index)
		return {
			type="call",
			args=args,
			index=index
		}
	end,
	field=function(...)
		local t = {...}
		local name, expr
		if #t == 1 then
			expr = t[1]
		else
			name, expr = t[1], t[2]
		end
		return {
			type="field",
			name=name,
			expr=expr
		}
	end,

	funcbody=function(args, return_type, block)
		return {
			type="funcbody",
			args=args,
			return_type=return_type,
			block=block
		}
	end,
	["return"]=function(exprlist, stmt_if)
		if exprlist == "" then exprlist = {type="exprlist"} end
		return {
			type="return",
			exprlist=exprlist,
			stmt_if=stmt_if
		}
	end,

	math=function(...)
		return climbPrecedence({...}, 1)
	end,

	varlist=function(...)
		local t = {...}
		if t[1] == "" and #t == 1 then return {type="varlist"} end
		return {type="varlist", ...}
	end,
	exprlist=function(...)
		local t = {...}
		if t[1] == "" and #t == 1 then return {type="exprlist"} end
		return {type="exprlist", ...}
	end,
	namelist=function(...)
		local t = {...}
		if t[1] == "" and #t == 1 then return {type="namelist"} end
		return {type="namelist", ...}
	end,
	fieldlist=function(...)
		local t = {...}
		if t[1] == "" and #t == 1 then return {type="fieldlist"} end
		return {type="fieldlist", ...}
	end,
	decoratorlist=function(...)
		local t = {...}
		if t[1] == "" and #t == 1 then return {type="decoratorlist"} end
		return {type="decoratorlist", ...}
	end,

	param=function(name, param_type)
		return {
			type="param",
			name=name,
			param_type=param_type
		}
	end,
	parlist=function(...)
		local t = {...}
		if t[1] == "" and #t == 1 then return {type="parlist"} end
		return {type="parlist", ...}
	end,

	Comment=function(comment)
		return {
			type="Comment",
			comment=comment
		}
	end,
	LongComment=function(comment)
		return {
			type="LongComment",
			comment=comment
		}
	end,

	VAR_ARGS=function(...)
		return {
			type="VAR_ARGS",
			...
		}
	end,

	-- Typeing
	type=function(name)
		return {
			type="type",
			name=name
		}
	end,
	type_array=function(name, valuetype)
		return {
			type="type",
			name=name,
			valuetype=valuetype
		}
	end,
	type_table=function(name, keytype, valuetype)
		return {
			type="type",
			name=name,
			keytype=keytype,
			valuetype=valuetype
		}
	end,
	type_function=function(name, type_args, type_return)
		if type_args == "" then type_args = nil end
		if type_return == "" then type_return = nil end
		return {
			type="type",
			name=name,
			type_args=type_args,
			type_return=type_return
		}
	end,
	typelist=function(...)
		local t = {...}
		if t[1] == "" and #t == 1 then return {type="typelist"} end
		return {type="typelist", ...}
	end,

	type_and=function(a, b)
		return {
			type="type_and",
			a=a,
			b=b
		}
	end,
	type_or=function(a, b)
		return {
			type="type_or",
			a=a,
			b=b
		}
	end,
}
local grammar = re.compile(grammarStr, defs)


---@param codeStr string
local function parse(codeStr)
	errors = {}

	local startTime = os.clock()
	local ast, errMsg, errPos = grammar:match(codeStr)
	local endTime = os.clock()

	local _errors = errors
	errors = nil
	return {
		errors=_errors,
		ast=ast,
		parseTime=endTime-startTime,
		errMsg=errMsg,  -- these errors should not be used
		errPos=errPos  -- these errors should not be used
	}
end

return {
	defs=defs,
	parse=parse
}
