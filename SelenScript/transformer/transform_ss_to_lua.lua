local Utils = require "SelenScript.utils"
local ASTHelpers = require "SelenScript.transformer.ast_helpers"
local ASTNodes = ASTHelpers.Nodes


---@type Transformer
local TransformerDefs = {}


local _loop_types = {["while"]=true,["foriter"]=true,["forrange"]=true,["repeat"]=true}
---@param node ASTNode
TransformerDefs["continue"] = function(self, node)
	local parent_loop = self:find_parent_of_type(node, function(parent) return _loop_types[parent.type] end)
	if parent_loop == nil then
		self:add_error("CONTINUE_MISSING_LOOP", node)
		return nil
	end
	local parent_block = self:get_parent(node)
	if parent_block == nil or parent_block.type ~= "block" then
		self:add_error("INTERNAL", node, "`continue` found parent node but that node isn't a block node?")
		return nil
	end
	local loop_block = (parent_loop or {}).block
	if loop_block == nil or loop_block.type ~= "block" then
		self:add_error("INTERNAL", node, "`continue` found loop node but that node isn't a block node?")
		return nil
	end
	local label_name = self:get_var("continue")
	table.insert(loop_block, ASTNodes.label(node, label_name))
	table.insert(parent_block, ASTNodes["goto"](node, label_name))
	return nil
end

---@param node ASTNode
TransformerDefs["ifexpr"] = function(self, node)
	-- TODO: We might sometimes be able to just use lua expressions instead of needing the `if` statement before the assign
	local block, stmt = self:find_parent_of_type(node, "block")
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


return TransformerDefs
