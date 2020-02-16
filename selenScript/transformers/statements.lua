local helpers = require "selenScript.helpers"
local targets = require "selenScript.targets"
local parser = require "selenScript.parser"


local unpack = table.unpack or unpack


local statements = {}
statements.__index = statements


---@param transformer SS_Transformer
function statements.new(transformer)
	local self = setmetatable({}, statements)
	self.transformer = transformer

	self.block_depth = -1
	self.prefix_stmts = {}
	transformer.prefix_stmts = self.prefix_stmts
	self.suffix_stmts = {}
	transformer.suffix_stmts = self.suffix_stmts

	return self
end


function statements:block(ast)
	self.block_depth = self.block_depth + 1

	-- Ugh, i hate having to copy code (from the transformer.lua)
	local i = 1
	while i <= #ast do
		table.insert(self.prefix_stmts, {})
		table.insert(self.suffix_stmts, {})

		local v = ast[i]
		if type(v) == "table" and v.type ~= nil and i ~= "parent" then
			local newValues = {self.transformer:transform(v)}
			local newValue = newValues[1]
			if newValue == nil and type(i) == "number" and #v <= i then
				table.remove(ast, i)
			else
				ast[i] = newValue
				i = i + 1
			end
			if #newValues > 1 then
				for valueIndex=2,#newValues do
					local value = newValues[valueIndex]
					table.insert(ast, i, value)
					value.parent = ast
					i = i + 1
				end
			end
		else
			i = i + 1
		end

		for _, stmt in ipairs(table.remove(self.prefix_stmts)) do
			table.insert(ast, i-1, stmt)
			stmt.parent = ast
			i = i + 1
		end
		for _, stmt in ipairs(table.remove(self.suffix_stmts)) do
			table.insert(ast, i, stmt)
			stmt.parent = ast
			i = i + 1
		end
	end

	self.block_depth = self.block_depth - 1
	return ast
end

function statements:continue(ast)
	self.transformer:transform(ast, true)

	local target = targets[self.transformer.settings.targetVersion]
	if ast.parent == nil or ast.parent.type ~= "block" then
		table.insert(self.transformer.diagnostics, {
			type="internal",
			start=ast.start,
			finish=ast.finish,
			msg="continue is does not have a parent node of type block"
		})
		return nil
	end
	local breakableStmt = ast.parent
	while target.breakable[breakableStmt.type] == nil do
		if breakableStmt.parent == nil or breakableStmt.type == "function" then
			local suffix = ""
			if breakableStmt.type == "function" then
				suffix = " (blocked by function)"
			end
			table.insert(self.transformer.diagnostics, {
				type="internal",
				start=ast.start,
				finish=ast.finish,
				msg="Failed to find breakable block" .. suffix
			})
			return nil
		end
		breakableStmt = breakableStmt.parent
	end
	local breakableBlock = breakableStmt.block
	local breakableBlockDepth = 0
	-- this is not the best way to get the block depth, but it works for now
	local _curNode = breakableBlock
	while _curNode.parent ~= nil do
		if _curNode.type == "block" then
			breakableBlockDepth = breakableBlockDepth + 1
		end
		_curNode = _curNode.parent
	end
	if breakableBlockDepth < 0 then
		table.insert(self.transformer.diagnostics, {
			type="internal",
			start=ast.start,
			finish=ast.finish,
			msg="`breakableBlockDepth` is less than 0 (this should not be happening)"
		})
		return nil
	end
	if target.hasGoto then
		if breakableBlock.hasContinue ~= true then
			table.insert(breakableBlock, parser.defs.label(-1, "continue_" .. tostring(breakableBlockDepth), -1))
			breakableBlock.hasContinue = true
		end
		local gotoStmt = parser.defs["goto"](-1, "continue_" .. tostring(breakableBlockDepth), -1)
		if ast.stmt_if ~= nil then
			gotoStmt = parser.defs["if"](-1, ast.stmt_if, parser.defs.block(-1, gotoStmt, -1), -1)
		end
		return gotoStmt
	else
		print("Version " .. self.transformer.settings.targetVersion .. " does not support the goto statement, there is a work in progress solution that will be used!")
		-- FIXME: if first statement is continue then there will be no output at all
		-- FIXME: potential bug when 2 continue stmts are used
		local newBlock = parser.defs.block(-1, -1)
		-- for i, v in pairs(breakableBlock.parent) do
		-- 	if v == breakableBlock then
		-- 		breakableBlock.parent[i] = newBlock
		-- 		break
		-- 	end
		-- end
		newBlock.parser = breakableBlock.parent
		table.insert(newBlock, breakableBlock)
		breakableBlock.parent = newBlock
		local replacedContinueStmt = false
		for i, v in ipairs(breakableBlock) do
			if v == ast then
				breakableBlock[i] = parser.defs["break"](-1, nil, ast.stmt_if, -1)
				breakableBlock[i].parent = breakableBlock
				replacedContinueStmt = true
				break
			end
		end
		if not replacedContinueStmt then
			table.insert(self.transformer.diagnostics, {
				type="internal",
				start=ast.start,
				finish=ast.finish,
				msg="Failed to replace continue statement with break"
			})
		end
		local repeatStmt = parser.defs["repeat"](-1, breakableBlock, parser.defs.bool(-1, "true", -1), -1)
		repeatStmt.parent = breakableBlock
		table.insert(newBlock, repeatStmt)
		-- self.transformer:transform(newBlock)
	end
	return nil
end

statements["return"] = function(self, ast)
	self.transformer:transform(ast, true)

	if ast.stmt_if ~= nil then
		ast = parser.defs["if"](-1, ast.stmt_if, parser.defs.block(-1, ast, -1), -1)
	end
	return ast
end

statements["break"] = function(self, ast)
	self.transformer:transform(ast, true)

	if ast.stmt_if ~= nil then
		ast = parser.defs["if"](-1, ast.stmt_if, parser.defs.block(-1, ast, -1), -1)
	end
	return ast
end

statements["goto"] = function(self, ast)
	self.transformer:transform(ast, true)

	if ast.stmt_if ~= nil then
		ast = parser.defs["if"](-1, ast.stmt_if, parser.defs.block(-1, ast, -1), -1)
	end
	return ast
end

function statements:decorate(ast)
	assert(ast.expr.funcname ~= nil)
	local funcName = helpers.deepCopy(ast.expr.funcname)
	local prevFuncNameIndex
	local funcNameIndex = funcName
	while funcNameIndex ~= nil do
		if funcNameIndex.op == ":" then
			prevFuncNameIndex.index.op = "."
		end
		prevFuncNameIndex = funcNameIndex
		funcNameIndex = funcNameIndex.index
	end
	local dec = ast.decorators[1]
	local lastIndex = dec.index
	local callArgs = dec.call and unpack(dec.call) or {}
	lastIndex.index = parser.defs.call(-1, parser.defs.expr_list(-1, funcName, unpack(callArgs), -1), nil, -1)
	for i=2,#ast.decorators do
		local dec = ast.decorators[i]
		local callArgs = dec.call and unpack(dec.call) or {}
		local call = parser.defs.call(-1, parser.defs.expr_list(-1, lastIndex, unpack(callArgs), -1), nil, -1)
		dec.index.index = call
		lastIndex = dec.index
	end
	local assign = parser.defs.assign(-1, "", parser.defs.expr_list(-1, funcName, -1), nil, lastIndex, -1)
	return ast.expr, assign
end

local exprStmtBlockWhitelist = {["block"]=true, ["if"]=true,["elseif"]=true, ["else"]=true, ["do"]=function(doAst) return doAst.is_expr ~= true end}
local function replaceReturnWithBreakAssign(self, ast, varExpr, _processedBreaks)
	_processedBreaks = _processedBreaks or {}
	for i, v in pairs(ast) do
		if type(v) == "table" and v.type ~= nil and i ~= "parent" then
			if v.type == "return" then
				local field_list = parser.defs.field_list(-1, -1)
				for exprI, expr in ipairs(v.expr_list) do
					table.insert(field_list, parser.defs.field(-1, parser.defs.Int(-1, tostring(exprI), -1), expr, -1))
				end
				ast[i] = parser.defs.assign(-1, "", parser.defs.expr_list(-1, varExpr, -1), nil, parser.defs.expr_list(-1, parser.defs.table(-1, field_list, -1), -1), -1)
				-- FIXME: its unhealthy to assume that `i` is a number
				table.insert(ast, i+1, parser.defs["break"](-1, true, v.stmt_if, -1))
			elseif v.type == "break" and v.expr_list == nil and _processedBreaks[v] == nil then
				-- unfortunately we have to adjust the normal break statements
				-- FIXME: there might be multiple break vars with multiple break statements
				local breakVarName = self.transformer:getVarName()
				local breakVarExpr = parser.defs.index(-1, "", nil, breakVarName, nil, nil, -1)
				local assignStmt = parser.defs.assign(-1, "local", parser.defs.var_list(-1, breakVarExpr, -1), nil, nil, -1)
				table.insert(self.prefix_stmts[#self.prefix_stmts], assignStmt)
				local ifBreakThenBreak = parser.defs["if"](-1, breakVarExpr, parser.defs.block(-1, parser.defs["break"](-1, nil, nil, -1), -1), -1)
				table.insert(self.suffix_stmts[#self.suffix_stmts], ifBreakThenBreak)
				ast[i] = parser.defs.assign(-1, "", parser.defs.var_list(-1, breakVarExpr, -1), nil, parser.defs.expr_list(-1, parser.defs.bool(-1, "true", -1), -1), -1)
				table.insert(ast, i+1, v)
				_processedBreaks[v] = true
			elseif exprStmtBlockWhitelist[v.type] == true or (type(exprStmtBlockWhitelist[v.type]) == "function" and exprStmtBlockWhitelist[v.type](v)) then
				replaceReturnWithBreakAssign(self, v, varExpr, _processedBreaks)
			end
		end
	end
end
local function replaceBreakWithBreakAssign(self, ast, varExpr)
	for i, v in pairs(ast) do
		if type(v) == "table" and v.type ~= nil and i ~= "parent" then
			if v.type == "break" then
				if v.expr_list ~= nil then
					local field_list = parser.defs.field_list(-1, -1)
					for exprI, expr in ipairs(v.expr_list) do
						table.insert(field_list, parser.defs.field(-1, parser.defs.Int(-1, tostring(exprI), -1), expr, -1))
					end
					ast[i] = parser.defs.assign(-1, "", parser.defs.expr_list(-1, varExpr, -1), nil, parser.defs.expr_list(-1, parser.defs.table(-1, field_list, -1), -1), -1)
					-- FIXME: its unhealthy to assume that `i` is a number
					table.insert(ast, i+1, parser.defs["break"](-1, nil, v.stmt_if, -1))
				end
			elseif exprStmtBlockWhitelist[v.type] == true or (type(exprStmtBlockWhitelist[v.type]) == "function" and exprStmtBlockWhitelist[v.type](v)) then
				replaceBreakWithBreakAssign(self, v, varExpr)
			end
		end
	end
end
statements["do"] = function(self, ast)
	self.transformer:transform(ast, true)

	if ast.is_expr == true then
		local target = targets[self.transformer.settings.targetVersion]
		local varName = self.transformer:getVarName()
		local varExpr = parser.defs.index(-1, "", nil, varName, nil, nil, -1)
		replaceReturnWithBreakAssign(self, ast.block, varExpr)
		local callExpr = parser.defs.call(-1, parser.defs.expr_list(-1, varExpr, -1), nil, -1)
		local expr
		if target.globalUnpack then
			expr = parser.defs.index(-1, "", nil, "unpack", nil, callExpr, -1)
		else
			local unpackExpr = parser.defs.index(-1, ".", nil, "unpack", nil, callExpr, -1)
			expr = parser.defs.index(-1, "", nil, "table", nil, unpackExpr, -1)
		end

		local assignStmt = parser.defs.assign(-1, "", parser.defs.expr_list(-1, varExpr, -1), nil, parser.defs.expr_list(-1, parser.defs.table(-1, parser.defs.field_list(-1, -1), -1), -1), -1)
		table.insert(self.prefix_stmts[#self.prefix_stmts], assignStmt)
		local repeatStmt = parser.defs["repeat"](-1, parser.defs.block(-1, ast, -1), parser.defs.bool(-1, "true", -1), -1)
		table.insert(self.prefix_stmts[#self.prefix_stmts], repeatStmt)
		return expr
	end

	return ast
end
statements["while"] = function(self, ast)
	self.transformer:transform(ast, true)

	if ast.is_expr == true then
		local target = targets[self.transformer.settings.targetVersion]
		local varName = self.transformer:getVarName()
		local varExpr = parser.defs.index(-1, "", nil, varName, nil, nil, -1)
		replaceBreakWithBreakAssign(self, ast.block, varExpr)

		local callExpr = parser.defs.call(-1, parser.defs.expr_list(-1, varExpr, -1), nil, -1)
		local expr
		if target.globalUnpack then
			expr = parser.defs.index(-1, "", nil, "unpack", nil, callExpr, -1)
		else
			local unpackExpr = parser.defs.index(-1, ".", nil, "unpack", nil, callExpr, -1)
			expr = parser.defs.index(-1, "", nil, "table", nil, unpackExpr, -1)
		end

		local assignStmt = parser.defs.assign(-1, "", parser.defs.expr_list(-1, varExpr, -1), nil, nil, -1)
		table.insert(self.prefix_stmts[#self.prefix_stmts], assignStmt)
		table.insert(self.prefix_stmts[#self.prefix_stmts], ast)
		return expr
	end

	return ast
end
statements["for_each"] = statements["while"]
statements["for_range"] = statements["while"]

function statements:interface(ast)
	return nil
end


return statements
