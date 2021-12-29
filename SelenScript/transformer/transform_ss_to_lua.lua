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
	-- TODO: make AST easier to generate
	table.insert(loop_block, {
		type = "label",
		start = node.start,
		name = {type="name", name=label_name},
		finish = node.finish,
	})
	table.insert(parent_block, {
		type = "goto",
		start = node.start,
		name = {type="name", name=label_name},
		finish = node.finish,
	})
	return nil
end


return TransformerDefs
