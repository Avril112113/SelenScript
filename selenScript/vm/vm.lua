local helpers = require "selenScript.helpers"
local common = require "selenScript.ast_common"


local vm = {}
vm.__index = vm

function vm.new(ast, file)
	local self = setmetatable({}, vm)
	self.file = file
	self.add_diagnostic = function(tbl)
		file:add_diagnostic(tbl)
	end

	self:reset()
	self.block = self:run(ast)

	return self
end


function vm:reset()
	self.globals = {
		content={},
		types={}
	}
	self.current_block = nil
end

function vm:run(ast, ...)
	if ast == nil then
		self.add_diagnostic {
			serverity="error",
			type="vm_error",
			start=1,
			finish=1,
			msg="VM Error:\n" .. debug.traceback("ast is nil")
		}
	elseif ast.type == nil then
		self.add_diagnostic {
			serverity="error",
			type="vm_error",
			start=1,
			finish=1,
			msg="VM Error:\n" .. debug.traceback("ast.type is nil")
		}
	elseif vm[ast.type] == nil then
		self.add_diagnostic {
			serverity="error",
			type="vm_error",
			start=1,
			finish=1,
			msg="VM Error: missing vm function '" .. tostring(ast.type) .. "'"
		}
	else
		local f = vm[ast.type]
		return f(self, ast, ...)
	end
end

function vm:eval(ast)
	if type(ast) == "table" and ast.type ~= nil then
		if ast.type == "Int" then
			return tonumber(ast.value)
		elseif ast.type == "String" then
			return ast.value
		elseif ast.type == "table" then
			local tbl = {
				content={},
				types={}
			}
			for i, field in ipairs(ast.fieldlist) do
				local key = self:eval(field.name)
				local value = self:eval(ast.expr)
				tbl[key] = value
			end
			return tbl
		else
			self.add_diagnostic {
				serverity="error",
				type="vm_error",
				start=1,
				finish=1,
				msg="VM Error: missing eval support for type '" .. tostring(ast.type) .. "'"
			}
		end
	else
		return ast  -- might just be nil or something
	end
end

function vm:get_variable(ast, ignoreLast)
	if ignoreLast == nil then ignoreLast = false end
	local block = self.current_block
	local variables = block.locals
	local indexingStr = ""
	local value = ast.name
	if value == nil then value = self:eval(ast.expr) end
	-- TODO: check value == nil
	if ignoreLast and ast.index == nil then return variables, ast, indexingStr end
	-- find initial value
	while true do
		if variables.content[value] ~= nil then
			variables = variables.content[value]
			indexingStr = tostring(value)
			break
		elseif variables == self.globals then
			self.add_diagnostic {
				serverity="error",
				type="undefined_variable",
				start=ast.start,
				finish=ast.finish,
				msg="Variable " .. helpers.strValueFromType(value) .. " is undefined."
			}
			if ignoreLast then
				return variables, ast, indexingStr
			end
			return variables, ast, indexingStr
		elseif block.parent ~= nil then
			block = block.parent
			variables = block.locals
		else
			variables = self.globals
		end
	end
	-- if we continue to index, variables is actually a table
	while true do
		ast = ast.index
		if ignoreLast and ast.index == nil then return variables, ast, indexingStr end
		if ast == nil then
			return variables, ast, indexingStr
		end
		value = ast.name
		if value == nil then value = self:eval(ast.expr) end
		indexingStr = indexingStr .. ast.op
		if ast.op == "[" then
			indexingStr = indexingStr .. helpers.strValueFromType(value) .. "]"
		else
			indexingStr = indexingStr .. value
		end
		-- TODO: check value == nil
		if variables.content[value] ~= nil then
			variables = variables.content[value]
		else
			self.add_diagnostic {
				serverity="error",
				type="undefined_variable",
				start=ast.start,
				finish=ast.finish,
				msg="Variable " .. indexingStr .. " is undefined."
			}
		end
	end
end

local function add(name, f)
	vm[name] = f
end


add("block", function(self, ast)
	local block = {
		parent=self.current_block,
		locals={
			content={},
			types={}
		}
	}
	self.current_block = block
	for i, stmt in ipairs(ast) do
		self:run(stmt)
	end
	self.current_block = block.parent
	return block
end)

add("assign", function(self, ast)
	-- not used if name is indexing
	local variables
	if common.assign_local(ast, self.file) then
		variables = self.current_block.locals
	else
		variables = self.globals
	end

	for i, name in ipairs(ast.varlist) do
		local value = self:eval(ast.exprlist and ast.exprlist[i] or nil)
		local typeInfo = ast.typelist and ast.typelist[i] or nil
		if type(name) == "string" then
			variables.content[name] = value
			variables.types[name] = typeInfo
		else
			local last, indexingStr
			variables, last, indexingStr = self:get_variable(name, true)
			local lastValue = last.name
			if lastValue == nil then
				lastValue = self:eval(last.expr)
			end
			if type(variables) ~= "table" then
				self.add_diagnostic {
					serverity="error",
					type="undefined_variable",
					start=ast.start,
					finish=ast.finish,
					msg="Attempt to assign to `" .. type(variables) .. "` at `" .. indexingStr .. "`."
				}
			else
				variables.content[lastValue] = value
				variables.types[lastValue] = typeInfo
			end
		end
	end

	-- TODO: diagnostics for unused in exprlist AKA `local a = 1, 2` `2` needs to be unused
end)


return vm
