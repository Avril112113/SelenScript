local lp = require "lpeglabel"
local re = require "drelabel"

local Precedence = require "SelenScript.parser.precedence"
local ParserErrors = require "SelenScript.parser.errors"
local Utils = require "SelenScript.utils"


--- All the AST definitions
---@class SelenScript.AST
---@field _bound_methods table<function,function>
---@field errors SelenScript.Error[]
---@field comments (SelenScript.ASTNodes.LineComment|SelenScript.ASTNodes.LongComment)[]
local AST = {
	esc_t = "\t",
	nl = lp.P'\r\n' + lp.S'\r\n',
}

-- Bind `.` calls with `self`
-- This is needed because of lpeg
---@param name any
function AST:__index(name)
	local value = rawget(self, name)
	if value == nil then
		value = rawget(AST, name)
	end
	if type(value) == "function" then
		local f = self._bound_methods[name]
		if f == nil then
			f = function(t, ...)
				if t == self then
					return value(self, ...)
				end
				return value(self, t, ...)
			end
			self._bound_methods[name] = f
		end
		return f
	end
	return value
end

local tostring_ast_ignored_keys = {type=true, start=true, finish=true, source=true, _avcalcline=true, calcline=true}
local tostring_ast_indent = "    "
function AST.tostring_ast(ast)
	local function str_value(value)
		if type(value) == "string" then
			if #value > 64 then
				return ("<STRING_TOO_LONG:#%i>"):format(#value)
			end
			return "\"" .. value:gsub("\"", "\\\""):gsub("\n", "\\n"):gsub("\r", "\\r"):gsub("\t", "\\t") .. "\""
		end
		return tostring(value)
	end
	local parts = {}
	local function str_node(node, depth)
		local indent = string.rep(tostring_ast_indent, depth)
		table.insert(parts, "<type: ")
		table.insert(parts, tostring(node.type))
		table.insert(parts, "> @ ")
		table.insert(parts, tostring(node.start))
		table.insert(parts, ":")
		table.insert(parts, tostring(node.finish))
		for name, value in Utils.sorted_pairs(node) do
			if tostring_ast_ignored_keys[name] == nil then
				table.insert(parts, "\n")
				table.insert(parts, indent..tostring_ast_indent)
				table.insert(parts, name)
				table.insert(parts, " = ")
				if type(value) == "table" and value.type ~= nil then
					str_node(value, depth+1)
				else
					table.insert(parts, str_value(value))
				end
			end
		end
	end
	str_node(ast, 0)
	return table.concat(parts)
end

--- Create a re-useable AST object
--- This object is used as the AST definitions, not the resulting AST it's self
function AST.new()
	return setmetatable({
		_bound_methods = {},
	}, AST)
end

--- Initialize that something new is going to be parsed with this AST definitions object
---@param src string # Required for error message position calculations
function AST:init(src)
	self.src = src
	self.errors = {}
	self.comments = {}
end

---@param id string
---@param start number
---@param finish number
---@param ... string
function AST:add_error(id, start, finish, ...)
	local errorBase = ParserErrors[id]
	if errorBase == nil then
		table.insert(self.errors, errorBase)
	else
		local ln, col = re.calcline(self.src, start)
		table.insert(self.errors, errorBase({start=start,finish=finish,src=self.src}, ln, col, ...))
	end
end

---@param tbl table
function AST:add_error_t(tbl)
	local id = tbl.id
	local start = tbl.start
	local finish = tbl.finish
	local errorBase = ParserErrors[id]
	if errorBase == nil then
		table.insert(self.errors, errorBase)
	else
		local ln, col = re.calcline(self.src, start)
		table.insert(self.errors, errorBase({start=start,finish=finish,src=self.src}, ln, col, unpack(tbl)))
	end
end

---@param id string
---@param start number
---@param msg string
---@param finish number
function AST:add_error_o(id, start, msg, finish)
	local errorBase = ParserErrors[id]
	if errorBase == nil then
		table.insert(self.errors, errorBase)
	else
		local ln, col = re.calcline(self.src, start)
		table.insert(self.errors, errorBase({start=start,finish=finish,src=self.src}, ln, col, msg))
	end
end

function AST:add_comment(node)
	table.insert(self.comments, node)
end

---@param data SelenScript.ASTNodes.expression[]
---@param min_precedence number
function AST:_climbPrecedence(data, min_precedence)
	local lhs = table.remove(data, 1)
	if lhs.type == "binary_op" or lhs.type == "unary_op" then
		local opData = Precedence.unaryOpData[lhs.op]
		if opData == nil then
			error("Invalid op, was unary '" .. lhs .. "' but expected a valid op")
		end
		if #opData ~= 2 then
			error("Invalid opData, data for unary '" .. lhs .. "' does not contain 2 values")
		end
		local rhs = self:_climbPrecedence(data, opData[1])
		lhs = {
			type=opData[2],
			start=lhs.start,
			finish=rhs.finish,
			op=lhs.op,
			rhs=rhs
		}
	end
	while #data > 0 do
		local lahead = data[1]
		if lahead.type ~= "binary_op" and lahead.type ~= "unary_op" then break end

		---@diagnostic disable-next-line: undefined-field # Because it does exist...
		local op = lahead.op:lower()
		local opData = Precedence.binaryOpData[op]
		if opData == nil then
			error("Invalid op, was binary '" .. op .. "' but expected a valid op")
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
		local rhs = self:_climbPrecedence(data, nextPrecedence)
		lhs = {
			type=opData[2],
			start=lhs.start,
			finish=rhs.finish,
			lhs=lhs,
			op=op,
			rhs=rhs
		}
	end
	return lhs
end
---@param data SelenScript.ASTNodes.expression[]|{start:integer, finish:integer}
---@param min_precedence number
function AST:climbPrecedence(data, min_precedence)
	min_precedence = min_precedence or 1
	local result = self:_climbPrecedence(data, min_precedence)
	if #data > 0 then
		self:add_error("GRAMMAR_INVALID_MATH", data.start, data.finish)
	end
	return result
end


return AST
