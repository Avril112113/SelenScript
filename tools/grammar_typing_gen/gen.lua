-- Command: luajit ./tools/grammar_typing_gen/gen.lua
-- See note in lpeg_ptree.lua
-- This script is quite messy, but it works for SelenScript.


package.path = "?/init.lua;libs/?.lua;libs/?/init.lua;libs/?/?.lua;" .. package.path
package.cpath = "libs/" .. _VERSION:sub(5) .. "/?.dll;libs/?.dll;" .. package.cpath


require "logging".windows_enable_ansi()
local LPegPTree = require "tools.grammar_typing_gen.lpeg_ptree"
local GrammarInfo = require "tools.grammar_typing_gen.lpeg_grammar_info"
local Utils = require "SelenScript.utils"
local Parser = require "SelenScript.parser.parser"
local Emitter = require "SelenScript.emitter.emitter"
local ASTNodes = require "SelenScript.parser.ast_nodes"
local Precedence = require "SelenScript.parser.precedence"


-- os.execute("luajit ./tools/grammar_typing_gen/print_ptree.lua > ./tools/grammar_typing_gen/grammar.ptree.txt")


local TESTING_RULE_NAME = nil
local TESTING_NODE_NAME = nil

local ENABLE_HELPER_ASSERTIONS = true


---@param name string
---@param default SelenScript.ASTNodes.expression
---@return SelenScript.ASTNodes.or
local function _default_parent_or(name, default)
	return ASTNodes["or"]{
		lhs = ASTNodes["and"]{
			lhs = ASTNodes.index{
				expr = ASTNodes.name{name="args"},
				index = ASTNodes.index{
					how = ".",
					expr = ASTNodes.name{name="_parent"},
				}
			},
			rhs = ASTNodes.index{
				expr = ASTNodes.name{name="args"},
				index = ASTNodes.index{
					how = ".",
					expr = ASTNodes.name{name="_parent"},
					index = ASTNodes.index{
						how = ".",
						expr = ASTNodes.name{name=name},
					}
				}
			},
		},
		rhs = default,
	}
end

-- args._parent and args._parent.start or 1

local HELPER_FIELD_DEFAULTS = {
	start = _default_parent_or("start", ASTNodes.numeral{value="1"}),
	finish = _default_parent_or("finish", ASTNodes.numeral{value="1"}),
}

-- Fields are done in alphadetical order.
-- Order can be overridden with `OVERRIDE_FIELD_ORDER`
local HELPER_CUSTOM_CODE = {
	["string"] = {
		---@param field_info ASTNodeInfo.TypeInfo
		["prefix"] = function(field_info)
			field_info.optional = true
			return [[
				if args["prefix"] == nil and type(args["value"]) == "string" then
					args["prefix"] = "\""
					if args["value"]:find(args["prefix"]) then
						args["prefix"] = "'"
					end
					if args["value"]:find(args["prefix"]) then
						args["prefix"] = "[["
					end
					local i = 1
					while args["value"]:find(Utils.escape_pattern(args["prefix"])) do
						args["prefix"] = "[" .. string.rep("=", i) .. "["
						i = i + 1
					end
				end
			]]
		end,
		---@param field_info ASTNodeInfo.TypeInfo
		["suffix"] = function(field_info)
			field_info.optional = true
			return [[
				if args["suffix"] == nil then
					if args["prefix"]:match("%[=*%[") then
						args["suffix"] = args["prefix"]:gsub("%[", "%]")
					else
						args["suffix"] = args["prefix"]
					end
				end
			]]
		end,
	},
	["label"]={
		---@param field_info ASTNodeInfo.TypeInfo
		["name"] = function(field_info)
			table.insert(field_info.types, "string")
			return [[
				if type(args["name"]) == "string" then
					args["name"] = ASTNodes["name"]{
						_parent = args,
						name = args["name"],
					}
				end
			]]
		end,
	},
	["goto"]={
		---@param field_info ASTNodeInfo.TypeInfo
		["name"] = function(field_info)
			table.insert(field_info.types, "string")
			return [[
				if type(args["name"]) == "string" then
					args["name"] = ASTNodes["name"]{
						_parent = args,
						name = args["name"],
					}
				end
			]]
		end,
	},
	["assign"]={
		---@param field_info ASTNodeInfo.TypeInfo
		["values"] = function(field_info)
			field_info.optional = true
			return [[
				if args["values"] == nil then
					args["values"] = ASTNodes["expressionlist"]{
						_parent = args,
					}
				end
			]]
		end,
		---@param field_info ASTNodeInfo.TypeInfo
		["scope"] = function(field_info)
			field_info.optional = true
			return [[
				if args["scope"] == nil then
					args["scope"] = "default"
				end
			]]
		end,
	},
	["attributename"]={
		---@param field_info ASTNodeInfo.TypeInfo
		["name"] = function(field_info)
			table.insert(field_info.types, "string")
			return [[
				if type(args["name"]) == "string" then
					args["name"] = ASTNodes["name"]{
						_parent = args,
						name = args["name"],
					}
				end
			]]
		end,
		---@param field_info ASTNodeInfo.TypeInfo
		["attribute"] = function(field_info)
			table.insert(field_info.types, "string")
			return [[
				if type(args["attribute"]) == "string" then
					args["attribute"] = ASTNodes["attribute"]{
						_parent = args,
						value = args["attribute"],
					}
				end
			]]
		end,
	},
}

local OVERRIDE_FIELD_ORDER = {
	["type"] = 1,
	["start"] = 2,
	["finish"] = 3,
}

---@param field ASTNodeInfo.TypeInfo
---@param astnode ASTNodeInfo
local function remove_literal_string_types(field, astnode)
	for i=#field.types,1,-1 do
		local v = field.types[i]
		if type(v) == "string" and v:find("^[\"'].*[\"']$") then
			table.remove(field.types, i)
		end
	end
end
-- Script isn't perfect, it's just a LOT easier to manually fix it for the cases it struggles.
local OVERRIDE_FIELD_TYPES = {
	["LineComment"] = {
		prefix = {types={"string"}, optional=false},
		value = {types={"string"}, optional=false},
	},
	["LongComment"] = {
		prefix = {types={"string", "\"--[[\""}, optional=false},
		suffix = {types={"string", "\"]]\"", "\"--]]\""}, optional=false},
	},
	["string"] = {
		prefix = "string",
		suffix = "string",
		value = {types={"string"}, optional=false},
	},
	["name"] = {
		name = {types={"string"}, optional=false},
	},
	["call"] = {
		args = remove_literal_string_types,
	},
	["chunk"] = {
		hashline = "string",
	},
	["index"] = {
		braces = {optional=true},
	},
}


local OVERRIDE_EMPTY_RULES = {
	["Sc"]=true,
}


local grammar_tree = LPegPTree.new(Utils.readFile("./tools/grammar_typing_gen/grammar.ptree.txt"))

local s = grammar_tree:tostring()
Utils.writeFile("./tools/grammar_typing_gen/gen.grammar.ptree.txt", s)


--- With changes for debugging stuff here.
---@param value any
---@param parts string[]?
---@param depth integer?
---@param has_done table<any,true>?
local function tostring_value(value, parts, depth, has_done)
	parts = parts or {}
	has_done = has_done or {}
	if type(value) == "string" then
		local quote_mark = "\""
		value = value:gsub("\n", "\\n"):gsub("\r", "\\r"):gsub("\t", "\\t")
		if value:find("\"") then
			if value:find("'") then
				value = value:gsub("\"", "\\\"")
			else
				quote_mark = "'"
			end
		end
		table.insert(parts, ("%s%s%s"):format(quote_mark, value, quote_mark))
	elseif type(value) == "table" and depth ~= -1 then
		if value.__name == "rule" and depth ~= nil then
			table.insert(parts, ("<RULE '%s'>"):format(value.name))
		elseif has_done[value] then
			table.insert(parts, "<RECURSIVE>")
		else
			has_done[value] = true
			depth = depth or 0
			table.insert(parts, "{\n")
			for i, v in Utils.sorted_pairs(value) do
				table.insert(parts, string.rep("    ", depth+1))
				tostring_value(i, parts, -1, has_done)
				table.insert(parts, " = ")
				tostring_value(v, parts, depth+1, has_done)
				table.insert(parts, ",\n")
			end
			table.insert(parts, string.rep("    ", depth) .. "}")
		end
	else
		table.insert(parts, tostring(value))
	end
	return parts
end

local climbPrecedence_captures = {}
---@type SelenScript.GrammarTools.GrammarInfo.CaptureContext
local climbPrecedence_cap = {
	__name = "capctx",
	captures = climbPrecedence_captures,
	fields = {},
	mode = "/",
}
-- Filled in later to have rule `value` in it
---@type SelenScript.GrammarTools.GrammarInfo.CaptureContext
local _value_cap = {
	__name = "capctx",
	captures = {},
	fields = {},
}

for op, data in Utils.sorted_pairs(Precedence.binaryOpData) do
	---@type SelenScript.GrammarTools.GrammarInfo.TableCapture
	local cap = {
		__name = "table",
		captures = {},
		fields = {
			type = { __name = "string", value = data[2] },
			start = { __name = "position" },
			finish = { __name = "position" },
			lhs = _value_cap,
			op = { __name = "string", value = op },
			rhs = _value_cap,
		},
	}
	table.insert(climbPrecedence_captures, cap)
end
for op, data in Utils.sorted_pairs(Precedence.unaryOpData) do
	---@type SelenScript.GrammarTools.GrammarInfo.TableCapture
	local cap = {
		__name = "table",
		captures = {},
		fields = {
			type = { __name = "string", value = data[2] },
			start = { __name = "position" },
			finish = { __name = "position" },
			op = { __name = "string", value = op },
			rhs = _value_cap,
		},
	}
	table.insert(climbPrecedence_captures, cap)
end

local grammar_info = GrammarInfo.new(grammar_tree, {
	-- If false, it is COMPLETLEY ignored, including the args passed to it.
	add_error = false,
	add_error_o = false,
	climbPrecedence = climbPrecedence_cap,
}, OVERRIDE_EMPTY_RULES)

---@param node SelenScript.GrammarTools.GrammarInfo.CaptureContext
local function remove_literl_strings(node)
	local to_remove = {}
	for i, v in ipairs(node.captures) do
		if v.__name == "string" then
			---@cast v SelenScript.GrammarTools.GrammarInfo.StringCapture
			table.insert(to_remove, i)
		elseif v.__name == "capctx" or v.__name == "table" then
			---@cast v SelenScript.GrammarTools.GrammarInfo.CaptureContext
			remove_literl_strings(v)
		end
	end
	for i=#to_remove,1,-1 do
		table.remove(node.captures, to_remove[i])
	end
end
remove_literl_strings(grammar_info.rules["value"])

_value_cap.captures[1] = {
	__name = "capctx",
	captures = grammar_info.rules["expression"].captures,
	fields = {},
}

if TESTING_RULE_NAME then
	print(table.concat(tostring_value(grammar_info.rules[TESTING_RULE_NAME]), ""))
end


--------------------------------------------------------------------------------------

-- Just a big spacer, as we are moving to another part of this script.
-- Just makes it easier to navigate.

--------------------------------------------------------------------------------------


---@param tblcap SelenScript.GrammarTools.GrammarInfo.TableCapture
local function get_tablecap_name(tblcap)
	local name_field_cap = tblcap.fields["type"] and tblcap.fields["type"].__name == "string" and tblcap.fields["type"]
	---@cast name_field_cap SelenScript.GrammarTools.GrammarInfo.StringCapture|false
	local name
	if name_field_cap then
		name = name_field_cap.value
	elseif next(tblcap.fields) then
		-- Only complain if it has any fields.
		-- If it doesn't it's very likely we don't care about it, as it's not a node.
		-- This check is only needed due to table captures used for function calls within the grammar.
		name = ("UNKNOWN_TYPE_%p"):format(tblcap)
		print("Unable to obtain field 'type' from table capture:\n" .. table.concat(tostring_value(tblcap), ""))
	end
	return name
end
---@alias ASTNodeInfo {name:string, fields:table<string,ASTNodeInfo.TypeInfo>}
---@alias ASTNodeInfo.TypeInfo {types:(string|ASTNodeInfo.TypeInfo)[],optional:boolean}
---@type table<string,ASTNodeInfo>
local astnodes = {}
---@param cap SelenScript.GrammarTools.GrammarInfo.CaptureBase
---@param astnode_info ASTNodeInfo
---@param unique_optional boolean  # Makes any unique field optional (applies both to existing and currently processing)
---@param current_field_name string|integer?
---@param processed table?
---@param add_field_cb fun(name:string, info:ASTNodeInfo.TypeInfo)?
---@param written_fields table<string,true>?
local function process_table_recur(cap, astnode_info, unique_optional, current_field_name, processed, add_field_cb, written_fields)
	-- TODO: If we encounder the same astnode again, any types that aren't present in both occurences need to be made optional.

	written_fields = written_fields or {}
	processed = processed or {}
	if processed[cap] then
		return written_fields
	end
	processed[cap] = true

	---@param field_name string|integer
	local function get_field_type(field_name)
		if type(field_name) == "number" then
			field_name = "[integer]"
		end
		---@cast field_name string
		---@type ASTNodeInfo.TypeInfo
		local field_info = astnode_info.fields[field_name]
		if not field_info then
			---@type ASTNodeInfo.TypeInfo
			field_info = {
				types = {},
				optional = false,
			}
			astnode_info.fields[field_name] = field_info
			if unique_optional then
				field_info.optional = true
			end
		end
		return field_info, field_name
	end
	---@param typ string|ASTNodeInfo.TypeInfo
	local function add_field_type(typ)
		assert(current_field_name ~= nil)
		local field_type, field_name = get_field_type(current_field_name)
		if add_field_cb then
			add_field_cb(field_name, field_type)
		end
		written_fields[field_name] = true
		for i, v in pairs(field_type.types) do
			if v == typ then
				return field_type
			end
		end
		table.insert(field_type.types, typ)
		return field_type
	end
	---@param cap SelenScript.GrammarTools.GrammarInfo.CaptureContext
	---@param inherit boolean
	---@param _add_field_cb fun(name:string, info:ASTNodeInfo.TypeInfo)?
	local function recur(cap, inherit, _add_field_cb)
		_add_field_cb = _add_field_cb or (inherit and add_field_cb) or nil
		local _written_fields = inherit and written_fields or {}
		for i, v in ipairs(cap.captures) do
			process_table_recur(v, astnode_info, unique_optional, inherit and current_field_name or i, inherit and processed or nil, _add_field_cb, _written_fields)
		end
		for i, v in Utils.sorted_pairs(cap.fields) do
			process_table_recur(v, astnode_info, unique_optional, i, inherit and processed or nil, _add_field_cb, _written_fields)
		end
		return _written_fields
	end

	if cap.__name == "table" then
		---@cast cap SelenScript.GrammarTools.GrammarInfo.TableCapture
		if current_field_name then
			-- NOTE: This expects all tables to be a ast node.
			local name = get_tablecap_name(cap)
			if name ~= nil then
				add_field_type(("SelenScript.ASTNodes.%s"):format(name))
			end
		else
			local _written_fields = recur(cap, false)
			if unique_optional then
				for i, v in pairs(astnode_info.fields) do
					if not _written_fields[i] then
						if not v.optional then
							v.optional = true
						end
					end
				end
			end
		end
	elseif cap.__name == "rule" then
		---@cast cap SelenScript.GrammarTools.GrammarInfo.Rule
		recur(cap, true)
	elseif cap.__name == "capctx" then
		---@cast cap SelenScript.GrammarTools.GrammarInfo.CaptureContext
		---@type fun(name:string, info:ASTNodeInfo.TypeInfo)?
		local _add_field_cb
		if cap.mode == "?" then
			_add_field_cb = function(name, info)
				info.optional = true
			end
		elseif cap.mode == "*" then
			_add_field_cb = function(name, info)
				info.optional = true
			end
		elseif cap.mode == "/" then
			-- :shrug:
			-- We could try compare all branches and set fields as optional or not from that.
		elseif cap.mode ~= nil then
			print("TODO: capctx mode " .. cap.mode)
		end
		recur(cap, true, _add_field_cb)
	elseif cap.__name == "position" then
		---@cast cap SelenScript.GrammarTools.GrammarInfo.PositionCapture
		add_field_type("SelenScript.ASTNodes.SrcPosition")
	elseif cap.__name == "constant" then
		---@cast cap SelenScript.GrammarTools.GrammarInfo.ConstantCapture
		add_field_type(table.concat(tostring_value(cap.value), ""))
	elseif cap.__name == "simple" then
		---@cast cap SelenScript.GrammarTools.GrammarInfo.FunctionCapture
		add_field_type("string")
	elseif cap.__name == "backref" then
		---@cast cap SelenScript.GrammarTools.GrammarInfo.BackrefCapture
		if type(current_field_name) == "string" then
			add_field_type(astnode_info.fields[cap.name])
		end
	elseif cap.__name == "string" then
		---@cast cap SelenScript.GrammarTools.GrammarInfo.StringCapture
		if type(current_field_name) == "string" then
			add_field_type(("%q"):format(cap.value))
		end
	elseif cap.__name == "set" then
		---@cast cap SelenScript.GrammarTools.GrammarInfo.SetCapture
		if type(current_field_name) == "string" then
			for _, v in ipairs(cap.values) do
				add_field_type(("%q"):format(v))
			end
		end
	elseif cap.__name == "any" then
		---@cast cap SelenScript.GrammarTools.GrammarInfo.AnyCapture
		if type(current_field_name) == "string" then
			add_field_type("string")
		end
	elseif cap.__name == "function" then
		---@cast cap SelenScript.GrammarTools.GrammarInfo.FunctionCapture
		-- Do nothing, these would have already been converted.
	else
		print(("Unhandled capture %s for field name %s"):format(table.concat(tostring_value(cap.__name), ""), table.concat(tostring_value(current_field_name), "")))
	end
end
---@param tblcap SelenScript.GrammarTools.GrammarInfo.TableCapture
local function process_table(tblcap)
	assert(tblcap.__name == "table")

	local name = get_tablecap_name(tblcap)
	if name then
		local uniques_optional = not not astnodes[name]
		---@type ASTNodeInfo
		local astnode_info = astnodes[name] or {
			name = name,
			fields = {},
		}
		astnodes[name] = astnode_info
		process_table_recur(tblcap, astnode_info, uniques_optional)
		return astnode_info
	end
end
---@param cap SelenScript.GrammarTools.GrammarInfo.CaptureBase
---@param checked table<SelenScript.GrammarTools.GrammarInfo.CaptureBase,true>?
local function process_cap(cap, checked)
	checked = checked or {}
	if checked[cap] then
		return
	end
	checked[cap] = true

	-- Look for any table captures.
	if cap.__name == "table" then
		---@cast cap SelenScript.GrammarTools.GrammarInfo.TableCapture
		process_table(cap)
	elseif cap.__name == "capctx" or cap.__name == "rule" then
		---@cast cap SelenScript.GrammarTools.GrammarInfo.CaptureContext
		for i, v in ipairs(cap.captures) do
			process_cap(v, checked)
		end
		for i, v in Utils.sorted_pairs(cap.fields) do
			process_cap(v, checked)
		end
	end
end

for _, rule in Utils.sorted_pairs(grammar_info.rules) do
	process_cap(rule)
end

for name, fields in pairs(OVERRIDE_FIELD_TYPES) do
	local astnode = assert(astnodes[name], name)
	for field, override in pairs(fields) do
		if override == false then
			astnode.fields[field] = nil
		elseif type(override) == "function" then
			override(astnode.fields[field], astnode)
		elseif type(override) == "table" and type(override[1]) == "string" then
			astnode.fields[field].types = override
		elseif type(override) == "string" then
			astnode.fields[field].types = {override}
		else
			if type(override) == "table" then
				if type(astnode.fields[field]) == "string" then
					astnode.fields[field] = {types={astnode.fields[field]}}
				end
				Utils.merge(override, astnode.fields[field], true)
			else
				astnode.fields[field] = override
			end
		end
	end
end

if TESTING_NODE_NAME then
	print(table.concat(tostring_value(astnodes[TESTING_NODE_NAME]), ""))
end

local value_captures = Utils.shallowcopy(astnodes["expressionlist"].fields["[integer]"])
value_captures.optional = false

---@param field_info ASTNodeInfo.TypeInfo
local function str_field_type(field_info)
	if field_info ~= value_captures and Utils.deepeq(field_info.types, value_captures.types) then
		return "SelenScript.ASTNodes.expression"
	end
	local type_strs = {}
	for i, v in ipairs(field_info.types) do
		if type(v) == "string" then
			table.insert(type_strs, v)
		else
			local typ_str = str_field_type(v)
			if typ_str:find("[|?]") then
				typ_str = ("(%s)"):format(typ_str)
			end
			table.insert(type_strs, typ_str)
		end
	end
	local type_str = table.concat(type_strs, "|")
	if #type_strs <= 0 then
		type_str = "unknown"
	end
	if field_info.optional then
		if #type_strs <= 1 then
			type_str = type_str .. "?"
		else
			type_str = "nil|"..type_str
		end
	end
	return type_str
end
local function astnodes_sort_cmp(a, b)
	local av = astnodes[a]
	local bv = astnodes[b]
	if av.name == TESTING_RULE_NAME or av.name == TESTING_NODE_NAME then
		return true
	elseif bv.name == TESTING_RULE_NAME or bv.name == TESTING_NODE_NAME then
		return false
	end
	return av.name < bv.name
end
local function astnodes_type_field_sort_cmp(a, b)
	if OVERRIDE_FIELD_ORDER[a] and OVERRIDE_FIELD_ORDER[b] then
		return OVERRIDE_FIELD_ORDER[a] < OVERRIDE_FIELD_ORDER[b]
	elseif OVERRIDE_FIELD_ORDER[a] then
		return true
	elseif OVERRIDE_FIELD_ORDER[b] then
		return false
	end
	return Utils.keys_sort(a, b)
end
---@param field_type ASTNodeInfo.TypeInfo|string
local function astnodes_type_get_constant_ast_node(field_type)
	if type(field_type) == "string" then
		local inner = field_type:match("^[\"'](.*)[\"']$")
		if inner then
			return ASTNodes.string{value=inner}
		end
	end
	return nil
end
---@param field_info ASTNodeInfo.TypeInfo
local function field_get_constant_as_node(field_info)
	if #field_info.types > 1 then
		return nil
	elseif #field_info.types == 0 then
		return ASTNodes["nil"]{}
	elseif field_info.optional then
		return nil
	end
	if type(field_info.types[1]) == "string" then
		return astnodes_type_get_constant_ast_node(field_info.types[1])
	end
	return nil
end
---@param field_info ASTNodeInfo.TypeInfo
---@param value_node SelenScript.ASTNodes.expression
local function field_get_type_check(field_info, value_node)
	if #field_info.types == 0 then
		return {
			type = "eq", start = 1, finish = 1,
			lhs = value_node,
			op = "==",
			rhs = ASTNodes["nil"]{},
		}
	end
	local constants = {}
	for _, typ in ipairs(field_info.types) do
		local constant_node = astnodes_type_get_constant_ast_node(typ)
		if constant_node then
			table.insert(constants, constant_node)
		else
			constants = nil
			break
		end
	end
	if constants and #constants > 0 then
		local base
		for i, constant_node in ipairs(constants) do
			local cmp_node = {
				type = "eq", start = 1, finish = 1,
				lhs = value_node,
				op = "==",
				rhs = constant_node,
			}
			if not base then
				base = cmp_node
			else
				base = {
					type = "or", start = 1, finish = 1,
					lhs = base,
					op = "or",
					rhs = cmp_node,
				}
			end
		end
		if base and field_info.optional then
			base = {
				type = "or", start = 1, finish = 1,
				lhs = {
					type = "eq", start = 1, finish = 1,
					lhs = value_node,
					op = "==",
					rhs = ASTNodes["nil"]{},
				},
				op = "or",
				rhs = base,
			}
		end
		return base
	elseif type(field_info) == "table" then
		local value_index_type_node = ASTNodes.index{expr=value_node, index=ASTNodes.index{how=".", expr=ASTNodes.name{name="type"}}}
		local value_type_node = ASTNodes.index{expr=ASTNodes.name{name="type"}, index=ASTNodes.call{args=ASTNodes.expressionlist{value_node}}}
		local types_base = {}
		local types_table = {}
		for _, typ in ipairs(field_info.types) do
			if type(typ) == "string" then
				local type_name = typ:match("SelenScript%.ASTNodes%.(.*)")
				if type_name == "SrcPosition" then
					table.insert(types_base, {
						type = "eq", start = 1, finish = 1,
						lhs = value_type_node,
						op = "==",
						rhs = ASTNodes.string{value="number"},
					})
					goto continue
				elseif type_name then
					table.insert(types_table, {
						type = "eq", start = 1, finish = 1,
						lhs = value_index_type_node,
						op = "==",
						rhs = ASTNodes.string{value=type_name},
					})
					goto continue
				elseif typ == "string" or typ == "number" or typ == "integer" then
					if typ == "integer" then typ = "number" end
					-- TODO: Check integer values properly.
					table.insert(types_base, {
						type = "eq", start = 1, finish = 1,
						lhs = value_type_node,
						op = "==",
						rhs = ASTNodes.string{value=typ},
					})
					goto continue
				end
			end
			types_base = nil
			types_table = nil
			do
				break
			end
		    ::continue::
		end
		if types_base and types_table and (#types_base > 0 or #types_table > 0) then
			local base
			for _, cmp_node in ipairs(types_base) do
				if not base then
					base = cmp_node
				else
					base = {
						type = "or", start = 1, finish = 1,
						lhs = base,
						op = "or",
						rhs = cmp_node,
					}
				end
			end
			if #types_table > 0 then
				-- TODO: We are making MANY checks, would it be more efficent to use a table keys to check?
				local table_base
				for _, cmp_node in ipairs(types_table) do
					if not table_base then
						table_base = cmp_node
					else
						table_base = {
							type = "or", start = 1, finish = 1,
							lhs = table_base,
							op = "or",
							rhs = cmp_node,
						}
					end
				end
				table_base = {
					type = "and", start = 1, finish = 1,
					lhs = {
						type = "eq", start = 1, finish = 1,
						lhs = ASTNodes.index{expr=ASTNodes.name{name="type"}, index=ASTNodes.call{args=ASTNodes.expressionlist{value_node}}},
						op = "==",
						rhs = ASTNodes.string{value="table"},
					},
					op = "and",
					rhs = table_base,
				}
				if base then
					base = {
						type = "or", start = 1, finish = 1,
						lhs = base,
						op = "or",
						rhs = table_base,
					}
				else
					base = table_base
				end
			end
			if base and field_info.optional then
				base = {
					type = "or", start = 1, finish = 1,
					lhs = {
						type = "eq", start = 1, finish = 1,
						lhs = value_node,
						op = "==",
						rhs = ASTNodes["nil"]{},
					},
					op = "or",
					rhs = base,
				}
			end
			return base
		end
		return not field_info.optional and value_node or nil
	end
	return nil
end

local ast = ASTNodes.block{}

table.insert(ast, ASTNodes.LineComment{prefix="--", value=" THIS FILE IS GENERATED"})
table.insert(ast, ASTNodes.LineComment{prefix="", value=""})  -- Used to create a blank line.
table.insert(ast, ASTNodes.LineComment{prefix="---", value="@alias SelenScript.ASTNodes.SrcPosition integer"})
table.insert(ast, ASTNodes.LineComment{prefix="", value=""})  -- Used to create a blank line.
table.insert(ast, ASTNodes.assign{
	scope="local",
	names=ASTNodes.attributenamelist{ASTNodes.attributename{name="ASTNodes"}},
	values=ASTNodes.expressionlist{ASTNodes.table{fields=ASTNodes.fieldlist{}}}
})
table.insert(ast, ASTNodes.LineComment{prefix="", value=""})  -- Used to create a blank line.
table.insert(ast, ASTNodes.assign{
	scope="local",
	names=ASTNodes.attributenamelist{ASTNodes.attributename{name="Utils"}},
	values=ASTNodes.expressionlist{ASTNodes.index{expr=ASTNodes.name{name="require"}, index=ASTNodes.call{args=ASTNodes.string{value="SelenScript.utils"}}}}
})
table.insert(ast, ASTNodes.LineComment{prefix="", value=""})  -- Used to create a blank line.
table.insert(ast, ASTNodes.LineComment{prefix="", value=""})  -- Used to create a blank line.

table.insert(ast, ASTNodes.LineComment{prefix="---", value="@class SelenScript.ASTNodes.Node"})
table.insert(ast, ASTNodes.LineComment{prefix="---", value="@field type string"})
table.insert(ast, ASTNodes.LineComment{prefix="---", value="@field start integer"})
table.insert(ast, ASTNodes.LineComment{prefix="---", value="@field start_source integer?  # Used to override source map start position"})
table.insert(ast, ASTNodes.LineComment{prefix="---", value="@field finish integer"})
table.insert(ast, ASTNodes.LineComment{prefix="---", value="@field source SelenScript.ASTNodes.Source"})

table.insert(ast, ASTNodes.LineComment{prefix="", value=""})  -- Used to create a blank line.
table.insert(ast, ASTNodes.LineComment{prefix="---", value=("@alias SelenScript.ASTNodes.expression %s"):format(str_field_type(value_captures))})

table.insert(ast, ASTNodes.LineComment{prefix="", value=""})  -- Used to create a blank line.
table.insert(ast, ASTNodes.LineComment{prefix="", value=""})  -- Used to create a blank line.

local parser, errors = Parser.new({
	selenscript=true
})
if #errors > 0 then
	print_error("-- Grammar Errors: " .. #errors .. " --")
	for _, v in ipairs(errors) do
		print_error((v.id or "NO_ID") .. ": " .. v.msg)
	end
end
if parser == nil then
	print_warn("Exit early, parser object is nil")
	os.exit(-1)
	return  -- Make diagnostics happy
end

for _, astnode in Utils.sorted_pairs(astnodes, astnodes_sort_cmp) do
	table.insert(ast, ASTNodes.LineComment{prefix="---", value=("@class SelenScript.ASTNodes.%s : SelenScript.ASTNodes.Node"):format(astnode.name)})
	for field_name, field_info in Utils.sorted_pairs(astnode.fields, astnodes_type_field_sort_cmp) do
		if type(field_name) == "number" then
			field_name = ("[%s]"):format(field_name)
		elseif field_name:sub(1, 1) ~= "_" then
			local field_type = str_field_type(field_info)
			table.insert(ast, ASTNodes.LineComment{prefix="---", value=("@field %s %s"):format(field_name, field_type)})
		end
	end

	table.insert(ast, ASTNodes.LineComment{prefix="", value=""})  -- Used to create a blank line.

	local func_args_fields = {"_parent:SelenScript.ASTNodes.Node?"}
	local func_block = ASTNodes.block{}
	table.insert(func_block, ASTNodes.assign{
		names=ASTNodes.varlist{ASTNodes.index{expr=ASTNodes.name{name="args"}, index=ASTNodes.index{how="[", expr=ASTNodes.string{value="source"}}}},
		values=ASTNodes.expressionlist{_default_parent_or("source", ASTNodes["nil"]{})},
	})
	for field_name, field_info in Utils.sorted_pairs(astnode.fields, astnodes_type_field_sort_cmp) do
		if type(field_name) == "string" and field_name:sub(1, 1) ~= "_" then
			local field_index_node = ASTNodes.index{expr=ASTNodes.name{name="args"}, index=ASTNodes.index{how="[", expr=ASTNodes.string{value=field_name}}}
			local custom_code = HELPER_CUSTOM_CODE[astnode.name] and HELPER_CUSTOM_CODE[astnode.name][field_name]
			local field_info_helper = field_info
			local custom_code_node
			if custom_code then
				field_info_helper = Utils.deepcopy(field_info_helper)
				local code = custom_code(field_info_helper)
				if type(code) == "string" then
					local ast_source, errors, comments = parser:parse(code)
					if #errors > 0 then
						print_error("-- Parse Errors: " .. #errors .. " --")
						for _, v in ipairs(errors) do
							print_error(v.id .. ": " .. v.msg)
						end
					end
					custom_code_node = ast_source
				end
			end
			local field_value_node = field_get_constant_as_node(field_info_helper)
			if not field_value_node then
				if field_name ~= "[integer]" then
					-- TODO: Check `[integer]` values (same assert stuff as for fields)
					---@diagnostic disable-next-line: cast-local-type
					field_value_node = field_index_node

					if HELPER_FIELD_DEFAULTS[field_name] then
						if field_info_helper == field_info then
							field_info_helper = Utils.deepcopy(field_info_helper)
						end
						field_info_helper.optional = true

						table.insert(func_block, ASTNodes["if"]{
							condition={
								type = "eq", start = 1, finish = 1,
								lhs = field_index_node,
								op = "==",
								rhs = ASTNodes["nil"]{},
								---@diagnostic disable-next-line: assign-type-mismatch
								source = nil
							},
							block=ASTNodes.block{
								ASTNodes.assign{names=ASTNodes.varlist{field_index_node}, values=ASTNodes.expressionlist{HELPER_FIELD_DEFAULTS[field_name]}}
							},
						})
					end

					if custom_code_node then
						table.insert(func_block, custom_code_node)
					end

					if ENABLE_HELPER_ASSERTIONS then
						local type_check_node = field_get_type_check(field_info, field_value_node)
						if type_check_node then
							table.insert(func_block, ASTNodes.index{
								expr=ASTNodes.name{name="assert"},
								index=ASTNodes.call{
									args=ASTNodes.expressionlist{type_check_node}
								}
							})
						end
					end
				end

				local field_type = str_field_type(field_info_helper)
				table.insert(func_args_fields, ("%s:%s"):format(field_name, field_type))
			end
			if field_value_node and field_value_node ~= field_index_node then
				table.insert(func_block, ASTNodes.assign{names=ASTNodes.varlist{field_index_node}, values=ASTNodes.expressionlist{field_value_node}})
			end
		end
	end
	table.insert(func_block, ASTNodes.assign{
		names=ASTNodes.varlist{ASTNodes.index{expr=ASTNodes.name{name="args"}, index=ASTNodes.index{how="[", expr=ASTNodes.string{value="_parent"}}}},
		values=ASTNodes.expressionlist{ASTNodes["nil"]{}},
	})
	table.insert(func_block, ASTNodes["return"]{values=ASTNodes.expressionlist{ASTNodes.index{expr=ASTNodes.name{name="args"}}}})
	table.insert(ast, ASTNodes.LineComment{prefix="---", value=("@param args {%s}"):format(table.concat(func_args_fields, ", "))})
	table.insert(ast, ASTNodes.LineComment{prefix="---", value=("@return SelenScript.ASTNodes.%s"):format(astnode.name)})
	local func_node = ASTNodes["function"]{funcbody=ASTNodes.funcbody{args=ASTNodes.parlist{ASTNodes.name{name="args"}}, block=func_block}}
	table.insert(ast, ASTNodes.assign{names=ASTNodes.varlist{ASTNodes.index{expr=ASTNodes.name{name="ASTNodes"}, index=ASTNodes.index{how="[", expr=ASTNodes.string{value=astnode.name}}}}, values=ASTNodes.expressionlist{func_node}})

	table.insert(ast, ASTNodes.LineComment{prefix="", value=""})  -- Used to create a blank line.
	table.insert(ast, ASTNodes.LineComment{prefix="", value=""})  -- Used to create a blank line.
end

table.insert(ast, ASTNodes["return"]{values=ASTNodes.expressionlist{ASTNodes.index{expr=ASTNodes.name{name="ASTNodes"}}}})
table.insert(ast, ASTNodes.LineComment{prefix="", value=""})  -- Used to create a blank line.

local emitter = Emitter.new("lua", {
	luacats_source=false,
})
local out, src_map = emitter:generate(ast)

Utils.writeFile("SelenScript/parser/ast_nodes.lua", out)
