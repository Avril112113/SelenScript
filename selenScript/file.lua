local Symbol = require "selenScript.symbol"
local helpers = require "selenScript.helpers"
local parser = require "selenScript.parser"

---@class SS_File
local file = {
	---@type string
	filepath=nil,
	---@type string
	code=nil,
	---@type table[]
	symbolizeDiagnostics=nil,

	---@type SS_Program
	program=nil,
}
file.__index = file


function file.new(filepath)
	local self = setmetatable({}, file)
	self.filepath = filepath

	local f = io.open(filepath)
	if f == nil then
		error("Failed to open file '" .. filepath .. "'")
	else
		self.code = f:read("*a")
		f:close()
	end

	self.parseResult = parser.parse(self)
	self.ast = self.parseResult.ast

	return self
end


function file:symbolize()
	self.symbolizeDiagnostics = {}

	local function getSymbol(name, ast)
		if ast.locals ~= nil and ast.locals[name] ~= nil then
			return ast.locals[name]
		end
		if ast.parent == nil then
			return nil
		end
		return getSymbol(name, ast.parent)
	end
	local function getSymbolTable(ast)
		if ast.locals ~= nil then
			return ast.locals
		end
		if ast.parent == nil then
			return nil
		end
		return getSymbolTable(ast.parent)
	end
	local function createSymbol(name, ast, value)
		local symbolTable
		local symbol
		if ast.scope == "local" then
			symbolTable = getSymbolTable(ast)
		elseif ast.scope == "global" then
			symbolTable = self.program.globals
		else
			symbol = getSymbol(name, ast)
			if symbol ~= nil then
			elseif self.program.settings.defaultLocals then
				symbolTable = getSymbolTable(ast)
			else
				symbolTable = self.program.globals
			end
		end

		if symbol ~= nil then
			-- it's already defined
			symbol:addDeclaration(ast)
		elseif symbolTable ~= nil then
			-- no definition or symbol yet, so we need to create them
			symbol = Symbol.new {
				name=name,
				value=value
			}
			symbol:addDeclaration(ast)
			symbolTable[name] = symbol
		else
			table.insert(self.symbolizeDiagnostics, {
				msg="INTERNAL: createSymbol Wait What? how did we get here?"
			})
			return
		end
	end
	local function symbolize(ast)
		if ast.type == "block" then
			ast.locals = ast.locals or {}
			for i, stmt in ipairs(ast) do
				symbolize(stmt)
			end
		elseif ast.type == "do" then
			symbolize(ast.block)
		elseif ast.type == "anon_function" then
			symbolize(ast.body)
		elseif ast.type == "function" then
			local name
			local var = ast.funcname
			if type(var) == "string" then
				name = var
			elseif var.index == nil and var.name ~= nil then
				name = var.name
			else
				table.insert(self.symbolizeDiagnostics, {
					msg="UNIMPLEMENTED: file:symbolize().symbolize() type 'function': assignment into table"
				})
				return
			end

			createSymbol(name, ast, helpers.deepCopy(ast.body))
			symbolize(ast.body)
		elseif ast.type == "funcbody" then
			local block = ast.block
			local locals = {}
			block.locals = locals

			for _, arg in ipairs(ast.args) do
				createSymbol(arg.name, block)
			end

			symbolize(block)
		elseif ast.type == "assign" then
			for i, var in ipairs(ast.var_list) do
				local value = ast.expr_list[i]
				local name
				if type(var) == "string" then
					name = var
				elseif var.index == nil and var.name ~= nil then
					name = var.name
				else
					table.insert(self.symbolizeDiagnostics, {
						msg="UNIMPLEMENTED: file:symbolize().symbolize() type 'assign': assignment into table"
					})
					return
				end

				symbolize(value)
				createSymbol(name, ast, helpers.deepCopy(value))
			end
		elseif ast.type == "index" then
			if ast.index == nil then
				if ast.name ~= nil then
					local symbol = getSymbol(ast.name, ast)
					if symbol == nil then
						table.insert(self.symbolizeDiagnostics, {
							msg="TODO: file:symbolize().symbolize() type 'index': handle when index is undefined"
						})
						return
					end
					symbol:addReference(ast)
				else
					table.insert(self.symbolizeDiagnostics, {
						msg="UNIMPLEMENTED: file:symbolize().symbolize() type 'index': expr index"
					})
					return
				end
			else
				table.insert(self.symbolizeDiagnostics, {
					msg="UNIMPLEMENTED: file:symbolize().symbolize() type 'index': index into table"
				})
				return
			end
		elseif ast.type == "table" then
			ast.symbols = {}
			
		elseif ast.type == "Int" or ast.type == "Float" or ast.type == "Hex" or ast.type == "String" or ast.type == "LongString" or ast.type == "nil" then
			-- Nothing to do
		elseif ast.type == "LongComment" or ast.type == "Comment" then
			-- Comments will have special stuff later on, like emmy lua support
		else
			table.insert(self.symbolizeDiagnostics, {
				msg="file:symbolize().symbolize() missing handle for type " .. helpers.strValue(ast.type)
			})
			return
		end
	end
	symbolize(self.ast)
end


return file
