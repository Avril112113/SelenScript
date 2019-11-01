local helpers = require "selenScript.helpers"
local targets = require "selenScript.targets"
local parser = require "selenScript.parser"


local unpack = table.unpack or unpack


local statements = {}
statements.__index = statements


function statements.new(transformer)
	local self = setmetatable({}, statements)
	self.transformer = transformer

	self.block_depth = -1

	return self
end


function statements:block(ast)
	self.block_depth = self.block_depth + 1
	self.transformer:transform(ast, true)
	self.block_depth = self.block_depth - 1
	return ast
end

function statements:continue(ast)
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
		table.insert(breakableBlock, parser.defs.label(-1, "continue_" .. tostring(breakableBlockDepth), -1))
		local gotoStmt = parser.defs["goto"](-1, "continue_" .. tostring(breakableBlockDepth), -1)
		if ast.stmt_if ~= nil then
			gotoStmt = parser.defs["if"](-1, ast.stmt_if, parser.defs.block(-1, gotoStmt, -1), -1)
		end
		return gotoStmt
	else
		local block = parser.defs.block(-1, -1)
		local addedBreak = false
		for i, v in ipairs(breakableBlock) do
			breakableBlock[i] = nil
			v.parent = block
			if v == ast then
				v = parser.defs["break"](-1, ast.exprlist, nil, -1)
				if ast.stmt_if ~= nil then
					v = parser.defs["if"](-1, ast.stmt_if, parser.defs.block(-1, v, -1), -1)
				end
				addedBreak = true
			end
			table.insert(block, v)
		end
		-- Just in case it happens we should still output valid mostly working code
		if addedBreak == false then
			table.insert(breakableBlock, parser.defs["break"](-1, ast.exprlist, nil, -1))
			table.insert(self.transformer.diagnostics, {
				type="internal",
				start=ast.start,
				finish=ast.finish,
				msg="Failed to find continue statement while copying breakable block to new block"
			})
		end
		local repeatStmt = parser.defs["repeat"](-1, block, parser.defs.bool(-1, "true", -1), -1)
		repeatStmt.parent = breakableBlock
		table.insert(breakableBlock, repeatStmt)
	end
	return nil
end

statements["return"] = function(self, ast)
	if ast.stmt_if ~= nil then
		ast = parser.defs["if"](-1, ast.stmt_if, parser.defs.block(-1, ast, -1), -1)
	end
	return ast
end

statements["break"] = function(self, ast)
	if ast.stmt_if ~= nil then
		ast = parser.defs["if"](-1, ast.stmt_if, parser.defs.block(-1, ast, -1), -1)
	end
	return ast
end

statements["goto"] = function(self, ast)
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
	lastIndex.index = parser.defs.call(-1, parser.defs.expr_list(-1, funcName, unpack(dec.call), -1), nil, -1)
	for i=2,#ast.decorators do
		local dec = ast.decorators[i]
		local call = parser.defs.call(-1, parser.defs.expr_list(-1, lastIndex, unpack(dec.call), -1), nil, -1)
		dec.index.index = call
		lastIndex = dec.index
	end
	local assign = parser.defs.assign(-1, "", parser.defs.expr_list(-1, funcName, -1), nil, lastIndex, -1)
	return ast.expr, assign, parser.defs.Comment(-1, "Test A", -1), parser.defs.Comment(-1, "Test B", -1), parser.defs.Comment(-1, "Test C", -1)
end


return statements
