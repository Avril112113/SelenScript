local helpers = require "selenScript.helpers"
local targets = require "selenScript.targets"
local parser = require "selenScript.parser"

local statements = {}
statements.__index = statements


function statements.new(transformer)
	local self = setmetatable({}, statements)
	self.transformer = transformer

	self.block_depth = -1

	return self
end


function statements:block(ast)
	-- yes all of this is needed just for `block_depth` as stuff may want to remove then selves, based on self.transformer:transform()
	self.block_depth = self.block_depth + 1
	local toRemove = {}
	for i, v in ipairs(ast) do
		local newValue = self.transformer:transform(v)
		if newValue == nil then
			table.insert(toRemove, i)
		else
			v[i] = newValue
		end
	end
	for i=#toRemove,1,-1 do
		local key = toRemove[i]
		table.remove(ast, key)
	end
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
		table.insert(ast.parent, parser.defs["goto"](-1, "continue_" .. tostring(breakableBlockDepth), -1))
		table.insert(breakableBlock, parser.defs.label(-1, "continue_" .. tostring(breakableBlockDepth), -1))
	else
		table.insert(ast.parent, parser.defs["break"](-1, nil, nil, -1))
		local block = parser.defs.block(-1, -1)
		for i, v in ipairs(breakableBlock) do
			breakableBlock[i] = nil
			v.parent = block
			table.insert(block, v)
		end
		local repeatStmt = parser.defs["repeat"](-1, block, parser.defs.bool(-1, "true", -1), -1)
		repeatStmt.parent = breakableBlock
		table.insert(breakableBlock, repeatStmt)
	end
	return nil
end


return statements
