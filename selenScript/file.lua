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


function file:getSymbol(key, ast)
	if ast.type == "block" and ast.symbols ~= nil then
		for symbolKey, symbol in pairs(ast.symbols) do
			if symbolKey.isEqualValue ~= nil then
				if symbolKey:isEqualValue(key) then
					return symbol
				end
			else
				table.insert(self.symbolizeDiagnostics, {
					type="internal",
					start=ast.start,
					finish=ast.finish,
					msg="INTERNAL: file:symbolize().getSymbol(): type " .. tostring(symbolKey.type) .. " is missing isEqualValue()"
				})
			end
		end
	end
	if ast.parent == nil then
		return nil
	end
	return self:getSymbol(key, ast.parent)
end
function file:getSymbolTable(ast)
	if ast.type == "block" and ast.symbols ~= nil then
		return ast.symbols
	end
	if ast.parent == nil then
		return nil
	end
	return self:getSymbolTable(ast.parent)
end
function file:createSymbol(key, ast, value)
	local symbolTable
	local symbol
	if ast.scope == "local" then
		symbolTable = self:getSymbolTable(ast)
	elseif ast.scope == "global" then
		symbolTable = self.program.globals
	else
		symbol = self:getSymbol(key, ast)
		if symbol ~= nil then
		elseif self.program.settings.defaultLocals then
			symbolTable = self:getSymbolTable(ast)
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
			key=key,
			value=value
		}
		symbolTable[key] = symbol
	else
		table.insert(self.symbolizeDiagnostics, {
			type="internal",
			start=ast.start,
			finish=ast.finish,
			msg="INTERNAL: createSymbol Wait What? how did we get here?"
		})
		return
	end
	return symbol
end
function file:symbolizeAST(ast)
	if ast.type == "block" then
		ast.symbols = ast.symbols or {}
		for i, stmt in ipairs(ast) do
			self:symbolizeAST(stmt)
		end
	elseif ast.type == "do" then
		self:symbolizeAST(ast.block)
	elseif ast.type == "anon_function" then
		self:symbolizeAST(ast.body)
	elseif ast.type == "function" then
		local symbol = self:createSymbol(ast.funcname, ast, helpers.deepCopy(ast.body))
		if symbol ~= nil then
			symbol:addDeclaration(ast)
		end
		self:symbolizeAST(ast.body)
	elseif ast.type == "funcbody" then
		local block = ast.block
		local symbols = {}
		block.symbols = symbols

		for _, arg in ipairs(ast.args) do
			local symbol = self:createSymbol(arg.name, block)
			if symbol ~= nil then
				symbol:addDeclaration(ast)
			end
		end

		self:symbolizeAST(block)
	elseif ast.type == "assign" then
		for i, var in ipairs(ast.var_list) do
			local value = (ast.expr_list ~= nil and ast.expr_list[i]) or nil

			local symbolValue = nil
			if value ~= nil then
				self:symbolizeAST(value)
				symbolValue = helpers.deepCopy(value)
			end
			local symbol = self:createSymbol(var, ast, symbolValue)
			if symbol ~= nil then
				symbol:addDeclaration(ast)
			end
		end
	elseif ast.type == "index" then
		if ast.index == nil then
			local symbol = self:getSymbol(ast.expr, ast)
			if symbol == nil then
				table.insert(self.symbolizeDiagnostics, {
					type="undefined",
					start=ast.start,
					finish=ast.finish,
					msg="Undefined variable " .. ((ast.toString and ast:toString()) or ("<type: " .. tostring(ast.type) .. " is missing toString()>"))
				})
				-- even though it was undefined, we want to still be able to link this up with any potential future declations or references
				symbol = self:createSymbol(ast.expr, ast)
			end
			if symbol ~= nil then
				symbol:addReference(ast)
			end
		else
			table.insert(self.symbolizeDiagnostics, {
				type="internal",
				start=ast.start,
				finish=ast.finish,
				msg="UNIMPLEMENTED: file:symbolizeAST() type 'index': index into table"
			})
			return
		end
	elseif ast.type == "table" then
		local symbols = {}
		ast.symbols = symbols
	elseif ast.type == "Int" or ast.type == "Float" or ast.type == "Hex" or ast.type == "String" or ast.type == "LongString" or ast.type == "nil" then
		-- Nothing to do
	elseif ast.type == "LongComment" or ast.type == "Comment" then
		-- Comments will have special stuff later on, like emmy lua support
	else
		table.insert(self.symbolizeDiagnostics, {
			type="internal",
			start=ast.start,
			finish=ast.finish,
			msg="INTERNAL: file:symbolizeAST() missing handle for type " .. helpers.strValue(ast.type)
		})
		return
	end
end
function file:symbolize()
	self.symbolizeDiagnostics = {}
	local startTime = os.clock()
	self:symbolizeAST(self.ast)
	return os.clock() - startTime
end

-- TODO
function file:diagnose()
	self.diagnostics = {}
end

-- TODO
function file:transpile()
	self.transpileDiagnostics = {}
end


return file
