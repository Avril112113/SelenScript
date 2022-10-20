local Utils = require "SelenScript.utils"
local ASTHelpers = require "SelenScript.transformer.ast_helpers"
local ASTNodes = ASTHelpers.Nodes


---@class Transformer_SS_to_Lua : Transformer
local TransformerDefs = {}


local _loop_types = {["while"]=true,["foriter"]=true,["forrange"]=true,["repeat"]=true}
---@param self Transformer_SS_to_Lua
---@param node ASTNode
TransformerDefs["continue"] = function(self, node)
	local parent_loop = self:find_parent_of_type(node, function(parent) return _loop_types[parent.type] end)
	if parent_loop == nil then
		self:add_error("CONTINUE_MISSING_LOOP", node)
		return nil
	end
	local parent_block = self:get_parent(node)
	if parent_block == nil or parent_block.type:sub(-5) ~= "block" then
		self:add_error("INTERNAL", node, "`continue` found parent node but that node isn't a block node?")
		return nil
	end
	local loop_block = (parent_loop or {}).block
	if loop_block == nil or loop_block.type:sub(-5) ~= "block" then
		self:add_error("INTERNAL", node, "`continue` found loop node but that node isn't a block node?")
		return nil
	end
	local label_name = self:get_var("continue")
	table.insert(loop_block, ASTNodes.label(node, label_name))
	table.insert(parent_block, ASTNodes["goto"](node, label_name))
	return nil
end

---@param self Transformer_SS_to_Lua
---@param node ASTNode
TransformerDefs["ifexpr"] = function(self, node)
	-- TODO: We might sometimes be able to just use lua expressions instead of needing the `if` statement before the assign
	--       This will probably depend on the type of whats used
	local block, stmt = self:find_parent_of_type(node, "block")
	if block == nil then
		self:add_error("INTERNAL", node, "`ifexpr` failed to find a parent block node.")
		return nil
	end
	local stmt_idx = Utils.find_key(block, stmt)
	local var_name = self:get_var("ifexpr")
	local local_assign_node = ASTNodes.assign(
		node, "local",
		ASTNodes.attributenamelist(node, ASTNodes.attributename(node, var_name))
	)
	local if_node = ASTNodes["if"](node, node.condition,
		ASTNodes.block(node,
			ASTNodes.assign(node, nil,
				ASTNodes.varlist(node, ASTNodes.index(node, nil, ASTNodes.name(node, var_name))),
				ASTNodes.expressionlist(node, node.lhs)
			)
		),
		ASTNodes["else"](node, ASTNodes.block(node,
			ASTNodes.assign(node, nil,
				ASTNodes.varlist(node, ASTNodes.index(node, nil, ASTNodes.name(node, var_name))),
				ASTNodes.expressionlist(node, node.rhs)
			)
		))
	)
	table.insert(block, stmt_idx, local_assign_node)
	table.insert(block, stmt_idx+1, if_node)
	return ASTNodes.index(node, nil, ASTNodes.name(node, var_name))
end

---@param self Transformer_SS_to_Lua
---@param node ASTNode
TransformerDefs["conditional_stmt"] = function(self, node)
	local block = ASTNodes.block(node, unpack(node))
	return ASTNodes["if"](node, node.condition, block)
end

---@param self Transformer_SS_to_Lua
---@param node ASTNode
TransformerDefs["functiondef"] = function(self, node)
	if node.decorators ~= nil and #node.decorators > 0 then
		local block, stmt = self:find_parent_of_type(node, "block")
		if block == nil then
			self:add_error("INTERNAL", node, "`functiondef` failed to find a parent block node.")
			return nil
		end
		local stmt_idx = Utils.find_key(block, stmt)
		local func_name = node.name  -- TODO: deal with ":" in node.name
		local call_node = func_name
		for i, dec in ipairs(node.decorators) do
			call_node = ASTNodes.index(node, nil, dec.expr, ASTNodes.call(node, call_node))
		end
		local assign_node = ASTNodes.assign(node, nil, ASTNodes.varlist(node, func_name), ASTNodes.expressionlist(node, call_node))
		table.insert(block, stmt_idx+1, assign_node)
		node.decorators = nil
	end
	return node
end


return TransformerDefs
