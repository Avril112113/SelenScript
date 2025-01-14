local Utils = require "SelenScript.utils"
local ASTNodes = require "SelenScript.parser.ast_nodes"
local Precedence = require "SelenScript.parser.precedence"
local Errors = require "SelenScript.transformer.errors"


---@class SelenScript.Transformer_SS_to_Lua : SelenScript.Transformer
local TransformerDefs = {}


local _loop_types = {["while"]=true,["foriter"]=true,["forrange"]=true,["repeat"]=true}
---@param self SelenScript.Transformer_SS_to_Lua
---@param node SelenScript.ASTNodes.continue
TransformerDefs["continue"] = function(self, node)
	local parent_loop = self:find_parent_of_type(node, function(parent) return _loop_types[parent.type] end)
	---@cast parent_loop nil|SelenScript.ASTNodes.while|SelenScript.ASTNodes.foriter|SelenScript.ASTNodes.forrange|SelenScript.ASTNodes.repeat
	if parent_loop == nil then
		self:add_error("CONTINUE_MISSING_LOOP", node)
		return nil
	end
	local parent_block = self:get_parent(node)
	if parent_block == nil or parent_block.type:sub(-5) ~= "block" then
		self:add_error("INTERNAL", node, "`continue` found parent node but that node isn't a block node?")
		return nil
	end
	---@type SelenScript.ASTNodes.block?
	local loop_block = (parent_loop or {}).block
	if loop_block == nil or loop_block.type:sub(-5) ~= "block" then
		self:add_error("INTERNAL", node, "`continue` found loop node but that node isn't a block node?")
		return nil
	end
	local label_name = self:get_var("continue")
	table.insert(parent_block, ASTNodes["label"]{
		_parent = node,
		name = label_name,
	})
	return ASTNodes["goto"]{
		_parent = node,
		name = label_name,
	}
end

---@param self SelenScript.Transformer_SS_to_Lua
---@param node SelenScript.ASTNodes.ifexpr
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
	local local_assign_node = ASTNodes["assign"]{
		_parent = node,
		scope = "local",
		names = ASTNodes["attributenamelist"]{
			_parent = node,
			ASTNodes["attributename"]{
				_parent = node,
				var_name
			}
		},
	}
	local if_node = ASTNodes["if"]{
		_parent = node,
		condition = node.condition,
		block = ASTNodes["block"]{ _parent = node,
			ASTNodes["assign"]{
				_parent = node,
				names = ASTNodes["varlist"]{
					_parent = node,
					ASTNodes["index"]{
						_parent = node,
						ASTNodes["name"]{
							_parent = node,
							name = var_name,
						}
					}
				},
				values = ASTNodes["expressionlist"]{
					_parent = node,
					node.lhs
				},
			},
		},
		["else"] = ASTNodes["else"]{
			_parent = node,
			block = ASTNodes["block"]{ _parent = node,
			ASTNodes["assign"]{
				_parent = node,
				names = ASTNodes["varlist"]{
					_parent = node,
					ASTNodes["index"]{
						_parent = node,
						ASTNodes["name"]{
							_parent = node,
							name = var_name,
						}
					}
				},
				values = ASTNodes["expressionlist"]{
					_parent = node,
					node.rhs
				},
			},
		},
		},
	}
	table.insert(block, stmt_idx, local_assign_node)
	table.insert(block, stmt_idx+1, if_node)
	return ASTNodes["index"]{
		_parent = node,
		expr = ASTNodes["name"]{
			_parent = node,
			name = var_name,
		}
	}
end

---@param self SelenScript.Transformer_SS_to_Lua
---@param node SelenScript.ASTNodes.stmt_expr
TransformerDefs["stmt_expr"] = function(self, node)
	local block, stmt = self:find_parent_of_type(node, "block")
	if block == nil then
		self:add_error("INTERNAL", node, "`stmt_expr` failed to find a parent block node.")
		return nil
	end
	local stmt_idx = Utils.find_key(block, stmt)
	node._var_name = node._var_name or self:get_var("stmt_expr_" .. node.stmt.type)
	local local_assign_node = ASTNodes["assign"]{
		_parent = node,
		scope = "local",
		names = ASTNodes["attributenamelist"]{
			_parent = node,
			ASTNodes["attributename"]{
				_parent = node,
				name = node._var_name
			}
		},
		values = ASTNodes["expressionlist"]{
			_parent = node,
			ASTNodes["table"]{
				_parent = node,
				fields = ASTNodes["fieldlist"]{
					_parent = node
				}
			}
		}
	}
	table.insert(block, stmt_idx, local_assign_node)
	table.insert(block, stmt_idx+1, node.stmt)
	return ASTNodes["expressionlist"]{
		_parent = node,
		ASTNodes["index"]{
			_parent = node,
			expr = ASTNodes["name"]{
				_parent = node,
				name = "unpack",
			},
			index = ASTNodes["call"]{
				_parent = node,
				args = ASTNodes["expressionlist"]{
					_parent = node,
					ASTNodes["index"]{
						_parent = node,
						expr = ASTNodes["name"]{
							_parent = node,
							name = node._var_name
						},
					},
				},
			},
		},
	}
end

---@param self SelenScript.Transformer_SS_to_Lua
---@param node SelenScript.ASTNodes.break
TransformerDefs["break"] = function(self, node)
	-- We inject fields
	---@class SelenScript.ASTNodes.stmt_expr
	local stmt_expr, _, _ = self:find_parent_of_type(node, "stmt_expr")
	---@diagnostic disable-next-line: cast-type-mismatch
	---@cast stmt_expr nil|SelenScript.ASTNodes.stmt_expr
	if stmt_expr ~= nil and #node.values > 0 then
		local parent_breakable, _, _ = self:find_parent_of_type(node, function(filter_node)
			return filter_node.type == "while" or filter_node.type == "forrange" or filter_node.type == "foriter" or filter_node.type == "do"
		end)
		---@cast parent_breakable nil|SelenScript.ASTNodes.while|SelenScript.ASTNodes.forrange|SelenScript.ASTNodes.foriter|SelenScript.ASTNodes.do
		if (stmt_expr.stmt ~= parent_breakable) then
			self:add_error("BREAK_VALUES_NON_EXPR", node)
			return node
		end
		local block, stmt = self:find_parent_of_type(node, "block")
		if block == nil then
			self:add_error("INTERNAL", node, "`break` failed to find a parent block node.")
			return nil
		end
		local stmt_idx = Utils.find_key(block, stmt)
		stmt_expr._var_name = stmt_expr._var_name or self:get_var("stmt_expr_" .. stmt_expr.stmt.type)
		local fields = {}
		for i, value_node in ipairs(node.values) do
			table.insert(fields, ASTNodes["field"]{_parent=node, value=value_node})
		end
		local assign_node = ASTNodes["assign"]{
			_parent = node,
			names = ASTNodes["varlist"]{
				_parent = node,
				ASTNodes["index"]{
					_parent = node,
					expr = ASTNodes["name"]{
						_parent = node,
						name = stmt_expr._var_name,
					},
				},
			},
			values = ASTNodes["expressionlist"]{
				_parent = node,
				ASTNodes["table"]{
					_parent = node,
					fields = ASTNodes["fieldlist"]{
						_parent = node,
						unpack(fields)
					},
				},
			},
		}
		table.insert(block, stmt_idx, assign_node)
		node.values = nil
		if stmt_expr.stmt.type == "do" then
			local stmt_expr_block = stmt_expr.stmt.block
			local label_node = stmt_expr_block[#stmt_expr_block]
			-- TODO: Our label might not be last right now? Ideally this should be within last set of labels in the block
			local is_our_label_last = label_node ~= node and (label_node == nil or label_node.type ~= "label" or label_node.name.name ~= stmt_expr._var_name)
			-- TODO: Remove redundant `goto` when a label is in use but this `return` is at the end
			if stmt_expr_block[#stmt_expr_block] ~= node then
				table.insert(block, stmt_idx+1, ASTNodes["goto"]{
					_parent = node,
					name = stmt_expr._var_name,
				})
			end
			if is_our_label_last then
				table.insert(stmt_expr_block, #stmt_expr_block+1, ASTNodes["label"]{
					_parent = node,
					name = stmt_expr._var_name,
				})
			end
			return nil
		else
			return node
		end
	elseif #node.values > 0 then
		self:add_error(Errors.BREAK_VALUES_NON_EXPR, node)
	end
	return node
end

---@param self SelenScript.Transformer_SS_to_Lua
---@param node SelenScript.ASTNodes.conditional_stmt
TransformerDefs["conditional_stmt"] = function(self, node)
	return ASTNodes["if"]{
		_parent = node,
		condition = node.condition,
		block = ASTNodes["block"]{
			_parent = node,
			unpack(node),
		},
	}
end

---@param self SelenScript.Transformer_SS_to_Lua
---@param node SelenScript.ASTNodes.functiondef
TransformerDefs["functiondef"] = function(self, node)
	if node.decorators ~= nil and #node.decorators > 0 then
		local block, stmt = self:find_parent_of_type(node, "block")
		if block == nil then
			self:add_error("INTERNAL", node, "`functiondef` failed to find a parent block node.")
			return nil
		end
		local stmt_idx = Utils.find_key(block, stmt)
		local func_name = node.name  -- TODO: deal with ":" in node.name
		if func_name.type == "name" then
			---@cast func_name -SelenScript.ASTNodes.name
			func_name = ASTNodes["index"]{
				_parent = func_name,
				expr = func_name,
			}
		end
		local dec_end_pos = node.start
		local call_node = func_name
		for i, dec in ipairs(node.decorators) do
			local root = Utils.shallowcopy(dec.expr)
			---@type SelenScript.ASTNodes.index|SelenScript.ASTNodes.call
			local call = root
			while true do
				if call.expr.type == "call" then
					call.expr = Utils.shallowcopy(call.expr)
					---@diagnostic disable-next-line: cast-local-type
					call = call.expr
					break
				elseif not call.index then
					call.index = ASTNodes["call"]{ _parent = dec.expr }
					call = call.index
					break
				end
				call.index = Utils.shallowcopy(call.index)
				call = call.index
				if call.type == "call" then
					break
				end
			end
			---@cast call -SelenScript.ASTNodes.index, -?
			call.args = call.args and Utils.shallowcopy(call.args) or ASTNodes["expressionlist"]{ _parent = call }
			table.insert(call.args, 1, call_node)
			call_node = ASTNodes["index"]{
				_parent = node,
				expr = root,
			}

			dec_end_pos = math.max(dec_end_pos, dec.finish)
		end
		local assign_node = ASTNodes["assign"]{
			_parent = node,
			names = ASTNodes["varlist"]{
				_parent = node,
				func_name
			},
			values = ASTNodes["expressionlist"]{
				_parent = node,
				call_node,
			},
		}
		table.insert(block, stmt_idx+1, assign_node)
		node.decorators = nil

		node.start_source = dec_end_pos
	end
	return node
end

---@param self SelenScript.Transformer_SS_to_Lua
---@param node SelenScript.ASTNodes.op_assign
TransformerDefs["op_assign"] = function(self, node)
	local values = ASTNodes["expressionlist"]{_parent=node.values}
	for i=1,math.max(#node.names, #node.values) do
		local name, value = node.names[i], node.values[i]
		if name and value then
			local op_node_name = Precedence.binaryOpData[node.op][2]
			table.insert(values, ASTNodes[op_node_name]{
				_parent = node,
				lhs = name,
				op = node.op,
				rhs = value,
			})
		elseif value then
			-- It's invalid, but make the output valid lua anyway.
			table.insert(values, value)
		end
	end
	return ASTNodes["assign"]{
		_parent = node,
		scope = "default",
		names = node.names,
		values = values,
	}
end


return TransformerDefs
