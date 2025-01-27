-- THIS FILE IS GENERATED

---@alias SelenScript.ASTNodes.SrcPosition integer

local ASTNodes = {}

local Utils = require("SelenScript.utils")


---@class SelenScript.ASTNodes.Node
---@field type string
---@field start integer
---@field start_source integer?  # Used to override source map start position
---@field finish integer
---@field source SelenScript.ASTNodes.Source

---@alias SelenScript.ASTNodes.expression SelenScript.ASTNodes.mul|SelenScript.ASTNodes.bit_and|SelenScript.ASTNodes.add|SelenScript.ASTNodes.concat|SelenScript.ASTNodes.eq|SelenScript.ASTNodes.bit_shift|SelenScript.ASTNodes.exp|SelenScript.ASTNodes.and|SelenScript.ASTNodes.or|SelenScript.ASTNodes.bit_or|SelenScript.ASTNodes.bit_eor|SelenScript.ASTNodes.len|SelenScript.ASTNodes.neg|SelenScript.ASTNodes.not|SelenScript.ASTNodes.bit_not|SelenScript.ASTNodes.ifexpr|SelenScript.ASTNodes.stmt_expr|SelenScript.ASTNodes.nil|SelenScript.ASTNodes.boolean|SelenScript.ASTNodes.var_args|SelenScript.ASTNodes.numeral|SelenScript.ASTNodes.string|SelenScript.ASTNodes.function|SelenScript.ASTNodes.index|SelenScript.ASTNodes.table


---@class SelenScript.ASTNodes.LineComment : SelenScript.ASTNodes.Node
---@field type "LineComment"
---@field start SelenScript.ASTNodes.SrcPosition
---@field finish SelenScript.ASTNodes.SrcPosition
---@field prefix string|"-"
---@field value string

---@param args {_parent:SelenScript.ASTNodes.Node?, start:SelenScript.ASTNodes.SrcPosition?, finish:SelenScript.ASTNodes.SrcPosition?, prefix:string|"-", value:string}
---@return SelenScript.ASTNodes.LineComment
ASTNodes["LineComment"] = function(args)
	args["source"] = args._parent and args._parent.source or nil
	args["type"] = "LineComment"
	if args["start"] == nil then
		args["start"] = args._parent and args._parent.start or 1
	end
	assert(type(args["start"]) == "number")
	if args["finish"] == nil then
		args["finish"] = args._parent and args._parent.finish or 1
	end
	assert(type(args["finish"]) == "number")
	assert(args["prefix"])
	assert(type(args["value"]) == "string")
	args["_parent"] = nil
	return args
end


---@class SelenScript.ASTNodes.LongComment : SelenScript.ASTNodes.Node
---@field type "LongComment"
---@field start SelenScript.ASTNodes.SrcPosition
---@field finish SelenScript.ASTNodes.SrcPosition
---@field prefix string|"--[["
---@field suffix string|"]]"|"--]]"
---@field value string?

---@param args {_parent:SelenScript.ASTNodes.Node?, start:SelenScript.ASTNodes.SrcPosition?, finish:SelenScript.ASTNodes.SrcPosition?, prefix:string|"--[[", suffix:string|"]]"|"--]]", value:string?}
---@return SelenScript.ASTNodes.LongComment
ASTNodes["LongComment"] = function(args)
	args["source"] = args._parent and args._parent.source or nil
	args["type"] = "LongComment"
	if args["start"] == nil then
		args["start"] = args._parent and args._parent.start or 1
	end
	assert(type(args["start"]) == "number")
	if args["finish"] == nil then
		args["finish"] = args._parent and args._parent.finish or 1
	end
	assert(type(args["finish"]) == "number")
	assert(args["prefix"])
	assert(args["suffix"])
	assert(args["value"] == nil or type(args["value"]) == "string")
	args["_parent"] = nil
	return args
end


---@class SelenScript.ASTNodes.add : SelenScript.ASTNodes.Node
---@field type "add"
---@field start SelenScript.ASTNodes.SrcPosition
---@field finish SelenScript.ASTNodes.SrcPosition
---@field lhs SelenScript.ASTNodes.expression
---@field op "+"|"-"
---@field rhs SelenScript.ASTNodes.expression

---@param args {_parent:SelenScript.ASTNodes.Node?, start:SelenScript.ASTNodes.SrcPosition?, finish:SelenScript.ASTNodes.SrcPosition?, lhs:SelenScript.ASTNodes.expression, op:"+"|"-", rhs:SelenScript.ASTNodes.expression}
---@return SelenScript.ASTNodes.add
ASTNodes["add"] = function(args)
	args["source"] = args._parent and args._parent.source or nil
	args["type"] = "add"
	if args["start"] == nil then
		args["start"] = args._parent and args._parent.start or 1
	end
	assert(type(args["start"]) == "number")
	if args["finish"] == nil then
		args["finish"] = args._parent and args._parent.finish or 1
	end
	assert(type(args["finish"]) == "number")
	assert(type(args["lhs"]) == "table" and (args["lhs"].type == "mul" or args["lhs"].type == "bit_and" or args["lhs"].type == "add" or args["lhs"].type == "concat" or args["lhs"].type == "eq" or args["lhs"].type == "bit_shift" or args["lhs"].type == "exp" or args["lhs"].type == "and" or args["lhs"].type == "or" or args["lhs"].type == "bit_or" or args["lhs"].type == "bit_eor" or args["lhs"].type == "len" or args["lhs"].type == "neg" or args["lhs"].type == "not" or args["lhs"].type == "bit_not" or args["lhs"].type == "ifexpr" or args["lhs"].type == "stmt_expr" or args["lhs"].type == "nil" or args["lhs"].type == "boolean" or args["lhs"].type == "var_args" or args["lhs"].type == "numeral" or args["lhs"].type == "string" or args["lhs"].type == "function" or args["lhs"].type == "index" or args["lhs"].type == "table"))
	assert(args["op"] == "+" or args["op"] == "-")
	assert(type(args["rhs"]) == "table" and (args["rhs"].type == "mul" or args["rhs"].type == "bit_and" or args["rhs"].type == "add" or args["rhs"].type == "concat" or args["rhs"].type == "eq" or args["rhs"].type == "bit_shift" or args["rhs"].type == "exp" or args["rhs"].type == "and" or args["rhs"].type == "or" or args["rhs"].type == "bit_or" or args["rhs"].type == "bit_eor" or args["rhs"].type == "len" or args["rhs"].type == "neg" or args["rhs"].type == "not" or args["rhs"].type == "bit_not" or args["rhs"].type == "ifexpr" or args["rhs"].type == "stmt_expr" or args["rhs"].type == "nil" or args["rhs"].type == "boolean" or args["rhs"].type == "var_args" or args["rhs"].type == "numeral" or args["rhs"].type == "string" or args["rhs"].type == "function" or args["rhs"].type == "index" or args["rhs"].type == "table"))
	args["_parent"] = nil
	return args
end


---@class SelenScript.ASTNodes.and : SelenScript.ASTNodes.Node
---@field type "and"
---@field start SelenScript.ASTNodes.SrcPosition
---@field finish SelenScript.ASTNodes.SrcPosition
---@field lhs SelenScript.ASTNodes.expression
---@field op "and"
---@field rhs SelenScript.ASTNodes.expression

---@param args {_parent:SelenScript.ASTNodes.Node?, start:SelenScript.ASTNodes.SrcPosition?, finish:SelenScript.ASTNodes.SrcPosition?, lhs:SelenScript.ASTNodes.expression, rhs:SelenScript.ASTNodes.expression}
---@return SelenScript.ASTNodes.and
ASTNodes["and"] = function(args)
	args["source"] = args._parent and args._parent.source or nil
	args["type"] = "and"
	if args["start"] == nil then
		args["start"] = args._parent and args._parent.start or 1
	end
	assert(type(args["start"]) == "number")
	if args["finish"] == nil then
		args["finish"] = args._parent and args._parent.finish or 1
	end
	assert(type(args["finish"]) == "number")
	assert(type(args["lhs"]) == "table" and (args["lhs"].type == "mul" or args["lhs"].type == "bit_and" or args["lhs"].type == "add" or args["lhs"].type == "concat" or args["lhs"].type == "eq" or args["lhs"].type == "bit_shift" or args["lhs"].type == "exp" or args["lhs"].type == "and" or args["lhs"].type == "or" or args["lhs"].type == "bit_or" or args["lhs"].type == "bit_eor" or args["lhs"].type == "len" or args["lhs"].type == "neg" or args["lhs"].type == "not" or args["lhs"].type == "bit_not" or args["lhs"].type == "ifexpr" or args["lhs"].type == "stmt_expr" or args["lhs"].type == "nil" or args["lhs"].type == "boolean" or args["lhs"].type == "var_args" or args["lhs"].type == "numeral" or args["lhs"].type == "string" or args["lhs"].type == "function" or args["lhs"].type == "index" or args["lhs"].type == "table"))
	args["op"] = "and"
	assert(type(args["rhs"]) == "table" and (args["rhs"].type == "mul" or args["rhs"].type == "bit_and" or args["rhs"].type == "add" or args["rhs"].type == "concat" or args["rhs"].type == "eq" or args["rhs"].type == "bit_shift" or args["rhs"].type == "exp" or args["rhs"].type == "and" or args["rhs"].type == "or" or args["rhs"].type == "bit_or" or args["rhs"].type == "bit_eor" or args["rhs"].type == "len" or args["rhs"].type == "neg" or args["rhs"].type == "not" or args["rhs"].type == "bit_not" or args["rhs"].type == "ifexpr" or args["rhs"].type == "stmt_expr" or args["rhs"].type == "nil" or args["rhs"].type == "boolean" or args["rhs"].type == "var_args" or args["rhs"].type == "numeral" or args["rhs"].type == "string" or args["rhs"].type == "function" or args["rhs"].type == "index" or args["rhs"].type == "table"))
	args["_parent"] = nil
	return args
end


---@class SelenScript.ASTNodes.assign : SelenScript.ASTNodes.Node
---@field type "assign"
---@field start SelenScript.ASTNodes.SrcPosition
---@field finish SelenScript.ASTNodes.SrcPosition
---@field names SelenScript.ASTNodes.attributenamelist|SelenScript.ASTNodes.varlist
---@field scope "local"|"default"
---@field values SelenScript.ASTNodes.expressionlist

---@param args {_parent:SelenScript.ASTNodes.Node?, start:SelenScript.ASTNodes.SrcPosition?, finish:SelenScript.ASTNodes.SrcPosition?, names:SelenScript.ASTNodes.attributenamelist|SelenScript.ASTNodes.varlist, scope:nil|"local"|"default", values:SelenScript.ASTNodes.expressionlist?}
---@return SelenScript.ASTNodes.assign
ASTNodes["assign"] = function(args)
	args["source"] = args._parent and args._parent.source or nil
	args["type"] = "assign"
	if args["start"] == nil then
		args["start"] = args._parent and args._parent.start or 1
	end
	assert(type(args["start"]) == "number")
	if args["finish"] == nil then
		args["finish"] = args._parent and args._parent.finish or 1
	end
	assert(type(args["finish"]) == "number")
	assert(type(args["names"]) == "table" and (args["names"].type == "attributenamelist" or args["names"].type == "varlist"))
	if args["scope"] == nil then
		args["scope"] = "default"
	end
	assert(args["scope"] == "local" or args["scope"] == "default")
	if args["values"] == nil then
		args["values"] = ASTNodes[("expressionlist")]({
			_parent = args,
		})
	end
	assert(type(args["values"]) == "table" and args["values"].type == "expressionlist")
	args["_parent"] = nil
	return args
end


---@class SelenScript.ASTNodes.attributename : SelenScript.ASTNodes.Node
---@field type "attributename"
---@field start SelenScript.ASTNodes.SrcPosition
---@field finish SelenScript.ASTNodes.SrcPosition
---@field attribute SelenScript.ASTNodes.name?
---@field name SelenScript.ASTNodes.name

---@param args {_parent:SelenScript.ASTNodes.Node?, start:SelenScript.ASTNodes.SrcPosition?, finish:SelenScript.ASTNodes.SrcPosition?, attribute:nil|SelenScript.ASTNodes.name|string, name:SelenScript.ASTNodes.name|string}
---@return SelenScript.ASTNodes.attributename
ASTNodes["attributename"] = function(args)
	args["source"] = args._parent and args._parent.source or nil
	args["type"] = "attributename"
	if args["start"] == nil then
		args["start"] = args._parent and args._parent.start or 1
	end
	assert(type(args["start"]) == "number")
	if args["finish"] == nil then
		args["finish"] = args._parent and args._parent.finish or 1
	end
	assert(type(args["finish"]) == "number")
	if type(args["attribute"]) == "string" then
		args["attribute"] = ASTNodes[("attribute")]({
			_parent = args,
			value = args["attribute"],
		})
	end
	assert(args["attribute"] == nil or type(args["attribute"]) == "table" and args["attribute"].type == "name")
	if type(args["name"]) == "string" then
		args["name"] = ASTNodes[("name")]({
			_parent = args,
			name = args["name"],
		})
	end
	assert(type(args["name"]) == "table" and args["name"].type == "name")
	args["_parent"] = nil
	return args
end


---@class SelenScript.ASTNodes.attributenamelist : SelenScript.ASTNodes.Node
---@field type "attributenamelist"
---@field start SelenScript.ASTNodes.SrcPosition
---@field finish SelenScript.ASTNodes.SrcPosition
---@field [integer] SelenScript.ASTNodes.attributename?

---@param args {_parent:SelenScript.ASTNodes.Node?, start:SelenScript.ASTNodes.SrcPosition?, finish:SelenScript.ASTNodes.SrcPosition?, [integer]:SelenScript.ASTNodes.attributename?}
---@return SelenScript.ASTNodes.attributenamelist
ASTNodes["attributenamelist"] = function(args)
	args["source"] = args._parent and args._parent.source or nil
	args["type"] = "attributenamelist"
	if args["start"] == nil then
		args["start"] = args._parent and args._parent.start or 1
	end
	assert(type(args["start"]) == "number")
	if args["finish"] == nil then
		args["finish"] = args._parent and args._parent.finish or 1
	end
	assert(type(args["finish"]) == "number")
	args["_parent"] = nil
	return args
end


---@class SelenScript.ASTNodes.binary_op : SelenScript.ASTNodes.Node
---@field type "binary_op"
---@field start SelenScript.ASTNodes.SrcPosition
---@field finish SelenScript.ASTNodes.SrcPosition
---@field op "*"|"^"|"//"|"/"|"%"|"+"|"-"|".."|"<<"|">>"|"&"|"~"|"|"|"<="|">="|"<"|">"|"~="|"=="|"and"|"or"

---@param args {_parent:SelenScript.ASTNodes.Node?, start:SelenScript.ASTNodes.SrcPosition?, finish:SelenScript.ASTNodes.SrcPosition?, op:"*"|"^"|"//"|"/"|"%"|"+"|"-"|".."|"<<"|">>"|"&"|"~"|"|"|"<="|">="|"<"|">"|"~="|"=="|"and"|"or"}
---@return SelenScript.ASTNodes.binary_op
ASTNodes["binary_op"] = function(args)
	args["source"] = args._parent and args._parent.source or nil
	args["type"] = "binary_op"
	if args["start"] == nil then
		args["start"] = args._parent and args._parent.start or 1
	end
	assert(type(args["start"]) == "number")
	if args["finish"] == nil then
		args["finish"] = args._parent and args._parent.finish or 1
	end
	assert(type(args["finish"]) == "number")
	assert(args["op"] == "*" or args["op"] == "^" or args["op"] == "//" or args["op"] == "/" or args["op"] == "%" or args["op"] == "+" or args["op"] == "-" or args["op"] == ".." or args["op"] == "<<" or args["op"] == ">>" or args["op"] == "&" or args["op"] == "~" or args["op"] == "|" or args["op"] == "<=" or args["op"] == ">=" or args["op"] == "<" or args["op"] == ">" or args["op"] == "~=" or args["op"] == "==" or args["op"] == "and" or args["op"] == "or")
	args["_parent"] = nil
	return args
end


---@class SelenScript.ASTNodes.bit_and : SelenScript.ASTNodes.Node
---@field type "bit_and"
---@field start SelenScript.ASTNodes.SrcPosition
---@field finish SelenScript.ASTNodes.SrcPosition
---@field lhs SelenScript.ASTNodes.expression
---@field op "&"
---@field rhs SelenScript.ASTNodes.expression

---@param args {_parent:SelenScript.ASTNodes.Node?, start:SelenScript.ASTNodes.SrcPosition?, finish:SelenScript.ASTNodes.SrcPosition?, lhs:SelenScript.ASTNodes.expression, rhs:SelenScript.ASTNodes.expression}
---@return SelenScript.ASTNodes.bit_and
ASTNodes["bit_and"] = function(args)
	args["source"] = args._parent and args._parent.source or nil
	args["type"] = "bit_and"
	if args["start"] == nil then
		args["start"] = args._parent and args._parent.start or 1
	end
	assert(type(args["start"]) == "number")
	if args["finish"] == nil then
		args["finish"] = args._parent and args._parent.finish or 1
	end
	assert(type(args["finish"]) == "number")
	assert(type(args["lhs"]) == "table" and (args["lhs"].type == "mul" or args["lhs"].type == "bit_and" or args["lhs"].type == "add" or args["lhs"].type == "concat" or args["lhs"].type == "eq" or args["lhs"].type == "bit_shift" or args["lhs"].type == "exp" or args["lhs"].type == "and" or args["lhs"].type == "or" or args["lhs"].type == "bit_or" or args["lhs"].type == "bit_eor" or args["lhs"].type == "len" or args["lhs"].type == "neg" or args["lhs"].type == "not" or args["lhs"].type == "bit_not" or args["lhs"].type == "ifexpr" or args["lhs"].type == "stmt_expr" or args["lhs"].type == "nil" or args["lhs"].type == "boolean" or args["lhs"].type == "var_args" or args["lhs"].type == "numeral" or args["lhs"].type == "string" or args["lhs"].type == "function" or args["lhs"].type == "index" or args["lhs"].type == "table"))
	args["op"] = "&"
	assert(type(args["rhs"]) == "table" and (args["rhs"].type == "mul" or args["rhs"].type == "bit_and" or args["rhs"].type == "add" or args["rhs"].type == "concat" or args["rhs"].type == "eq" or args["rhs"].type == "bit_shift" or args["rhs"].type == "exp" or args["rhs"].type == "and" or args["rhs"].type == "or" or args["rhs"].type == "bit_or" or args["rhs"].type == "bit_eor" or args["rhs"].type == "len" or args["rhs"].type == "neg" or args["rhs"].type == "not" or args["rhs"].type == "bit_not" or args["rhs"].type == "ifexpr" or args["rhs"].type == "stmt_expr" or args["rhs"].type == "nil" or args["rhs"].type == "boolean" or args["rhs"].type == "var_args" or args["rhs"].type == "numeral" or args["rhs"].type == "string" or args["rhs"].type == "function" or args["rhs"].type == "index" or args["rhs"].type == "table"))
	args["_parent"] = nil
	return args
end


---@class SelenScript.ASTNodes.bit_eor : SelenScript.ASTNodes.Node
---@field type "bit_eor"
---@field start SelenScript.ASTNodes.SrcPosition
---@field finish SelenScript.ASTNodes.SrcPosition
---@field lhs SelenScript.ASTNodes.expression
---@field op "~"
---@field rhs SelenScript.ASTNodes.expression

---@param args {_parent:SelenScript.ASTNodes.Node?, start:SelenScript.ASTNodes.SrcPosition?, finish:SelenScript.ASTNodes.SrcPosition?, lhs:SelenScript.ASTNodes.expression, rhs:SelenScript.ASTNodes.expression}
---@return SelenScript.ASTNodes.bit_eor
ASTNodes["bit_eor"] = function(args)
	args["source"] = args._parent and args._parent.source or nil
	args["type"] = "bit_eor"
	if args["start"] == nil then
		args["start"] = args._parent and args._parent.start or 1
	end
	assert(type(args["start"]) == "number")
	if args["finish"] == nil then
		args["finish"] = args._parent and args._parent.finish or 1
	end
	assert(type(args["finish"]) == "number")
	assert(type(args["lhs"]) == "table" and (args["lhs"].type == "mul" or args["lhs"].type == "bit_and" or args["lhs"].type == "add" or args["lhs"].type == "concat" or args["lhs"].type == "eq" or args["lhs"].type == "bit_shift" or args["lhs"].type == "exp" or args["lhs"].type == "and" or args["lhs"].type == "or" or args["lhs"].type == "bit_or" or args["lhs"].type == "bit_eor" or args["lhs"].type == "len" or args["lhs"].type == "neg" or args["lhs"].type == "not" or args["lhs"].type == "bit_not" or args["lhs"].type == "ifexpr" or args["lhs"].type == "stmt_expr" or args["lhs"].type == "nil" or args["lhs"].type == "boolean" or args["lhs"].type == "var_args" or args["lhs"].type == "numeral" or args["lhs"].type == "string" or args["lhs"].type == "function" or args["lhs"].type == "index" or args["lhs"].type == "table"))
	args["op"] = "~"
	assert(type(args["rhs"]) == "table" and (args["rhs"].type == "mul" or args["rhs"].type == "bit_and" or args["rhs"].type == "add" or args["rhs"].type == "concat" or args["rhs"].type == "eq" or args["rhs"].type == "bit_shift" or args["rhs"].type == "exp" or args["rhs"].type == "and" or args["rhs"].type == "or" or args["rhs"].type == "bit_or" or args["rhs"].type == "bit_eor" or args["rhs"].type == "len" or args["rhs"].type == "neg" or args["rhs"].type == "not" or args["rhs"].type == "bit_not" or args["rhs"].type == "ifexpr" or args["rhs"].type == "stmt_expr" or args["rhs"].type == "nil" or args["rhs"].type == "boolean" or args["rhs"].type == "var_args" or args["rhs"].type == "numeral" or args["rhs"].type == "string" or args["rhs"].type == "function" or args["rhs"].type == "index" or args["rhs"].type == "table"))
	args["_parent"] = nil
	return args
end


---@class SelenScript.ASTNodes.bit_not : SelenScript.ASTNodes.Node
---@field type "bit_not"
---@field start SelenScript.ASTNodes.SrcPosition
---@field finish SelenScript.ASTNodes.SrcPosition
---@field op "~"
---@field rhs SelenScript.ASTNodes.expression

---@param args {_parent:SelenScript.ASTNodes.Node?, start:SelenScript.ASTNodes.SrcPosition?, finish:SelenScript.ASTNodes.SrcPosition?, rhs:SelenScript.ASTNodes.expression}
---@return SelenScript.ASTNodes.bit_not
ASTNodes["bit_not"] = function(args)
	args["source"] = args._parent and args._parent.source or nil
	args["type"] = "bit_not"
	if args["start"] == nil then
		args["start"] = args._parent and args._parent.start or 1
	end
	assert(type(args["start"]) == "number")
	if args["finish"] == nil then
		args["finish"] = args._parent and args._parent.finish or 1
	end
	assert(type(args["finish"]) == "number")
	args["op"] = "~"
	assert(type(args["rhs"]) == "table" and (args["rhs"].type == "mul" or args["rhs"].type == "bit_and" or args["rhs"].type == "add" or args["rhs"].type == "concat" or args["rhs"].type == "eq" or args["rhs"].type == "bit_shift" or args["rhs"].type == "exp" or args["rhs"].type == "and" or args["rhs"].type == "or" or args["rhs"].type == "bit_or" or args["rhs"].type == "bit_eor" or args["rhs"].type == "len" or args["rhs"].type == "neg" or args["rhs"].type == "not" or args["rhs"].type == "bit_not" or args["rhs"].type == "ifexpr" or args["rhs"].type == "stmt_expr" or args["rhs"].type == "nil" or args["rhs"].type == "boolean" or args["rhs"].type == "var_args" or args["rhs"].type == "numeral" or args["rhs"].type == "string" or args["rhs"].type == "function" or args["rhs"].type == "index" or args["rhs"].type == "table"))
	args["_parent"] = nil
	return args
end


---@class SelenScript.ASTNodes.bit_or : SelenScript.ASTNodes.Node
---@field type "bit_or"
---@field start SelenScript.ASTNodes.SrcPosition
---@field finish SelenScript.ASTNodes.SrcPosition
---@field lhs SelenScript.ASTNodes.expression
---@field op "|"
---@field rhs SelenScript.ASTNodes.expression

---@param args {_parent:SelenScript.ASTNodes.Node?, start:SelenScript.ASTNodes.SrcPosition?, finish:SelenScript.ASTNodes.SrcPosition?, lhs:SelenScript.ASTNodes.expression, rhs:SelenScript.ASTNodes.expression}
---@return SelenScript.ASTNodes.bit_or
ASTNodes["bit_or"] = function(args)
	args["source"] = args._parent and args._parent.source or nil
	args["type"] = "bit_or"
	if args["start"] == nil then
		args["start"] = args._parent and args._parent.start or 1
	end
	assert(type(args["start"]) == "number")
	if args["finish"] == nil then
		args["finish"] = args._parent and args._parent.finish or 1
	end
	assert(type(args["finish"]) == "number")
	assert(type(args["lhs"]) == "table" and (args["lhs"].type == "mul" or args["lhs"].type == "bit_and" or args["lhs"].type == "add" or args["lhs"].type == "concat" or args["lhs"].type == "eq" or args["lhs"].type == "bit_shift" or args["lhs"].type == "exp" or args["lhs"].type == "and" or args["lhs"].type == "or" or args["lhs"].type == "bit_or" or args["lhs"].type == "bit_eor" or args["lhs"].type == "len" or args["lhs"].type == "neg" or args["lhs"].type == "not" or args["lhs"].type == "bit_not" or args["lhs"].type == "ifexpr" or args["lhs"].type == "stmt_expr" or args["lhs"].type == "nil" or args["lhs"].type == "boolean" or args["lhs"].type == "var_args" or args["lhs"].type == "numeral" or args["lhs"].type == "string" or args["lhs"].type == "function" or args["lhs"].type == "index" or args["lhs"].type == "table"))
	args["op"] = "|"
	assert(type(args["rhs"]) == "table" and (args["rhs"].type == "mul" or args["rhs"].type == "bit_and" or args["rhs"].type == "add" or args["rhs"].type == "concat" or args["rhs"].type == "eq" or args["rhs"].type == "bit_shift" or args["rhs"].type == "exp" or args["rhs"].type == "and" or args["rhs"].type == "or" or args["rhs"].type == "bit_or" or args["rhs"].type == "bit_eor" or args["rhs"].type == "len" or args["rhs"].type == "neg" or args["rhs"].type == "not" or args["rhs"].type == "bit_not" or args["rhs"].type == "ifexpr" or args["rhs"].type == "stmt_expr" or args["rhs"].type == "nil" or args["rhs"].type == "boolean" or args["rhs"].type == "var_args" or args["rhs"].type == "numeral" or args["rhs"].type == "string" or args["rhs"].type == "function" or args["rhs"].type == "index" or args["rhs"].type == "table"))
	args["_parent"] = nil
	return args
end


---@class SelenScript.ASTNodes.bit_shift : SelenScript.ASTNodes.Node
---@field type "bit_shift"
---@field start SelenScript.ASTNodes.SrcPosition
---@field finish SelenScript.ASTNodes.SrcPosition
---@field lhs SelenScript.ASTNodes.expression
---@field op "<<"|">>"
---@field rhs SelenScript.ASTNodes.expression

---@param args {_parent:SelenScript.ASTNodes.Node?, start:SelenScript.ASTNodes.SrcPosition?, finish:SelenScript.ASTNodes.SrcPosition?, lhs:SelenScript.ASTNodes.expression, op:"<<"|">>", rhs:SelenScript.ASTNodes.expression}
---@return SelenScript.ASTNodes.bit_shift
ASTNodes["bit_shift"] = function(args)
	args["source"] = args._parent and args._parent.source or nil
	args["type"] = "bit_shift"
	if args["start"] == nil then
		args["start"] = args._parent and args._parent.start or 1
	end
	assert(type(args["start"]) == "number")
	if args["finish"] == nil then
		args["finish"] = args._parent and args._parent.finish or 1
	end
	assert(type(args["finish"]) == "number")
	assert(type(args["lhs"]) == "table" and (args["lhs"].type == "mul" or args["lhs"].type == "bit_and" or args["lhs"].type == "add" or args["lhs"].type == "concat" or args["lhs"].type == "eq" or args["lhs"].type == "bit_shift" or args["lhs"].type == "exp" or args["lhs"].type == "and" or args["lhs"].type == "or" or args["lhs"].type == "bit_or" or args["lhs"].type == "bit_eor" or args["lhs"].type == "len" or args["lhs"].type == "neg" or args["lhs"].type == "not" or args["lhs"].type == "bit_not" or args["lhs"].type == "ifexpr" or args["lhs"].type == "stmt_expr" or args["lhs"].type == "nil" or args["lhs"].type == "boolean" or args["lhs"].type == "var_args" or args["lhs"].type == "numeral" or args["lhs"].type == "string" or args["lhs"].type == "function" or args["lhs"].type == "index" or args["lhs"].type == "table"))
	assert(args["op"] == "<<" or args["op"] == ">>")
	assert(type(args["rhs"]) == "table" and (args["rhs"].type == "mul" or args["rhs"].type == "bit_and" or args["rhs"].type == "add" or args["rhs"].type == "concat" or args["rhs"].type == "eq" or args["rhs"].type == "bit_shift" or args["rhs"].type == "exp" or args["rhs"].type == "and" or args["rhs"].type == "or" or args["rhs"].type == "bit_or" or args["rhs"].type == "bit_eor" or args["rhs"].type == "len" or args["rhs"].type == "neg" or args["rhs"].type == "not" or args["rhs"].type == "bit_not" or args["rhs"].type == "ifexpr" or args["rhs"].type == "stmt_expr" or args["rhs"].type == "nil" or args["rhs"].type == "boolean" or args["rhs"].type == "var_args" or args["rhs"].type == "numeral" or args["rhs"].type == "string" or args["rhs"].type == "function" or args["rhs"].type == "index" or args["rhs"].type == "table"))
	args["_parent"] = nil
	return args
end


---@class SelenScript.ASTNodes.block : SelenScript.ASTNodes.Node
---@field type "block"
---@field start SelenScript.ASTNodes.SrcPosition
---@field finish SelenScript.ASTNodes.SrcPosition
---@field [integer] nil|SelenScript.ASTNodes.conditional_stmt|SelenScript.ASTNodes.assign|SelenScript.ASTNodes.op_assign|SelenScript.ASTNodes.label|SelenScript.ASTNodes.break|SelenScript.ASTNodes.goto|SelenScript.ASTNodes.do|SelenScript.ASTNodes.while|SelenScript.ASTNodes.repeat|SelenScript.ASTNodes.if|SelenScript.ASTNodes.forrange|SelenScript.ASTNodes.foriter|SelenScript.ASTNodes.functiondef|SelenScript.ASTNodes.index|SelenScript.ASTNodes.continue|SelenScript.ASTNodes.return

---@param args {_parent:SelenScript.ASTNodes.Node?, start:SelenScript.ASTNodes.SrcPosition?, finish:SelenScript.ASTNodes.SrcPosition?, [integer]:nil|SelenScript.ASTNodes.conditional_stmt|SelenScript.ASTNodes.assign|SelenScript.ASTNodes.op_assign|SelenScript.ASTNodes.label|SelenScript.ASTNodes.break|SelenScript.ASTNodes.goto|SelenScript.ASTNodes.do|SelenScript.ASTNodes.while|SelenScript.ASTNodes.repeat|SelenScript.ASTNodes.if|SelenScript.ASTNodes.forrange|SelenScript.ASTNodes.foriter|SelenScript.ASTNodes.functiondef|SelenScript.ASTNodes.index|SelenScript.ASTNodes.continue|SelenScript.ASTNodes.return}
---@return SelenScript.ASTNodes.block
ASTNodes["block"] = function(args)
	args["source"] = args._parent and args._parent.source or nil
	args["type"] = "block"
	if args["start"] == nil then
		args["start"] = args._parent and args._parent.start or 1
	end
	assert(type(args["start"]) == "number")
	if args["finish"] == nil then
		args["finish"] = args._parent and args._parent.finish or 1
	end
	assert(type(args["finish"]) == "number")
	args["_parent"] = nil
	return args
end


---@class SelenScript.ASTNodes.boolean : SelenScript.ASTNodes.Node
---@field type "boolean"
---@field start SelenScript.ASTNodes.SrcPosition
---@field finish SelenScript.ASTNodes.SrcPosition
---@field value "true"|"false"

---@param args {_parent:SelenScript.ASTNodes.Node?, start:SelenScript.ASTNodes.SrcPosition?, finish:SelenScript.ASTNodes.SrcPosition?, value:"true"|"false"}
---@return SelenScript.ASTNodes.boolean
ASTNodes["boolean"] = function(args)
	args["source"] = args._parent and args._parent.source or nil
	args["type"] = "boolean"
	if args["start"] == nil then
		args["start"] = args._parent and args._parent.start or 1
	end
	assert(type(args["start"]) == "number")
	if args["finish"] == nil then
		args["finish"] = args._parent and args._parent.finish or 1
	end
	assert(type(args["finish"]) == "number")
	assert(args["value"] == "true" or args["value"] == "false")
	args["_parent"] = nil
	return args
end


---@class SelenScript.ASTNodes.break : SelenScript.ASTNodes.Node
---@field type "break"
---@field start SelenScript.ASTNodes.SrcPosition
---@field finish SelenScript.ASTNodes.SrcPosition
---@field values SelenScript.ASTNodes.expressionlist

---@param args {_parent:SelenScript.ASTNodes.Node?, start:SelenScript.ASTNodes.SrcPosition?, finish:SelenScript.ASTNodes.SrcPosition?, values:SelenScript.ASTNodes.expressionlist}
---@return SelenScript.ASTNodes.break
ASTNodes["break"] = function(args)
	args["source"] = args._parent and args._parent.source or nil
	args["type"] = "break"
	if args["start"] == nil then
		args["start"] = args._parent and args._parent.start or 1
	end
	assert(type(args["start"]) == "number")
	if args["finish"] == nil then
		args["finish"] = args._parent and args._parent.finish or 1
	end
	assert(type(args["finish"]) == "number")
	assert(type(args["values"]) == "table" and args["values"].type == "expressionlist")
	args["_parent"] = nil
	return args
end


---@class SelenScript.ASTNodes.call : SelenScript.ASTNodes.Node
---@field type "call"
---@field start SelenScript.ASTNodes.SrcPosition
---@field finish SelenScript.ASTNodes.SrcPosition
---@field args nil|SelenScript.ASTNodes.expressionlist|SelenScript.ASTNodes.table|SelenScript.ASTNodes.string
---@field self true?

---@param args {_parent:SelenScript.ASTNodes.Node?, start:SelenScript.ASTNodes.SrcPosition?, finish:SelenScript.ASTNodes.SrcPosition?, args:nil|SelenScript.ASTNodes.expressionlist|SelenScript.ASTNodes.table|SelenScript.ASTNodes.string, self:true?}
---@return SelenScript.ASTNodes.call
ASTNodes["call"] = function(args)
	args["source"] = args._parent and args._parent.source or nil
	args["type"] = "call"
	if args["start"] == nil then
		args["start"] = args._parent and args._parent.start or 1
	end
	assert(type(args["start"]) == "number")
	if args["finish"] == nil then
		args["finish"] = args._parent and args._parent.finish or 1
	end
	assert(type(args["finish"]) == "number")
	assert(args["args"] == nil or type(args["args"]) == "table" and (args["args"].type == "expressionlist" or args["args"].type == "table" or args["args"].type == "string"))
	args["_parent"] = nil
	return args
end


---@class SelenScript.ASTNodes.chunk : SelenScript.ASTNodes.Node
---@field type "chunk"
---@field start SelenScript.ASTNodes.SrcPosition
---@field finish SelenScript.ASTNodes.SrcPosition
---@field block SelenScript.ASTNodes.block
---@field hashline string?

---@param args {_parent:SelenScript.ASTNodes.Node?, start:SelenScript.ASTNodes.SrcPosition?, finish:SelenScript.ASTNodes.SrcPosition?, block:SelenScript.ASTNodes.block, hashline:string?}
---@return SelenScript.ASTNodes.chunk
ASTNodes["chunk"] = function(args)
	args["source"] = args._parent and args._parent.source or nil
	args["type"] = "chunk"
	if args["start"] == nil then
		args["start"] = args._parent and args._parent.start or 1
	end
	assert(type(args["start"]) == "number")
	if args["finish"] == nil then
		args["finish"] = args._parent and args._parent.finish or 1
	end
	assert(type(args["finish"]) == "number")
	assert(type(args["block"]) == "table" and args["block"].type == "block")
	assert(args["hashline"] == nil or type(args["hashline"]) == "string")
	args["_parent"] = nil
	return args
end


---@class SelenScript.ASTNodes.concat : SelenScript.ASTNodes.Node
---@field type "concat"
---@field start SelenScript.ASTNodes.SrcPosition
---@field finish SelenScript.ASTNodes.SrcPosition
---@field lhs SelenScript.ASTNodes.expression
---@field op ".."
---@field rhs SelenScript.ASTNodes.expression

---@param args {_parent:SelenScript.ASTNodes.Node?, start:SelenScript.ASTNodes.SrcPosition?, finish:SelenScript.ASTNodes.SrcPosition?, lhs:SelenScript.ASTNodes.expression, rhs:SelenScript.ASTNodes.expression}
---@return SelenScript.ASTNodes.concat
ASTNodes["concat"] = function(args)
	args["source"] = args._parent and args._parent.source or nil
	args["type"] = "concat"
	if args["start"] == nil then
		args["start"] = args._parent and args._parent.start or 1
	end
	assert(type(args["start"]) == "number")
	if args["finish"] == nil then
		args["finish"] = args._parent and args._parent.finish or 1
	end
	assert(type(args["finish"]) == "number")
	assert(type(args["lhs"]) == "table" and (args["lhs"].type == "mul" or args["lhs"].type == "bit_and" or args["lhs"].type == "add" or args["lhs"].type == "concat" or args["lhs"].type == "eq" or args["lhs"].type == "bit_shift" or args["lhs"].type == "exp" or args["lhs"].type == "and" or args["lhs"].type == "or" or args["lhs"].type == "bit_or" or args["lhs"].type == "bit_eor" or args["lhs"].type == "len" or args["lhs"].type == "neg" or args["lhs"].type == "not" or args["lhs"].type == "bit_not" or args["lhs"].type == "ifexpr" or args["lhs"].type == "stmt_expr" or args["lhs"].type == "nil" or args["lhs"].type == "boolean" or args["lhs"].type == "var_args" or args["lhs"].type == "numeral" or args["lhs"].type == "string" or args["lhs"].type == "function" or args["lhs"].type == "index" or args["lhs"].type == "table"))
	args["op"] = ".."
	assert(type(args["rhs"]) == "table" and (args["rhs"].type == "mul" or args["rhs"].type == "bit_and" or args["rhs"].type == "add" or args["rhs"].type == "concat" or args["rhs"].type == "eq" or args["rhs"].type == "bit_shift" or args["rhs"].type == "exp" or args["rhs"].type == "and" or args["rhs"].type == "or" or args["rhs"].type == "bit_or" or args["rhs"].type == "bit_eor" or args["rhs"].type == "len" or args["rhs"].type == "neg" or args["rhs"].type == "not" or args["rhs"].type == "bit_not" or args["rhs"].type == "ifexpr" or args["rhs"].type == "stmt_expr" or args["rhs"].type == "nil" or args["rhs"].type == "boolean" or args["rhs"].type == "var_args" or args["rhs"].type == "numeral" or args["rhs"].type == "string" or args["rhs"].type == "function" or args["rhs"].type == "index" or args["rhs"].type == "table"))
	args["_parent"] = nil
	return args
end


---@class SelenScript.ASTNodes.conditional_stmt : SelenScript.ASTNodes.Node
---@field type "conditional_stmt"
---@field start SelenScript.ASTNodes.SrcPosition
---@field finish SelenScript.ASTNodes.SrcPosition
---@field [integer] SelenScript.ASTNodes.continue|SelenScript.ASTNodes.break|SelenScript.ASTNodes.goto|SelenScript.ASTNodes.return
---@field condition SelenScript.ASTNodes.expression

---@param args {_parent:SelenScript.ASTNodes.Node?, start:SelenScript.ASTNodes.SrcPosition?, finish:SelenScript.ASTNodes.SrcPosition?, [integer]:SelenScript.ASTNodes.continue|SelenScript.ASTNodes.break|SelenScript.ASTNodes.goto|SelenScript.ASTNodes.return, condition:SelenScript.ASTNodes.expression}
---@return SelenScript.ASTNodes.conditional_stmt
ASTNodes["conditional_stmt"] = function(args)
	args["source"] = args._parent and args._parent.source or nil
	args["type"] = "conditional_stmt"
	if args["start"] == nil then
		args["start"] = args._parent and args._parent.start or 1
	end
	assert(type(args["start"]) == "number")
	if args["finish"] == nil then
		args["finish"] = args._parent and args._parent.finish or 1
	end
	assert(type(args["finish"]) == "number")
	assert(type(args["condition"]) == "table" and (args["condition"].type == "mul" or args["condition"].type == "bit_and" or args["condition"].type == "add" or args["condition"].type == "concat" or args["condition"].type == "eq" or args["condition"].type == "bit_shift" or args["condition"].type == "exp" or args["condition"].type == "and" or args["condition"].type == "or" or args["condition"].type == "bit_or" or args["condition"].type == "bit_eor" or args["condition"].type == "len" or args["condition"].type == "neg" or args["condition"].type == "not" or args["condition"].type == "bit_not" or args["condition"].type == "ifexpr" or args["condition"].type == "stmt_expr" or args["condition"].type == "nil" or args["condition"].type == "boolean" or args["condition"].type == "var_args" or args["condition"].type == "numeral" or args["condition"].type == "string" or args["condition"].type == "function" or args["condition"].type == "index" or args["condition"].type == "table"))
	args["_parent"] = nil
	return args
end


---@class SelenScript.ASTNodes.continue : SelenScript.ASTNodes.Node
---@field type "continue"
---@field start SelenScript.ASTNodes.SrcPosition
---@field finish SelenScript.ASTNodes.SrcPosition

---@param args {_parent:SelenScript.ASTNodes.Node?, start:SelenScript.ASTNodes.SrcPosition?, finish:SelenScript.ASTNodes.SrcPosition?}
---@return SelenScript.ASTNodes.continue
ASTNodes["continue"] = function(args)
	args["source"] = args._parent and args._parent.source or nil
	args["type"] = "continue"
	if args["start"] == nil then
		args["start"] = args._parent and args._parent.start or 1
	end
	assert(type(args["start"]) == "number")
	if args["finish"] == nil then
		args["finish"] = args._parent and args._parent.finish or 1
	end
	assert(type(args["finish"]) == "number")
	args["_parent"] = nil
	return args
end


---@class SelenScript.ASTNodes.decorator : SelenScript.ASTNodes.Node
---@field type "decorator"
---@field start SelenScript.ASTNodes.SrcPosition
---@field finish SelenScript.ASTNodes.SrcPosition
---@field expr SelenScript.ASTNodes.index

---@param args {_parent:SelenScript.ASTNodes.Node?, start:SelenScript.ASTNodes.SrcPosition?, finish:SelenScript.ASTNodes.SrcPosition?, expr:SelenScript.ASTNodes.index}
---@return SelenScript.ASTNodes.decorator
ASTNodes["decorator"] = function(args)
	args["source"] = args._parent and args._parent.source or nil
	args["type"] = "decorator"
	if args["start"] == nil then
		args["start"] = args._parent and args._parent.start or 1
	end
	assert(type(args["start"]) == "number")
	if args["finish"] == nil then
		args["finish"] = args._parent and args._parent.finish or 1
	end
	assert(type(args["finish"]) == "number")
	assert(type(args["expr"]) == "table" and args["expr"].type == "index")
	args["_parent"] = nil
	return args
end


---@class SelenScript.ASTNodes.decorator_list : SelenScript.ASTNodes.Node
---@field type "decorator_list"
---@field start SelenScript.ASTNodes.SrcPosition
---@field finish SelenScript.ASTNodes.SrcPosition
---@field [integer] SelenScript.ASTNodes.decorator?

---@param args {_parent:SelenScript.ASTNodes.Node?, start:SelenScript.ASTNodes.SrcPosition?, finish:SelenScript.ASTNodes.SrcPosition?, [integer]:SelenScript.ASTNodes.decorator?}
---@return SelenScript.ASTNodes.decorator_list
ASTNodes["decorator_list"] = function(args)
	args["source"] = args._parent and args._parent.source or nil
	args["type"] = "decorator_list"
	if args["start"] == nil then
		args["start"] = args._parent and args._parent.start or 1
	end
	assert(type(args["start"]) == "number")
	if args["finish"] == nil then
		args["finish"] = args._parent and args._parent.finish or 1
	end
	assert(type(args["finish"]) == "number")
	args["_parent"] = nil
	return args
end


---@class SelenScript.ASTNodes.do : SelenScript.ASTNodes.Node
---@field type "do"
---@field start SelenScript.ASTNodes.SrcPosition
---@field finish SelenScript.ASTNodes.SrcPosition
---@field block SelenScript.ASTNodes.block

---@param args {_parent:SelenScript.ASTNodes.Node?, start:SelenScript.ASTNodes.SrcPosition?, finish:SelenScript.ASTNodes.SrcPosition?, block:SelenScript.ASTNodes.block}
---@return SelenScript.ASTNodes.do
ASTNodes["do"] = function(args)
	args["source"] = args._parent and args._parent.source or nil
	args["type"] = "do"
	if args["start"] == nil then
		args["start"] = args._parent and args._parent.start or 1
	end
	assert(type(args["start"]) == "number")
	if args["finish"] == nil then
		args["finish"] = args._parent and args._parent.finish or 1
	end
	assert(type(args["finish"]) == "number")
	assert(type(args["block"]) == "table" and args["block"].type == "block")
	args["_parent"] = nil
	return args
end


---@class SelenScript.ASTNodes.else : SelenScript.ASTNodes.Node
---@field type "else"
---@field start SelenScript.ASTNodes.SrcPosition
---@field finish SelenScript.ASTNodes.SrcPosition
---@field block SelenScript.ASTNodes.block

---@param args {_parent:SelenScript.ASTNodes.Node?, start:SelenScript.ASTNodes.SrcPosition?, finish:SelenScript.ASTNodes.SrcPosition?, block:SelenScript.ASTNodes.block}
---@return SelenScript.ASTNodes.else
ASTNodes["else"] = function(args)
	args["source"] = args._parent and args._parent.source or nil
	args["type"] = "else"
	if args["start"] == nil then
		args["start"] = args._parent and args._parent.start or 1
	end
	assert(type(args["start"]) == "number")
	if args["finish"] == nil then
		args["finish"] = args._parent and args._parent.finish or 1
	end
	assert(type(args["finish"]) == "number")
	assert(type(args["block"]) == "table" and args["block"].type == "block")
	args["_parent"] = nil
	return args
end


---@class SelenScript.ASTNodes.elseif : SelenScript.ASTNodes.Node
---@field type "elseif"
---@field start SelenScript.ASTNodes.SrcPosition
---@field finish SelenScript.ASTNodes.SrcPosition
---@field block SelenScript.ASTNodes.block
---@field condition SelenScript.ASTNodes.expression
---@field else nil|SelenScript.ASTNodes.elseif|SelenScript.ASTNodes.else

---@param args {_parent:SelenScript.ASTNodes.Node?, start:SelenScript.ASTNodes.SrcPosition?, finish:SelenScript.ASTNodes.SrcPosition?, block:SelenScript.ASTNodes.block, condition:SelenScript.ASTNodes.expression, else:nil|SelenScript.ASTNodes.elseif|SelenScript.ASTNodes.else}
---@return SelenScript.ASTNodes.elseif
ASTNodes["elseif"] = function(args)
	args["source"] = args._parent and args._parent.source or nil
	args["type"] = "elseif"
	if args["start"] == nil then
		args["start"] = args._parent and args._parent.start or 1
	end
	assert(type(args["start"]) == "number")
	if args["finish"] == nil then
		args["finish"] = args._parent and args._parent.finish or 1
	end
	assert(type(args["finish"]) == "number")
	assert(type(args["block"]) == "table" and args["block"].type == "block")
	assert(type(args["condition"]) == "table" and (args["condition"].type == "mul" or args["condition"].type == "bit_and" or args["condition"].type == "add" or args["condition"].type == "concat" or args["condition"].type == "eq" or args["condition"].type == "bit_shift" or args["condition"].type == "exp" or args["condition"].type == "and" or args["condition"].type == "or" or args["condition"].type == "bit_or" or args["condition"].type == "bit_eor" or args["condition"].type == "len" or args["condition"].type == "neg" or args["condition"].type == "not" or args["condition"].type == "bit_not" or args["condition"].type == "ifexpr" or args["condition"].type == "stmt_expr" or args["condition"].type == "nil" or args["condition"].type == "boolean" or args["condition"].type == "var_args" or args["condition"].type == "numeral" or args["condition"].type == "string" or args["condition"].type == "function" or args["condition"].type == "index" or args["condition"].type == "table"))
	assert(args["else"] == nil or type(args["else"]) == "table" and (args["else"].type == "elseif" or args["else"].type == "else"))
	args["_parent"] = nil
	return args
end


---@class SelenScript.ASTNodes.eq : SelenScript.ASTNodes.Node
---@field type "eq"
---@field start SelenScript.ASTNodes.SrcPosition
---@field finish SelenScript.ASTNodes.SrcPosition
---@field lhs SelenScript.ASTNodes.expression
---@field op "<"|"<="|"=="|">"|">="|"~="
---@field rhs SelenScript.ASTNodes.expression

---@param args {_parent:SelenScript.ASTNodes.Node?, start:SelenScript.ASTNodes.SrcPosition?, finish:SelenScript.ASTNodes.SrcPosition?, lhs:SelenScript.ASTNodes.expression, op:"<"|"<="|"=="|">"|">="|"~=", rhs:SelenScript.ASTNodes.expression}
---@return SelenScript.ASTNodes.eq
ASTNodes["eq"] = function(args)
	args["source"] = args._parent and args._parent.source or nil
	args["type"] = "eq"
	if args["start"] == nil then
		args["start"] = args._parent and args._parent.start or 1
	end
	assert(type(args["start"]) == "number")
	if args["finish"] == nil then
		args["finish"] = args._parent and args._parent.finish or 1
	end
	assert(type(args["finish"]) == "number")
	assert(type(args["lhs"]) == "table" and (args["lhs"].type == "mul" or args["lhs"].type == "bit_and" or args["lhs"].type == "add" or args["lhs"].type == "concat" or args["lhs"].type == "eq" or args["lhs"].type == "bit_shift" or args["lhs"].type == "exp" or args["lhs"].type == "and" or args["lhs"].type == "or" or args["lhs"].type == "bit_or" or args["lhs"].type == "bit_eor" or args["lhs"].type == "len" or args["lhs"].type == "neg" or args["lhs"].type == "not" or args["lhs"].type == "bit_not" or args["lhs"].type == "ifexpr" or args["lhs"].type == "stmt_expr" or args["lhs"].type == "nil" or args["lhs"].type == "boolean" or args["lhs"].type == "var_args" or args["lhs"].type == "numeral" or args["lhs"].type == "string" or args["lhs"].type == "function" or args["lhs"].type == "index" or args["lhs"].type == "table"))
	assert(args["op"] == "<" or args["op"] == "<=" or args["op"] == "==" or args["op"] == ">" or args["op"] == ">=" or args["op"] == "~=")
	assert(type(args["rhs"]) == "table" and (args["rhs"].type == "mul" or args["rhs"].type == "bit_and" or args["rhs"].type == "add" or args["rhs"].type == "concat" or args["rhs"].type == "eq" or args["rhs"].type == "bit_shift" or args["rhs"].type == "exp" or args["rhs"].type == "and" or args["rhs"].type == "or" or args["rhs"].type == "bit_or" or args["rhs"].type == "bit_eor" or args["rhs"].type == "len" or args["rhs"].type == "neg" or args["rhs"].type == "not" or args["rhs"].type == "bit_not" or args["rhs"].type == "ifexpr" or args["rhs"].type == "stmt_expr" or args["rhs"].type == "nil" or args["rhs"].type == "boolean" or args["rhs"].type == "var_args" or args["rhs"].type == "numeral" or args["rhs"].type == "string" or args["rhs"].type == "function" or args["rhs"].type == "index" or args["rhs"].type == "table"))
	args["_parent"] = nil
	return args
end


---@class SelenScript.ASTNodes.exp : SelenScript.ASTNodes.Node
---@field type "exp"
---@field start SelenScript.ASTNodes.SrcPosition
---@field finish SelenScript.ASTNodes.SrcPosition
---@field lhs SelenScript.ASTNodes.expression
---@field op "^"
---@field rhs SelenScript.ASTNodes.expression

---@param args {_parent:SelenScript.ASTNodes.Node?, start:SelenScript.ASTNodes.SrcPosition?, finish:SelenScript.ASTNodes.SrcPosition?, lhs:SelenScript.ASTNodes.expression, rhs:SelenScript.ASTNodes.expression}
---@return SelenScript.ASTNodes.exp
ASTNodes["exp"] = function(args)
	args["source"] = args._parent and args._parent.source or nil
	args["type"] = "exp"
	if args["start"] == nil then
		args["start"] = args._parent and args._parent.start or 1
	end
	assert(type(args["start"]) == "number")
	if args["finish"] == nil then
		args["finish"] = args._parent and args._parent.finish or 1
	end
	assert(type(args["finish"]) == "number")
	assert(type(args["lhs"]) == "table" and (args["lhs"].type == "mul" or args["lhs"].type == "bit_and" or args["lhs"].type == "add" or args["lhs"].type == "concat" or args["lhs"].type == "eq" or args["lhs"].type == "bit_shift" or args["lhs"].type == "exp" or args["lhs"].type == "and" or args["lhs"].type == "or" or args["lhs"].type == "bit_or" or args["lhs"].type == "bit_eor" or args["lhs"].type == "len" or args["lhs"].type == "neg" or args["lhs"].type == "not" or args["lhs"].type == "bit_not" or args["lhs"].type == "ifexpr" or args["lhs"].type == "stmt_expr" or args["lhs"].type == "nil" or args["lhs"].type == "boolean" or args["lhs"].type == "var_args" or args["lhs"].type == "numeral" or args["lhs"].type == "string" or args["lhs"].type == "function" or args["lhs"].type == "index" or args["lhs"].type == "table"))
	args["op"] = "^"
	assert(type(args["rhs"]) == "table" and (args["rhs"].type == "mul" or args["rhs"].type == "bit_and" or args["rhs"].type == "add" or args["rhs"].type == "concat" or args["rhs"].type == "eq" or args["rhs"].type == "bit_shift" or args["rhs"].type == "exp" or args["rhs"].type == "and" or args["rhs"].type == "or" or args["rhs"].type == "bit_or" or args["rhs"].type == "bit_eor" or args["rhs"].type == "len" or args["rhs"].type == "neg" or args["rhs"].type == "not" or args["rhs"].type == "bit_not" or args["rhs"].type == "ifexpr" or args["rhs"].type == "stmt_expr" or args["rhs"].type == "nil" or args["rhs"].type == "boolean" or args["rhs"].type == "var_args" or args["rhs"].type == "numeral" or args["rhs"].type == "string" or args["rhs"].type == "function" or args["rhs"].type == "index" or args["rhs"].type == "table"))
	args["_parent"] = nil
	return args
end


---@class SelenScript.ASTNodes.expressionlist : SelenScript.ASTNodes.Node
---@field type "expressionlist"
---@field start SelenScript.ASTNodes.SrcPosition
---@field finish SelenScript.ASTNodes.SrcPosition
---@field [integer] SelenScript.ASTNodes.expression

---@param args {_parent:SelenScript.ASTNodes.Node?, start:SelenScript.ASTNodes.SrcPosition?, finish:SelenScript.ASTNodes.SrcPosition?, [integer]:SelenScript.ASTNodes.expression}
---@return SelenScript.ASTNodes.expressionlist
ASTNodes["expressionlist"] = function(args)
	args["source"] = args._parent and args._parent.source or nil
	args["type"] = "expressionlist"
	if args["start"] == nil then
		args["start"] = args._parent and args._parent.start or 1
	end
	assert(type(args["start"]) == "number")
	if args["finish"] == nil then
		args["finish"] = args._parent and args._parent.finish or 1
	end
	assert(type(args["finish"]) == "number")
	args["_parent"] = nil
	return args
end


---@class SelenScript.ASTNodes.field : SelenScript.ASTNodes.Node
---@field type "field"
---@field start SelenScript.ASTNodes.SrcPosition
---@field finish SelenScript.ASTNodes.SrcPosition
---@field key nil|SelenScript.ASTNodes.mul|SelenScript.ASTNodes.bit_and|SelenScript.ASTNodes.add|SelenScript.ASTNodes.concat|SelenScript.ASTNodes.eq|SelenScript.ASTNodes.bit_shift|SelenScript.ASTNodes.exp|SelenScript.ASTNodes.and|SelenScript.ASTNodes.or|SelenScript.ASTNodes.bit_or|SelenScript.ASTNodes.bit_eor|SelenScript.ASTNodes.len|SelenScript.ASTNodes.neg|SelenScript.ASTNodes.not|SelenScript.ASTNodes.bit_not|SelenScript.ASTNodes.ifexpr|SelenScript.ASTNodes.stmt_expr|SelenScript.ASTNodes.nil|SelenScript.ASTNodes.boolean|SelenScript.ASTNodes.var_args|SelenScript.ASTNodes.numeral|SelenScript.ASTNodes.string|SelenScript.ASTNodes.function|SelenScript.ASTNodes.index|SelenScript.ASTNodes.table|SelenScript.ASTNodes.name
---@field value SelenScript.ASTNodes.expression

---@param args {_parent:SelenScript.ASTNodes.Node?, start:SelenScript.ASTNodes.SrcPosition?, finish:SelenScript.ASTNodes.SrcPosition?, key:nil|SelenScript.ASTNodes.mul|SelenScript.ASTNodes.bit_and|SelenScript.ASTNodes.add|SelenScript.ASTNodes.concat|SelenScript.ASTNodes.eq|SelenScript.ASTNodes.bit_shift|SelenScript.ASTNodes.exp|SelenScript.ASTNodes.and|SelenScript.ASTNodes.or|SelenScript.ASTNodes.bit_or|SelenScript.ASTNodes.bit_eor|SelenScript.ASTNodes.len|SelenScript.ASTNodes.neg|SelenScript.ASTNodes.not|SelenScript.ASTNodes.bit_not|SelenScript.ASTNodes.ifexpr|SelenScript.ASTNodes.stmt_expr|SelenScript.ASTNodes.nil|SelenScript.ASTNodes.boolean|SelenScript.ASTNodes.var_args|SelenScript.ASTNodes.numeral|SelenScript.ASTNodes.string|SelenScript.ASTNodes.function|SelenScript.ASTNodes.index|SelenScript.ASTNodes.table|SelenScript.ASTNodes.name, value:SelenScript.ASTNodes.expression}
---@return SelenScript.ASTNodes.field
ASTNodes["field"] = function(args)
	args["source"] = args._parent and args._parent.source or nil
	args["type"] = "field"
	if args["start"] == nil then
		args["start"] = args._parent and args._parent.start or 1
	end
	assert(type(args["start"]) == "number")
	if args["finish"] == nil then
		args["finish"] = args._parent and args._parent.finish or 1
	end
	assert(type(args["finish"]) == "number")
	assert(args["key"] == nil or type(args["key"]) == "table" and (args["key"].type == "mul" or args["key"].type == "bit_and" or args["key"].type == "add" or args["key"].type == "concat" or args["key"].type == "eq" or args["key"].type == "bit_shift" or args["key"].type == "exp" or args["key"].type == "and" or args["key"].type == "or" or args["key"].type == "bit_or" or args["key"].type == "bit_eor" or args["key"].type == "len" or args["key"].type == "neg" or args["key"].type == "not" or args["key"].type == "bit_not" or args["key"].type == "ifexpr" or args["key"].type == "stmt_expr" or args["key"].type == "nil" or args["key"].type == "boolean" or args["key"].type == "var_args" or args["key"].type == "numeral" or args["key"].type == "string" or args["key"].type == "function" or args["key"].type == "index" or args["key"].type == "table" or args["key"].type == "name"))
	assert(type(args["value"]) == "table" and (args["value"].type == "mul" or args["value"].type == "bit_and" or args["value"].type == "add" or args["value"].type == "concat" or args["value"].type == "eq" or args["value"].type == "bit_shift" or args["value"].type == "exp" or args["value"].type == "and" or args["value"].type == "or" or args["value"].type == "bit_or" or args["value"].type == "bit_eor" or args["value"].type == "len" or args["value"].type == "neg" or args["value"].type == "not" or args["value"].type == "bit_not" or args["value"].type == "ifexpr" or args["value"].type == "stmt_expr" or args["value"].type == "nil" or args["value"].type == "boolean" or args["value"].type == "var_args" or args["value"].type == "numeral" or args["value"].type == "string" or args["value"].type == "function" or args["value"].type == "index" or args["value"].type == "table"))
	args["_parent"] = nil
	return args
end


---@class SelenScript.ASTNodes.fieldlist : SelenScript.ASTNodes.Node
---@field type "fieldlist"
---@field start SelenScript.ASTNodes.SrcPosition
---@field finish SelenScript.ASTNodes.SrcPosition
---@field [integer] SelenScript.ASTNodes.field?

---@param args {_parent:SelenScript.ASTNodes.Node?, start:SelenScript.ASTNodes.SrcPosition?, finish:SelenScript.ASTNodes.SrcPosition?, [integer]:SelenScript.ASTNodes.field?}
---@return SelenScript.ASTNodes.fieldlist
ASTNodes["fieldlist"] = function(args)
	args["source"] = args._parent and args._parent.source or nil
	args["type"] = "fieldlist"
	if args["start"] == nil then
		args["start"] = args._parent and args._parent.start or 1
	end
	assert(type(args["start"]) == "number")
	if args["finish"] == nil then
		args["finish"] = args._parent and args._parent.finish or 1
	end
	assert(type(args["finish"]) == "number")
	args["_parent"] = nil
	return args
end


---@class SelenScript.ASTNodes.foriter : SelenScript.ASTNodes.Node
---@field type "foriter"
---@field start SelenScript.ASTNodes.SrcPosition
---@field finish SelenScript.ASTNodes.SrcPosition
---@field block SelenScript.ASTNodes.block
---@field namelist SelenScript.ASTNodes.namelist
---@field values SelenScript.ASTNodes.expressionlist

---@param args {_parent:SelenScript.ASTNodes.Node?, start:SelenScript.ASTNodes.SrcPosition?, finish:SelenScript.ASTNodes.SrcPosition?, block:SelenScript.ASTNodes.block, namelist:SelenScript.ASTNodes.namelist, values:SelenScript.ASTNodes.expressionlist}
---@return SelenScript.ASTNodes.foriter
ASTNodes["foriter"] = function(args)
	args["source"] = args._parent and args._parent.source or nil
	args["type"] = "foriter"
	if args["start"] == nil then
		args["start"] = args._parent and args._parent.start or 1
	end
	assert(type(args["start"]) == "number")
	if args["finish"] == nil then
		args["finish"] = args._parent and args._parent.finish or 1
	end
	assert(type(args["finish"]) == "number")
	assert(type(args["block"]) == "table" and args["block"].type == "block")
	assert(type(args["namelist"]) == "table" and args["namelist"].type == "namelist")
	assert(type(args["values"]) == "table" and args["values"].type == "expressionlist")
	args["_parent"] = nil
	return args
end


---@class SelenScript.ASTNodes.forrange : SelenScript.ASTNodes.Node
---@field type "forrange"
---@field start SelenScript.ASTNodes.SrcPosition
---@field finish SelenScript.ASTNodes.SrcPosition
---@field block SelenScript.ASTNodes.block
---@field increment SelenScript.ASTNodes.expression
---@field name SelenScript.ASTNodes.name
---@field value_finish SelenScript.ASTNodes.expression
---@field value_start SelenScript.ASTNodes.expression

---@param args {_parent:SelenScript.ASTNodes.Node?, start:SelenScript.ASTNodes.SrcPosition?, finish:SelenScript.ASTNodes.SrcPosition?, block:SelenScript.ASTNodes.block, increment:SelenScript.ASTNodes.expression, name:SelenScript.ASTNodes.name, value_finish:SelenScript.ASTNodes.expression, value_start:SelenScript.ASTNodes.expression}
---@return SelenScript.ASTNodes.forrange
ASTNodes["forrange"] = function(args)
	args["source"] = args._parent and args._parent.source or nil
	args["type"] = "forrange"
	if args["start"] == nil then
		args["start"] = args._parent and args._parent.start or 1
	end
	assert(type(args["start"]) == "number")
	if args["finish"] == nil then
		args["finish"] = args._parent and args._parent.finish or 1
	end
	assert(type(args["finish"]) == "number")
	assert(type(args["block"]) == "table" and args["block"].type == "block")
	assert(args["increment"] == nil or type(args["increment"]) == "table" and (args["increment"].type == "mul" or args["increment"].type == "bit_and" or args["increment"].type == "add" or args["increment"].type == "concat" or args["increment"].type == "eq" or args["increment"].type == "bit_shift" or args["increment"].type == "exp" or args["increment"].type == "and" or args["increment"].type == "or" or args["increment"].type == "bit_or" or args["increment"].type == "bit_eor" or args["increment"].type == "len" or args["increment"].type == "neg" or args["increment"].type == "not" or args["increment"].type == "bit_not" or args["increment"].type == "ifexpr" or args["increment"].type == "stmt_expr" or args["increment"].type == "nil" or args["increment"].type == "boolean" or args["increment"].type == "var_args" or args["increment"].type == "numeral" or args["increment"].type == "string" or args["increment"].type == "function" or args["increment"].type == "index" or args["increment"].type == "table"))
	assert(type(args["name"]) == "table" and args["name"].type == "name")
	assert(type(args["value_finish"]) == "table" and (args["value_finish"].type == "mul" or args["value_finish"].type == "bit_and" or args["value_finish"].type == "add" or args["value_finish"].type == "concat" or args["value_finish"].type == "eq" or args["value_finish"].type == "bit_shift" or args["value_finish"].type == "exp" or args["value_finish"].type == "and" or args["value_finish"].type == "or" or args["value_finish"].type == "bit_or" or args["value_finish"].type == "bit_eor" or args["value_finish"].type == "len" or args["value_finish"].type == "neg" or args["value_finish"].type == "not" or args["value_finish"].type == "bit_not" or args["value_finish"].type == "ifexpr" or args["value_finish"].type == "stmt_expr" or args["value_finish"].type == "nil" or args["value_finish"].type == "boolean" or args["value_finish"].type == "var_args" or args["value_finish"].type == "numeral" or args["value_finish"].type == "string" or args["value_finish"].type == "function" or args["value_finish"].type == "index" or args["value_finish"].type == "table"))
	assert(type(args["value_start"]) == "table" and (args["value_start"].type == "mul" or args["value_start"].type == "bit_and" or args["value_start"].type == "add" or args["value_start"].type == "concat" or args["value_start"].type == "eq" or args["value_start"].type == "bit_shift" or args["value_start"].type == "exp" or args["value_start"].type == "and" or args["value_start"].type == "or" or args["value_start"].type == "bit_or" or args["value_start"].type == "bit_eor" or args["value_start"].type == "len" or args["value_start"].type == "neg" or args["value_start"].type == "not" or args["value_start"].type == "bit_not" or args["value_start"].type == "ifexpr" or args["value_start"].type == "stmt_expr" or args["value_start"].type == "nil" or args["value_start"].type == "boolean" or args["value_start"].type == "var_args" or args["value_start"].type == "numeral" or args["value_start"].type == "string" or args["value_start"].type == "function" or args["value_start"].type == "index" or args["value_start"].type == "table"))
	args["_parent"] = nil
	return args
end


---@class SelenScript.ASTNodes.funcbody : SelenScript.ASTNodes.Node
---@field type "funcbody"
---@field start SelenScript.ASTNodes.SrcPosition
---@field finish SelenScript.ASTNodes.SrcPosition
---@field args SelenScript.ASTNodes.parlist
---@field block SelenScript.ASTNodes.block

---@param args {_parent:SelenScript.ASTNodes.Node?, start:SelenScript.ASTNodes.SrcPosition?, finish:SelenScript.ASTNodes.SrcPosition?, args:SelenScript.ASTNodes.parlist, block:SelenScript.ASTNodes.block}
---@return SelenScript.ASTNodes.funcbody
ASTNodes["funcbody"] = function(args)
	args["source"] = args._parent and args._parent.source or nil
	args["type"] = "funcbody"
	if args["start"] == nil then
		args["start"] = args._parent and args._parent.start or 1
	end
	assert(type(args["start"]) == "number")
	if args["finish"] == nil then
		args["finish"] = args._parent and args._parent.finish or 1
	end
	assert(type(args["finish"]) == "number")
	assert(type(args["args"]) == "table" and args["args"].type == "parlist")
	assert(type(args["block"]) == "table" and args["block"].type == "block")
	args["_parent"] = nil
	return args
end


---@class SelenScript.ASTNodes.function : SelenScript.ASTNodes.Node
---@field type "function"
---@field start SelenScript.ASTNodes.SrcPosition
---@field finish SelenScript.ASTNodes.SrcPosition
---@field funcbody SelenScript.ASTNodes.funcbody

---@param args {_parent:SelenScript.ASTNodes.Node?, start:SelenScript.ASTNodes.SrcPosition?, finish:SelenScript.ASTNodes.SrcPosition?, funcbody:SelenScript.ASTNodes.funcbody}
---@return SelenScript.ASTNodes.function
ASTNodes["function"] = function(args)
	args["source"] = args._parent and args._parent.source or nil
	args["type"] = "function"
	if args["start"] == nil then
		args["start"] = args._parent and args._parent.start or 1
	end
	assert(type(args["start"]) == "number")
	if args["finish"] == nil then
		args["finish"] = args._parent and args._parent.finish or 1
	end
	assert(type(args["finish"]) == "number")
	assert(type(args["funcbody"]) == "table" and args["funcbody"].type == "funcbody")
	args["_parent"] = nil
	return args
end


---@class SelenScript.ASTNodes.functiondef : SelenScript.ASTNodes.Node
---@field type "functiondef"
---@field start SelenScript.ASTNodes.SrcPosition
---@field finish SelenScript.ASTNodes.SrcPosition
---@field decorators SelenScript.ASTNodes.decorator_list?
---@field funcbody SelenScript.ASTNodes.funcbody
---@field name SelenScript.ASTNodes.name|SelenScript.ASTNodes.index
---@field scope "local"|"default"

---@param args {_parent:SelenScript.ASTNodes.Node?, start:SelenScript.ASTNodes.SrcPosition?, finish:SelenScript.ASTNodes.SrcPosition?, decorators:SelenScript.ASTNodes.decorator_list?, funcbody:SelenScript.ASTNodes.funcbody, name:SelenScript.ASTNodes.name|SelenScript.ASTNodes.index, scope:"local"|"default"}
---@return SelenScript.ASTNodes.functiondef
ASTNodes["functiondef"] = function(args)
	args["source"] = args._parent and args._parent.source or nil
	args["type"] = "functiondef"
	if args["start"] == nil then
		args["start"] = args._parent and args._parent.start or 1
	end
	assert(type(args["start"]) == "number")
	if args["finish"] == nil then
		args["finish"] = args._parent and args._parent.finish or 1
	end
	assert(type(args["finish"]) == "number")
	assert(args["decorators"] == nil or type(args["decorators"]) == "table" and args["decorators"].type == "decorator_list")
	assert(type(args["funcbody"]) == "table" and args["funcbody"].type == "funcbody")
	assert(type(args["name"]) == "table" and (args["name"].type == "name" or args["name"].type == "index"))
	assert(args["scope"] == "local" or args["scope"] == "default")
	args["_parent"] = nil
	return args
end


---@class SelenScript.ASTNodes.goto : SelenScript.ASTNodes.Node
---@field type "goto"
---@field start SelenScript.ASTNodes.SrcPosition
---@field finish SelenScript.ASTNodes.SrcPosition
---@field name SelenScript.ASTNodes.name

---@param args {_parent:SelenScript.ASTNodes.Node?, start:SelenScript.ASTNodes.SrcPosition?, finish:SelenScript.ASTNodes.SrcPosition?, name:SelenScript.ASTNodes.name|string}
---@return SelenScript.ASTNodes.goto
ASTNodes["goto"] = function(args)
	args["source"] = args._parent and args._parent.source or nil
	args["type"] = "goto"
	if args["start"] == nil then
		args["start"] = args._parent and args._parent.start or 1
	end
	assert(type(args["start"]) == "number")
	if args["finish"] == nil then
		args["finish"] = args._parent and args._parent.finish or 1
	end
	assert(type(args["finish"]) == "number")
	if type(args["name"]) == "string" then
		args["name"] = ASTNodes[("name")]({
			_parent = args,
			name = args["name"],
		})
	end
	assert(type(args["name"]) == "table" and args["name"].type == "name")
	args["_parent"] = nil
	return args
end


---@class SelenScript.ASTNodes.if : SelenScript.ASTNodes.Node
---@field type "if"
---@field start SelenScript.ASTNodes.SrcPosition
---@field finish SelenScript.ASTNodes.SrcPosition
---@field block SelenScript.ASTNodes.block
---@field condition SelenScript.ASTNodes.expression
---@field else nil|SelenScript.ASTNodes.elseif|SelenScript.ASTNodes.else

---@param args {_parent:SelenScript.ASTNodes.Node?, start:SelenScript.ASTNodes.SrcPosition?, finish:SelenScript.ASTNodes.SrcPosition?, block:SelenScript.ASTNodes.block, condition:SelenScript.ASTNodes.expression, else:nil|SelenScript.ASTNodes.elseif|SelenScript.ASTNodes.else}
---@return SelenScript.ASTNodes.if
ASTNodes["if"] = function(args)
	args["source"] = args._parent and args._parent.source or nil
	args["type"] = "if"
	if args["start"] == nil then
		args["start"] = args._parent and args._parent.start or 1
	end
	assert(type(args["start"]) == "number")
	if args["finish"] == nil then
		args["finish"] = args._parent and args._parent.finish or 1
	end
	assert(type(args["finish"]) == "number")
	assert(type(args["block"]) == "table" and args["block"].type == "block")
	assert(type(args["condition"]) == "table" and (args["condition"].type == "mul" or args["condition"].type == "bit_and" or args["condition"].type == "add" or args["condition"].type == "concat" or args["condition"].type == "eq" or args["condition"].type == "bit_shift" or args["condition"].type == "exp" or args["condition"].type == "and" or args["condition"].type == "or" or args["condition"].type == "bit_or" or args["condition"].type == "bit_eor" or args["condition"].type == "len" or args["condition"].type == "neg" or args["condition"].type == "not" or args["condition"].type == "bit_not" or args["condition"].type == "ifexpr" or args["condition"].type == "stmt_expr" or args["condition"].type == "nil" or args["condition"].type == "boolean" or args["condition"].type == "var_args" or args["condition"].type == "numeral" or args["condition"].type == "string" or args["condition"].type == "function" or args["condition"].type == "index" or args["condition"].type == "table"))
	assert(args["else"] == nil or type(args["else"]) == "table" and (args["else"].type == "elseif" or args["else"].type == "else"))
	args["_parent"] = nil
	return args
end


---@class SelenScript.ASTNodes.ifexpr : SelenScript.ASTNodes.Node
---@field type "ifexpr"
---@field start SelenScript.ASTNodes.SrcPosition
---@field finish SelenScript.ASTNodes.SrcPosition
---@field condition SelenScript.ASTNodes.expression
---@field lhs SelenScript.ASTNodes.expression
---@field rhs SelenScript.ASTNodes.expression

---@param args {_parent:SelenScript.ASTNodes.Node?, start:SelenScript.ASTNodes.SrcPosition?, finish:SelenScript.ASTNodes.SrcPosition?, condition:SelenScript.ASTNodes.expression, lhs:SelenScript.ASTNodes.expression, rhs:SelenScript.ASTNodes.expression}
---@return SelenScript.ASTNodes.ifexpr
ASTNodes["ifexpr"] = function(args)
	args["source"] = args._parent and args._parent.source or nil
	args["type"] = "ifexpr"
	if args["start"] == nil then
		args["start"] = args._parent and args._parent.start or 1
	end
	assert(type(args["start"]) == "number")
	if args["finish"] == nil then
		args["finish"] = args._parent and args._parent.finish or 1
	end
	assert(type(args["finish"]) == "number")
	assert(type(args["condition"]) == "table" and (args["condition"].type == "mul" or args["condition"].type == "bit_and" or args["condition"].type == "add" or args["condition"].type == "concat" or args["condition"].type == "eq" or args["condition"].type == "bit_shift" or args["condition"].type == "exp" or args["condition"].type == "and" or args["condition"].type == "or" or args["condition"].type == "bit_or" or args["condition"].type == "bit_eor" or args["condition"].type == "len" or args["condition"].type == "neg" or args["condition"].type == "not" or args["condition"].type == "bit_not" or args["condition"].type == "ifexpr" or args["condition"].type == "stmt_expr" or args["condition"].type == "nil" or args["condition"].type == "boolean" or args["condition"].type == "var_args" or args["condition"].type == "numeral" or args["condition"].type == "string" or args["condition"].type == "function" or args["condition"].type == "index" or args["condition"].type == "table"))
	assert(type(args["lhs"]) == "table" and (args["lhs"].type == "mul" or args["lhs"].type == "bit_and" or args["lhs"].type == "add" or args["lhs"].type == "concat" or args["lhs"].type == "eq" or args["lhs"].type == "bit_shift" or args["lhs"].type == "exp" or args["lhs"].type == "and" or args["lhs"].type == "or" or args["lhs"].type == "bit_or" or args["lhs"].type == "bit_eor" or args["lhs"].type == "len" or args["lhs"].type == "neg" or args["lhs"].type == "not" or args["lhs"].type == "bit_not" or args["lhs"].type == "ifexpr" or args["lhs"].type == "stmt_expr" or args["lhs"].type == "nil" or args["lhs"].type == "boolean" or args["lhs"].type == "var_args" or args["lhs"].type == "numeral" or args["lhs"].type == "string" or args["lhs"].type == "function" or args["lhs"].type == "index" or args["lhs"].type == "table"))
	assert(type(args["rhs"]) == "table" and (args["rhs"].type == "mul" or args["rhs"].type == "bit_and" or args["rhs"].type == "add" or args["rhs"].type == "concat" or args["rhs"].type == "eq" or args["rhs"].type == "bit_shift" or args["rhs"].type == "exp" or args["rhs"].type == "and" or args["rhs"].type == "or" or args["rhs"].type == "bit_or" or args["rhs"].type == "bit_eor" or args["rhs"].type == "len" or args["rhs"].type == "neg" or args["rhs"].type == "not" or args["rhs"].type == "bit_not" or args["rhs"].type == "ifexpr" or args["rhs"].type == "stmt_expr" or args["rhs"].type == "nil" or args["rhs"].type == "boolean" or args["rhs"].type == "var_args" or args["rhs"].type == "numeral" or args["rhs"].type == "string" or args["rhs"].type == "function" or args["rhs"].type == "index" or args["rhs"].type == "table"))
	args["_parent"] = nil
	return args
end


---@class SelenScript.ASTNodes.index : SelenScript.ASTNodes.Node
---@field type "index"
---@field start SelenScript.ASTNodes.SrcPosition
---@field finish SelenScript.ASTNodes.SrcPosition
---@field braces "("?
---@field expr SelenScript.ASTNodes.name|SelenScript.ASTNodes.mul|SelenScript.ASTNodes.bit_and|SelenScript.ASTNodes.add|SelenScript.ASTNodes.concat|SelenScript.ASTNodes.eq|SelenScript.ASTNodes.bit_shift|SelenScript.ASTNodes.exp|SelenScript.ASTNodes.and|SelenScript.ASTNodes.or|SelenScript.ASTNodes.bit_or|SelenScript.ASTNodes.bit_eor|SelenScript.ASTNodes.len|SelenScript.ASTNodes.neg|SelenScript.ASTNodes.not|SelenScript.ASTNodes.bit_not|SelenScript.ASTNodes.ifexpr|SelenScript.ASTNodes.stmt_expr|SelenScript.ASTNodes.nil|SelenScript.ASTNodes.boolean|SelenScript.ASTNodes.var_args|SelenScript.ASTNodes.numeral|SelenScript.ASTNodes.string|SelenScript.ASTNodes.function|SelenScript.ASTNodes.index|SelenScript.ASTNodes.table|SelenScript.ASTNodes.call
---@field how nil|":"|"."|"["
---@field index nil|SelenScript.ASTNodes.call|SelenScript.ASTNodes.index

---@param args {_parent:SelenScript.ASTNodes.Node?, start:SelenScript.ASTNodes.SrcPosition?, finish:SelenScript.ASTNodes.SrcPosition?, braces:"("?, expr:SelenScript.ASTNodes.name|SelenScript.ASTNodes.mul|SelenScript.ASTNodes.bit_and|SelenScript.ASTNodes.add|SelenScript.ASTNodes.concat|SelenScript.ASTNodes.eq|SelenScript.ASTNodes.bit_shift|SelenScript.ASTNodes.exp|SelenScript.ASTNodes.and|SelenScript.ASTNodes.or|SelenScript.ASTNodes.bit_or|SelenScript.ASTNodes.bit_eor|SelenScript.ASTNodes.len|SelenScript.ASTNodes.neg|SelenScript.ASTNodes.not|SelenScript.ASTNodes.bit_not|SelenScript.ASTNodes.ifexpr|SelenScript.ASTNodes.stmt_expr|SelenScript.ASTNodes.nil|SelenScript.ASTNodes.boolean|SelenScript.ASTNodes.var_args|SelenScript.ASTNodes.numeral|SelenScript.ASTNodes.string|SelenScript.ASTNodes.function|SelenScript.ASTNodes.index|SelenScript.ASTNodes.table|SelenScript.ASTNodes.call, how:nil|":"|"."|"[", index:nil|SelenScript.ASTNodes.call|SelenScript.ASTNodes.index}
---@return SelenScript.ASTNodes.index
ASTNodes["index"] = function(args)
	args["source"] = args._parent and args._parent.source or nil
	args["type"] = "index"
	if args["start"] == nil then
		args["start"] = args._parent and args._parent.start or 1
	end
	assert(type(args["start"]) == "number")
	if args["finish"] == nil then
		args["finish"] = args._parent and args._parent.finish or 1
	end
	assert(type(args["finish"]) == "number")
	assert(args["braces"] == nil or args["braces"] == "(")
	assert(type(args["expr"]) == "table" and (args["expr"].type == "name" or args["expr"].type == "mul" or args["expr"].type == "bit_and" or args["expr"].type == "add" or args["expr"].type == "concat" or args["expr"].type == "eq" or args["expr"].type == "bit_shift" or args["expr"].type == "exp" or args["expr"].type == "and" or args["expr"].type == "or" or args["expr"].type == "bit_or" or args["expr"].type == "bit_eor" or args["expr"].type == "len" or args["expr"].type == "neg" or args["expr"].type == "not" or args["expr"].type == "bit_not" or args["expr"].type == "ifexpr" or args["expr"].type == "stmt_expr" or args["expr"].type == "nil" or args["expr"].type == "boolean" or args["expr"].type == "var_args" or args["expr"].type == "numeral" or args["expr"].type == "string" or args["expr"].type == "function" or args["expr"].type == "index" or args["expr"].type == "table" or args["expr"].type == "call"))
	assert(args["how"] == nil or args["how"] == ":" or args["how"] == "." or args["how"] == "[")
	assert(args["index"] == nil or type(args["index"]) == "table" and (args["index"].type == "call" or args["index"].type == "index"))
	args["_parent"] = nil
	return args
end


---@class SelenScript.ASTNodes.label : SelenScript.ASTNodes.Node
---@field type "label"
---@field start SelenScript.ASTNodes.SrcPosition
---@field finish SelenScript.ASTNodes.SrcPosition
---@field name SelenScript.ASTNodes.name

---@param args {_parent:SelenScript.ASTNodes.Node?, start:SelenScript.ASTNodes.SrcPosition?, finish:SelenScript.ASTNodes.SrcPosition?, name:SelenScript.ASTNodes.name|string}
---@return SelenScript.ASTNodes.label
ASTNodes["label"] = function(args)
	args["source"] = args._parent and args._parent.source or nil
	args["type"] = "label"
	if args["start"] == nil then
		args["start"] = args._parent and args._parent.start or 1
	end
	assert(type(args["start"]) == "number")
	if args["finish"] == nil then
		args["finish"] = args._parent and args._parent.finish or 1
	end
	assert(type(args["finish"]) == "number")
	if type(args["name"]) == "string" then
		args["name"] = ASTNodes[("name")]({
			_parent = args,
			name = args["name"],
		})
	end
	assert(type(args["name"]) == "table" and args["name"].type == "name")
	args["_parent"] = nil
	return args
end


---@class SelenScript.ASTNodes.len : SelenScript.ASTNodes.Node
---@field type "len"
---@field start SelenScript.ASTNodes.SrcPosition
---@field finish SelenScript.ASTNodes.SrcPosition
---@field op "#"
---@field rhs SelenScript.ASTNodes.expression

---@param args {_parent:SelenScript.ASTNodes.Node?, start:SelenScript.ASTNodes.SrcPosition?, finish:SelenScript.ASTNodes.SrcPosition?, rhs:SelenScript.ASTNodes.expression}
---@return SelenScript.ASTNodes.len
ASTNodes["len"] = function(args)
	args["source"] = args._parent and args._parent.source or nil
	args["type"] = "len"
	if args["start"] == nil then
		args["start"] = args._parent and args._parent.start or 1
	end
	assert(type(args["start"]) == "number")
	if args["finish"] == nil then
		args["finish"] = args._parent and args._parent.finish or 1
	end
	assert(type(args["finish"]) == "number")
	args["op"] = "#"
	assert(type(args["rhs"]) == "table" and (args["rhs"].type == "mul" or args["rhs"].type == "bit_and" or args["rhs"].type == "add" or args["rhs"].type == "concat" or args["rhs"].type == "eq" or args["rhs"].type == "bit_shift" or args["rhs"].type == "exp" or args["rhs"].type == "and" or args["rhs"].type == "or" or args["rhs"].type == "bit_or" or args["rhs"].type == "bit_eor" or args["rhs"].type == "len" or args["rhs"].type == "neg" or args["rhs"].type == "not" or args["rhs"].type == "bit_not" or args["rhs"].type == "ifexpr" or args["rhs"].type == "stmt_expr" or args["rhs"].type == "nil" or args["rhs"].type == "boolean" or args["rhs"].type == "var_args" or args["rhs"].type == "numeral" or args["rhs"].type == "string" or args["rhs"].type == "function" or args["rhs"].type == "index" or args["rhs"].type == "table"))
	args["_parent"] = nil
	return args
end


---@class SelenScript.ASTNodes.mul : SelenScript.ASTNodes.Node
---@field type "mul"
---@field start SelenScript.ASTNodes.SrcPosition
---@field finish SelenScript.ASTNodes.SrcPosition
---@field lhs SelenScript.ASTNodes.expression
---@field op "%"|"*"|"/"|"//"
---@field rhs SelenScript.ASTNodes.expression

---@param args {_parent:SelenScript.ASTNodes.Node?, start:SelenScript.ASTNodes.SrcPosition?, finish:SelenScript.ASTNodes.SrcPosition?, lhs:SelenScript.ASTNodes.expression, op:"%"|"*"|"/"|"//", rhs:SelenScript.ASTNodes.expression}
---@return SelenScript.ASTNodes.mul
ASTNodes["mul"] = function(args)
	args["source"] = args._parent and args._parent.source or nil
	args["type"] = "mul"
	if args["start"] == nil then
		args["start"] = args._parent and args._parent.start or 1
	end
	assert(type(args["start"]) == "number")
	if args["finish"] == nil then
		args["finish"] = args._parent and args._parent.finish or 1
	end
	assert(type(args["finish"]) == "number")
	assert(type(args["lhs"]) == "table" and (args["lhs"].type == "mul" or args["lhs"].type == "bit_and" or args["lhs"].type == "add" or args["lhs"].type == "concat" or args["lhs"].type == "eq" or args["lhs"].type == "bit_shift" or args["lhs"].type == "exp" or args["lhs"].type == "and" or args["lhs"].type == "or" or args["lhs"].type == "bit_or" or args["lhs"].type == "bit_eor" or args["lhs"].type == "len" or args["lhs"].type == "neg" or args["lhs"].type == "not" or args["lhs"].type == "bit_not" or args["lhs"].type == "ifexpr" or args["lhs"].type == "stmt_expr" or args["lhs"].type == "nil" or args["lhs"].type == "boolean" or args["lhs"].type == "var_args" or args["lhs"].type == "numeral" or args["lhs"].type == "string" or args["lhs"].type == "function" or args["lhs"].type == "index" or args["lhs"].type == "table"))
	assert(args["op"] == "%" or args["op"] == "*" or args["op"] == "/" or args["op"] == "//")
	assert(type(args["rhs"]) == "table" and (args["rhs"].type == "mul" or args["rhs"].type == "bit_and" or args["rhs"].type == "add" or args["rhs"].type == "concat" or args["rhs"].type == "eq" or args["rhs"].type == "bit_shift" or args["rhs"].type == "exp" or args["rhs"].type == "and" or args["rhs"].type == "or" or args["rhs"].type == "bit_or" or args["rhs"].type == "bit_eor" or args["rhs"].type == "len" or args["rhs"].type == "neg" or args["rhs"].type == "not" or args["rhs"].type == "bit_not" or args["rhs"].type == "ifexpr" or args["rhs"].type == "stmt_expr" or args["rhs"].type == "nil" or args["rhs"].type == "boolean" or args["rhs"].type == "var_args" or args["rhs"].type == "numeral" or args["rhs"].type == "string" or args["rhs"].type == "function" or args["rhs"].type == "index" or args["rhs"].type == "table"))
	args["_parent"] = nil
	return args
end


---@class SelenScript.ASTNodes.name : SelenScript.ASTNodes.Node
---@field type "name"
---@field start SelenScript.ASTNodes.SrcPosition
---@field finish SelenScript.ASTNodes.SrcPosition
---@field name string|"B"|"C"|"D"|"E"|"F"|"G"|"H"|"I"|"J"|"K"|"L"|"M"|"N"|"O"|"P"|"Q"|"R"|"S"|"T"|"U"|"V"|"W"|"X"|"Y"|"Z"|"_"|"a"|"b"|"c"|"d"|"e"|"f"|"g"|"h"|"i"|"j"|"k"|"l"|"m"|"n"|"o"|"p"|"q"|"r"|"s"|"t"|"u"|"v"|"w"|"x"|"y"|"z"|"0"|"1"|"2"|"3"|"4"|"5"|"6"|"7"|"8"|"9"|"and"|"not"|"or"|"then"|"do"|"in"|"end"|"break"|"goto"|"else"|"elseif"|"if"|"for"|"function"|"repeat"|"until"|"while"|"return"|"local"|"nil"|"true"|"false"

---@param args {_parent:SelenScript.ASTNodes.Node?, start:SelenScript.ASTNodes.SrcPosition?, finish:SelenScript.ASTNodes.SrcPosition?, name:string|"B"|"C"|"D"|"E"|"F"|"G"|"H"|"I"|"J"|"K"|"L"|"M"|"N"|"O"|"P"|"Q"|"R"|"S"|"T"|"U"|"V"|"W"|"X"|"Y"|"Z"|"_"|"a"|"b"|"c"|"d"|"e"|"f"|"g"|"h"|"i"|"j"|"k"|"l"|"m"|"n"|"o"|"p"|"q"|"r"|"s"|"t"|"u"|"v"|"w"|"x"|"y"|"z"|"0"|"1"|"2"|"3"|"4"|"5"|"6"|"7"|"8"|"9"|"and"|"not"|"or"|"then"|"do"|"in"|"end"|"break"|"goto"|"else"|"elseif"|"if"|"for"|"function"|"repeat"|"until"|"while"|"return"|"local"|"nil"|"true"|"false"}
---@return SelenScript.ASTNodes.name
ASTNodes["name"] = function(args)
	args["source"] = args._parent and args._parent.source or nil
	args["type"] = "name"
	if args["start"] == nil then
		args["start"] = args._parent and args._parent.start or 1
	end
	assert(type(args["start"]) == "number")
	if args["finish"] == nil then
		args["finish"] = args._parent and args._parent.finish or 1
	end
	assert(type(args["finish"]) == "number")
	assert(args["name"])
	args["_parent"] = nil
	return args
end


---@class SelenScript.ASTNodes.namelist : SelenScript.ASTNodes.Node
---@field type "namelist"
---@field start SelenScript.ASTNodes.SrcPosition
---@field finish SelenScript.ASTNodes.SrcPosition
---@field [integer] SelenScript.ASTNodes.name?

---@param args {_parent:SelenScript.ASTNodes.Node?, start:SelenScript.ASTNodes.SrcPosition?, finish:SelenScript.ASTNodes.SrcPosition?, [integer]:SelenScript.ASTNodes.name?}
---@return SelenScript.ASTNodes.namelist
ASTNodes["namelist"] = function(args)
	args["source"] = args._parent and args._parent.source or nil
	args["type"] = "namelist"
	if args["start"] == nil then
		args["start"] = args._parent and args._parent.start or 1
	end
	assert(type(args["start"]) == "number")
	if args["finish"] == nil then
		args["finish"] = args._parent and args._parent.finish or 1
	end
	assert(type(args["finish"]) == "number")
	args["_parent"] = nil
	return args
end


---@class SelenScript.ASTNodes.neg : SelenScript.ASTNodes.Node
---@field type "neg"
---@field start SelenScript.ASTNodes.SrcPosition
---@field finish SelenScript.ASTNodes.SrcPosition
---@field op "-"
---@field rhs SelenScript.ASTNodes.expression

---@param args {_parent:SelenScript.ASTNodes.Node?, start:SelenScript.ASTNodes.SrcPosition?, finish:SelenScript.ASTNodes.SrcPosition?, rhs:SelenScript.ASTNodes.expression}
---@return SelenScript.ASTNodes.neg
ASTNodes["neg"] = function(args)
	args["source"] = args._parent and args._parent.source or nil
	args["type"] = "neg"
	if args["start"] == nil then
		args["start"] = args._parent and args._parent.start or 1
	end
	assert(type(args["start"]) == "number")
	if args["finish"] == nil then
		args["finish"] = args._parent and args._parent.finish or 1
	end
	assert(type(args["finish"]) == "number")
	args["op"] = "-"
	assert(type(args["rhs"]) == "table" and (args["rhs"].type == "mul" or args["rhs"].type == "bit_and" or args["rhs"].type == "add" or args["rhs"].type == "concat" or args["rhs"].type == "eq" or args["rhs"].type == "bit_shift" or args["rhs"].type == "exp" or args["rhs"].type == "and" or args["rhs"].type == "or" or args["rhs"].type == "bit_or" or args["rhs"].type == "bit_eor" or args["rhs"].type == "len" or args["rhs"].type == "neg" or args["rhs"].type == "not" or args["rhs"].type == "bit_not" or args["rhs"].type == "ifexpr" or args["rhs"].type == "stmt_expr" or args["rhs"].type == "nil" or args["rhs"].type == "boolean" or args["rhs"].type == "var_args" or args["rhs"].type == "numeral" or args["rhs"].type == "string" or args["rhs"].type == "function" or args["rhs"].type == "index" or args["rhs"].type == "table"))
	args["_parent"] = nil
	return args
end


---@class SelenScript.ASTNodes.nil : SelenScript.ASTNodes.Node
---@field type "nil"
---@field start SelenScript.ASTNodes.SrcPosition
---@field finish SelenScript.ASTNodes.SrcPosition
---@field value "nil"

---@param args {_parent:SelenScript.ASTNodes.Node?, start:SelenScript.ASTNodes.SrcPosition?, finish:SelenScript.ASTNodes.SrcPosition?}
---@return SelenScript.ASTNodes.nil
ASTNodes["nil"] = function(args)
	args["source"] = args._parent and args._parent.source or nil
	args["type"] = "nil"
	if args["start"] == nil then
		args["start"] = args._parent and args._parent.start or 1
	end
	assert(type(args["start"]) == "number")
	if args["finish"] == nil then
		args["finish"] = args._parent and args._parent.finish or 1
	end
	assert(type(args["finish"]) == "number")
	args["value"] = "nil"
	args["_parent"] = nil
	return args
end


---@class SelenScript.ASTNodes.not : SelenScript.ASTNodes.Node
---@field type "not"
---@field start SelenScript.ASTNodes.SrcPosition
---@field finish SelenScript.ASTNodes.SrcPosition
---@field op "not"
---@field rhs SelenScript.ASTNodes.expression

---@param args {_parent:SelenScript.ASTNodes.Node?, start:SelenScript.ASTNodes.SrcPosition?, finish:SelenScript.ASTNodes.SrcPosition?, rhs:SelenScript.ASTNodes.expression}
---@return SelenScript.ASTNodes.not
ASTNodes["not"] = function(args)
	args["source"] = args._parent and args._parent.source or nil
	args["type"] = "not"
	if args["start"] == nil then
		args["start"] = args._parent and args._parent.start or 1
	end
	assert(type(args["start"]) == "number")
	if args["finish"] == nil then
		args["finish"] = args._parent and args._parent.finish or 1
	end
	assert(type(args["finish"]) == "number")
	args["op"] = "not"
	assert(type(args["rhs"]) == "table" and (args["rhs"].type == "mul" or args["rhs"].type == "bit_and" or args["rhs"].type == "add" or args["rhs"].type == "concat" or args["rhs"].type == "eq" or args["rhs"].type == "bit_shift" or args["rhs"].type == "exp" or args["rhs"].type == "and" or args["rhs"].type == "or" or args["rhs"].type == "bit_or" or args["rhs"].type == "bit_eor" or args["rhs"].type == "len" or args["rhs"].type == "neg" or args["rhs"].type == "not" or args["rhs"].type == "bit_not" or args["rhs"].type == "ifexpr" or args["rhs"].type == "stmt_expr" or args["rhs"].type == "nil" or args["rhs"].type == "boolean" or args["rhs"].type == "var_args" or args["rhs"].type == "numeral" or args["rhs"].type == "string" or args["rhs"].type == "function" or args["rhs"].type == "index" or args["rhs"].type == "table"))
	args["_parent"] = nil
	return args
end


---@class SelenScript.ASTNodes.numeral : SelenScript.ASTNodes.Node
---@field type "numeral"
---@field start SelenScript.ASTNodes.SrcPosition
---@field finish SelenScript.ASTNodes.SrcPosition
---@field value string

---@param args {_parent:SelenScript.ASTNodes.Node?, start:SelenScript.ASTNodes.SrcPosition?, finish:SelenScript.ASTNodes.SrcPosition?, value:string}
---@return SelenScript.ASTNodes.numeral
ASTNodes["numeral"] = function(args)
	args["source"] = args._parent and args._parent.source or nil
	args["type"] = "numeral"
	if args["start"] == nil then
		args["start"] = args._parent and args._parent.start or 1
	end
	assert(type(args["start"]) == "number")
	if args["finish"] == nil then
		args["finish"] = args._parent and args._parent.finish or 1
	end
	assert(type(args["finish"]) == "number")
	assert(type(args["value"]) == "string")
	args["_parent"] = nil
	return args
end


---@class SelenScript.ASTNodes.op_assign : SelenScript.ASTNodes.Node
---@field type "op_assign"
---@field start SelenScript.ASTNodes.SrcPosition
---@field finish SelenScript.ASTNodes.SrcPosition
---@field names SelenScript.ASTNodes.varlist
---@field op "*"|"^"|"//"|"/"|"%"|"+"|"-"|"<<"|">>"|"&"|"~"|"|"
---@field values SelenScript.ASTNodes.expressionlist

---@param args {_parent:SelenScript.ASTNodes.Node?, start:SelenScript.ASTNodes.SrcPosition?, finish:SelenScript.ASTNodes.SrcPosition?, names:SelenScript.ASTNodes.varlist, op:"*"|"^"|"//"|"/"|"%"|"+"|"-"|"<<"|">>"|"&"|"~"|"|", values:SelenScript.ASTNodes.expressionlist}
---@return SelenScript.ASTNodes.op_assign
ASTNodes["op_assign"] = function(args)
	args["source"] = args._parent and args._parent.source or nil
	args["type"] = "op_assign"
	if args["start"] == nil then
		args["start"] = args._parent and args._parent.start or 1
	end
	assert(type(args["start"]) == "number")
	if args["finish"] == nil then
		args["finish"] = args._parent and args._parent.finish or 1
	end
	assert(type(args["finish"]) == "number")
	assert(type(args["names"]) == "table" and args["names"].type == "varlist")
	assert(args["op"] == "*" or args["op"] == "^" or args["op"] == "//" or args["op"] == "/" or args["op"] == "%" or args["op"] == "+" or args["op"] == "-" or args["op"] == "<<" or args["op"] == ">>" or args["op"] == "&" or args["op"] == "~" or args["op"] == "|")
	assert(type(args["values"]) == "table" and args["values"].type == "expressionlist")
	args["_parent"] = nil
	return args
end


---@class SelenScript.ASTNodes.or : SelenScript.ASTNodes.Node
---@field type "or"
---@field start SelenScript.ASTNodes.SrcPosition
---@field finish SelenScript.ASTNodes.SrcPosition
---@field lhs SelenScript.ASTNodes.expression
---@field op "or"
---@field rhs SelenScript.ASTNodes.expression

---@param args {_parent:SelenScript.ASTNodes.Node?, start:SelenScript.ASTNodes.SrcPosition?, finish:SelenScript.ASTNodes.SrcPosition?, lhs:SelenScript.ASTNodes.expression, rhs:SelenScript.ASTNodes.expression}
---@return SelenScript.ASTNodes.or
ASTNodes["or"] = function(args)
	args["source"] = args._parent and args._parent.source or nil
	args["type"] = "or"
	if args["start"] == nil then
		args["start"] = args._parent and args._parent.start or 1
	end
	assert(type(args["start"]) == "number")
	if args["finish"] == nil then
		args["finish"] = args._parent and args._parent.finish or 1
	end
	assert(type(args["finish"]) == "number")
	assert(type(args["lhs"]) == "table" and (args["lhs"].type == "mul" or args["lhs"].type == "bit_and" or args["lhs"].type == "add" or args["lhs"].type == "concat" or args["lhs"].type == "eq" or args["lhs"].type == "bit_shift" or args["lhs"].type == "exp" or args["lhs"].type == "and" or args["lhs"].type == "or" or args["lhs"].type == "bit_or" or args["lhs"].type == "bit_eor" or args["lhs"].type == "len" or args["lhs"].type == "neg" or args["lhs"].type == "not" or args["lhs"].type == "bit_not" or args["lhs"].type == "ifexpr" or args["lhs"].type == "stmt_expr" or args["lhs"].type == "nil" or args["lhs"].type == "boolean" or args["lhs"].type == "var_args" or args["lhs"].type == "numeral" or args["lhs"].type == "string" or args["lhs"].type == "function" or args["lhs"].type == "index" or args["lhs"].type == "table"))
	args["op"] = "or"
	assert(type(args["rhs"]) == "table" and (args["rhs"].type == "mul" or args["rhs"].type == "bit_and" or args["rhs"].type == "add" or args["rhs"].type == "concat" or args["rhs"].type == "eq" or args["rhs"].type == "bit_shift" or args["rhs"].type == "exp" or args["rhs"].type == "and" or args["rhs"].type == "or" or args["rhs"].type == "bit_or" or args["rhs"].type == "bit_eor" or args["rhs"].type == "len" or args["rhs"].type == "neg" or args["rhs"].type == "not" or args["rhs"].type == "bit_not" or args["rhs"].type == "ifexpr" or args["rhs"].type == "stmt_expr" or args["rhs"].type == "nil" or args["rhs"].type == "boolean" or args["rhs"].type == "var_args" or args["rhs"].type == "numeral" or args["rhs"].type == "string" or args["rhs"].type == "function" or args["rhs"].type == "index" or args["rhs"].type == "table"))
	args["_parent"] = nil
	return args
end


---@class SelenScript.ASTNodes.parlist : SelenScript.ASTNodes.Node
---@field type "parlist"
---@field start SelenScript.ASTNodes.SrcPosition
---@field finish SelenScript.ASTNodes.SrcPosition
---@field [integer] nil|SelenScript.ASTNodes.name|SelenScript.ASTNodes.var_args

---@param args {_parent:SelenScript.ASTNodes.Node?, start:SelenScript.ASTNodes.SrcPosition?, finish:SelenScript.ASTNodes.SrcPosition?, [integer]:nil|SelenScript.ASTNodes.name|SelenScript.ASTNodes.var_args}
---@return SelenScript.ASTNodes.parlist
ASTNodes["parlist"] = function(args)
	args["source"] = args._parent and args._parent.source or nil
	args["type"] = "parlist"
	if args["start"] == nil then
		args["start"] = args._parent and args._parent.start or 1
	end
	assert(type(args["start"]) == "number")
	if args["finish"] == nil then
		args["finish"] = args._parent and args._parent.finish or 1
	end
	assert(type(args["finish"]) == "number")
	args["_parent"] = nil
	return args
end


---@class SelenScript.ASTNodes.repeat : SelenScript.ASTNodes.Node
---@field type "repeat"
---@field start SelenScript.ASTNodes.SrcPosition
---@field finish SelenScript.ASTNodes.SrcPosition
---@field block SelenScript.ASTNodes.block
---@field expr SelenScript.ASTNodes.expression

---@param args {_parent:SelenScript.ASTNodes.Node?, start:SelenScript.ASTNodes.SrcPosition?, finish:SelenScript.ASTNodes.SrcPosition?, block:SelenScript.ASTNodes.block, expr:SelenScript.ASTNodes.expression}
---@return SelenScript.ASTNodes.repeat
ASTNodes["repeat"] = function(args)
	args["source"] = args._parent and args._parent.source or nil
	args["type"] = "repeat"
	if args["start"] == nil then
		args["start"] = args._parent and args._parent.start or 1
	end
	assert(type(args["start"]) == "number")
	if args["finish"] == nil then
		args["finish"] = args._parent and args._parent.finish or 1
	end
	assert(type(args["finish"]) == "number")
	assert(type(args["block"]) == "table" and args["block"].type == "block")
	assert(type(args["expr"]) == "table" and (args["expr"].type == "mul" or args["expr"].type == "bit_and" or args["expr"].type == "add" or args["expr"].type == "concat" or args["expr"].type == "eq" or args["expr"].type == "bit_shift" or args["expr"].type == "exp" or args["expr"].type == "and" or args["expr"].type == "or" or args["expr"].type == "bit_or" or args["expr"].type == "bit_eor" or args["expr"].type == "len" or args["expr"].type == "neg" or args["expr"].type == "not" or args["expr"].type == "bit_not" or args["expr"].type == "ifexpr" or args["expr"].type == "stmt_expr" or args["expr"].type == "nil" or args["expr"].type == "boolean" or args["expr"].type == "var_args" or args["expr"].type == "numeral" or args["expr"].type == "string" or args["expr"].type == "function" or args["expr"].type == "index" or args["expr"].type == "table"))
	args["_parent"] = nil
	return args
end


---@class SelenScript.ASTNodes.return : SelenScript.ASTNodes.Node
---@field type "return"
---@field start SelenScript.ASTNodes.SrcPosition
---@field finish SelenScript.ASTNodes.SrcPosition
---@field values SelenScript.ASTNodes.expressionlist

---@param args {_parent:SelenScript.ASTNodes.Node?, start:SelenScript.ASTNodes.SrcPosition?, finish:SelenScript.ASTNodes.SrcPosition?, values:SelenScript.ASTNodes.expressionlist}
---@return SelenScript.ASTNodes.return
ASTNodes["return"] = function(args)
	args["source"] = args._parent and args._parent.source or nil
	args["type"] = "return"
	if args["start"] == nil then
		args["start"] = args._parent and args._parent.start or 1
	end
	assert(type(args["start"]) == "number")
	if args["finish"] == nil then
		args["finish"] = args._parent and args._parent.finish or 1
	end
	assert(type(args["finish"]) == "number")
	assert(type(args["values"]) == "table" and args["values"].type == "expressionlist")
	args["_parent"] = nil
	return args
end


---@class SelenScript.ASTNodes.stmt_expr : SelenScript.ASTNodes.Node
---@field type "stmt_expr"
---@field start SelenScript.ASTNodes.SrcPosition
---@field finish SelenScript.ASTNodes.SrcPosition
---@field stmt SelenScript.ASTNodes.while|SelenScript.ASTNodes.do|SelenScript.ASTNodes.forrange|SelenScript.ASTNodes.foriter

---@param args {_parent:SelenScript.ASTNodes.Node?, start:SelenScript.ASTNodes.SrcPosition?, finish:SelenScript.ASTNodes.SrcPosition?, stmt:SelenScript.ASTNodes.while|SelenScript.ASTNodes.do|SelenScript.ASTNodes.forrange|SelenScript.ASTNodes.foriter}
---@return SelenScript.ASTNodes.stmt_expr
ASTNodes["stmt_expr"] = function(args)
	args["source"] = args._parent and args._parent.source or nil
	args["type"] = "stmt_expr"
	if args["start"] == nil then
		args["start"] = args._parent and args._parent.start or 1
	end
	assert(type(args["start"]) == "number")
	if args["finish"] == nil then
		args["finish"] = args._parent and args._parent.finish or 1
	end
	assert(type(args["finish"]) == "number")
	assert(type(args["stmt"]) == "table" and (args["stmt"].type == "while" or args["stmt"].type == "do" or args["stmt"].type == "forrange" or args["stmt"].type == "foriter"))
	args["_parent"] = nil
	return args
end


---@class SelenScript.ASTNodes.string : SelenScript.ASTNodes.Node
---@field type "string"
---@field start SelenScript.ASTNodes.SrcPosition
---@field finish SelenScript.ASTNodes.SrcPosition
---@field prefix string
---@field suffix string
---@field value string|"\\"|string|string

---@param args {_parent:SelenScript.ASTNodes.Node?, start:SelenScript.ASTNodes.SrcPosition?, finish:SelenScript.ASTNodes.SrcPosition?, prefix:string?, suffix:string?, value:string|"\\"|string|string}
---@return SelenScript.ASTNodes.string
ASTNodes["string"] = function(args)
	args["source"] = args._parent and args._parent.source or nil
	args["type"] = "string"
	if args["start"] == nil then
		args["start"] = args._parent and args._parent.start or 1
	end
	assert(type(args["start"]) == "number")
	if args["finish"] == nil then
		args["finish"] = args._parent and args._parent.finish or 1
	end
	assert(type(args["finish"]) == "number")
	if args["prefix"] == nil and type(args["value"]) == "string" then
		args["prefix"] = "\""
		if args[("value")]:find(args["prefix"]) then
			args["prefix"] = "'"
		end
		if args[("value")]:find(args["prefix"]) then
			args["prefix"] = "[["
		end
		local i = 1
		while args[("value")]:find(Utils.escape_pattern(args["prefix"])) do
			args["prefix"] = "[" .. string.rep("=", i) .. "["
			i = i + 1
		end
	end
	assert(type(args["prefix"]) == "string")
	if args["suffix"] == nil then
		if args[("prefix")]:match("%[=*%[") then
			args["suffix"] = args[("prefix")]:gsub("%[", "%]")
		else
			args["suffix"] = args["prefix"]
		end
	end
	assert(type(args["suffix"]) == "string")
	assert(args["value"])
	args["_parent"] = nil
	return args
end


---@class SelenScript.ASTNodes.table : SelenScript.ASTNodes.Node
---@field type "table"
---@field start SelenScript.ASTNodes.SrcPosition
---@field finish SelenScript.ASTNodes.SrcPosition
---@field fields SelenScript.ASTNodes.fieldlist

---@param args {_parent:SelenScript.ASTNodes.Node?, start:SelenScript.ASTNodes.SrcPosition?, finish:SelenScript.ASTNodes.SrcPosition?, fields:SelenScript.ASTNodes.fieldlist}
---@return SelenScript.ASTNodes.table
ASTNodes["table"] = function(args)
	args["source"] = args._parent and args._parent.source or nil
	args["type"] = "table"
	if args["start"] == nil then
		args["start"] = args._parent and args._parent.start or 1
	end
	assert(type(args["start"]) == "number")
	if args["finish"] == nil then
		args["finish"] = args._parent and args._parent.finish or 1
	end
	assert(type(args["finish"]) == "number")
	assert(type(args["fields"]) == "table" and args["fields"].type == "fieldlist")
	args["_parent"] = nil
	return args
end


---@class SelenScript.ASTNodes.unary_op : SelenScript.ASTNodes.Node
---@field type "unary_op"
---@field start SelenScript.ASTNodes.SrcPosition
---@field finish SelenScript.ASTNodes.SrcPosition
---@field op "-"|"not"|"#"|"~"

---@param args {_parent:SelenScript.ASTNodes.Node?, start:SelenScript.ASTNodes.SrcPosition?, finish:SelenScript.ASTNodes.SrcPosition?, op:"-"|"not"|"#"|"~"}
---@return SelenScript.ASTNodes.unary_op
ASTNodes["unary_op"] = function(args)
	args["source"] = args._parent and args._parent.source or nil
	args["type"] = "unary_op"
	if args["start"] == nil then
		args["start"] = args._parent and args._parent.start or 1
	end
	assert(type(args["start"]) == "number")
	if args["finish"] == nil then
		args["finish"] = args._parent and args._parent.finish or 1
	end
	assert(type(args["finish"]) == "number")
	assert(args["op"] == "-" or args["op"] == "not" or args["op"] == "#" or args["op"] == "~")
	args["_parent"] = nil
	return args
end


---@class SelenScript.ASTNodes.var_args : SelenScript.ASTNodes.Node
---@field type "var_args"
---@field start SelenScript.ASTNodes.SrcPosition
---@field finish SelenScript.ASTNodes.SrcPosition
---@field value "..."

---@param args {_parent:SelenScript.ASTNodes.Node?, start:SelenScript.ASTNodes.SrcPosition?, finish:SelenScript.ASTNodes.SrcPosition?}
---@return SelenScript.ASTNodes.var_args
ASTNodes["var_args"] = function(args)
	args["source"] = args._parent and args._parent.source or nil
	args["type"] = "var_args"
	if args["start"] == nil then
		args["start"] = args._parent and args._parent.start or 1
	end
	assert(type(args["start"]) == "number")
	if args["finish"] == nil then
		args["finish"] = args._parent and args._parent.finish or 1
	end
	assert(type(args["finish"]) == "number")
	args["value"] = "..."
	args["_parent"] = nil
	return args
end


---@class SelenScript.ASTNodes.varlist : SelenScript.ASTNodes.Node
---@field type "varlist"
---@field start SelenScript.ASTNodes.SrcPosition
---@field finish SelenScript.ASTNodes.SrcPosition
---@field [integer] SelenScript.ASTNodes.index?

---@param args {_parent:SelenScript.ASTNodes.Node?, start:SelenScript.ASTNodes.SrcPosition?, finish:SelenScript.ASTNodes.SrcPosition?, [integer]:SelenScript.ASTNodes.index?}
---@return SelenScript.ASTNodes.varlist
ASTNodes["varlist"] = function(args)
	args["source"] = args._parent and args._parent.source or nil
	args["type"] = "varlist"
	if args["start"] == nil then
		args["start"] = args._parent and args._parent.start or 1
	end
	assert(type(args["start"]) == "number")
	if args["finish"] == nil then
		args["finish"] = args._parent and args._parent.finish or 1
	end
	assert(type(args["finish"]) == "number")
	args["_parent"] = nil
	return args
end


---@class SelenScript.ASTNodes.while : SelenScript.ASTNodes.Node
---@field type "while"
---@field start SelenScript.ASTNodes.SrcPosition
---@field finish SelenScript.ASTNodes.SrcPosition
---@field block SelenScript.ASTNodes.block
---@field expr SelenScript.ASTNodes.expression

---@param args {_parent:SelenScript.ASTNodes.Node?, start:SelenScript.ASTNodes.SrcPosition?, finish:SelenScript.ASTNodes.SrcPosition?, block:SelenScript.ASTNodes.block, expr:SelenScript.ASTNodes.expression}
---@return SelenScript.ASTNodes.while
ASTNodes["while"] = function(args)
	args["source"] = args._parent and args._parent.source or nil
	args["type"] = "while"
	if args["start"] == nil then
		args["start"] = args._parent and args._parent.start or 1
	end
	assert(type(args["start"]) == "number")
	if args["finish"] == nil then
		args["finish"] = args._parent and args._parent.finish or 1
	end
	assert(type(args["finish"]) == "number")
	assert(type(args["block"]) == "table" and args["block"].type == "block")
	assert(type(args["expr"]) == "table" and (args["expr"].type == "mul" or args["expr"].type == "bit_and" or args["expr"].type == "add" or args["expr"].type == "concat" or args["expr"].type == "eq" or args["expr"].type == "bit_shift" or args["expr"].type == "exp" or args["expr"].type == "and" or args["expr"].type == "or" or args["expr"].type == "bit_or" or args["expr"].type == "bit_eor" or args["expr"].type == "len" or args["expr"].type == "neg" or args["expr"].type == "not" or args["expr"].type == "bit_not" or args["expr"].type == "ifexpr" or args["expr"].type == "stmt_expr" or args["expr"].type == "nil" or args["expr"].type == "boolean" or args["expr"].type == "var_args" or args["expr"].type == "numeral" or args["expr"].type == "string" or args["expr"].type == "function" or args["expr"].type == "index" or args["expr"].type == "table"))
	args["_parent"] = nil
	return args
end


return ASTNodes
