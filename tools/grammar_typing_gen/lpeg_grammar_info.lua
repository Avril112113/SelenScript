--- From a ptree, we would have to detect repeated sub-sections to figure out "+" and "^+"/"^-"
--- "?" - 1 or 0 (AKA Optional)
--- "*" - 0 or more
--- "/" - One of in captures
---@alias GrammarInfo.ContextMode "?"|"*"|"/"


---@class SelenScript.GrammarTools.GrammarInfo.CaptureBase
---@field __name string


--- Base grouping for many captures (has children).  
--- Can be used on it's own to add info for all subsequant children (eg, optional).  
--- Represents whatever it holds, usually put in the prior TableCapture.  
---@class SelenScript.GrammarTools.GrammarInfo.CaptureContext : SelenScript.GrammarTools.GrammarInfo.CaptureBase
---@field __name "capctx"
---@field captures SelenScript.GrammarTools.GrammarInfo.CaptureBase[]
---@field fields table<string,SelenScript.GrammarTools.GrammarInfo.CaptureBase>
---@field mode GrammarInfo.ContextMode?  # Only for "capctx", not it's super types

--- `rule <- ...`  
--- Represents the same as CaptureContext.  
---@class SelenScript.GrammarTools.GrammarInfo.Rule : SelenScript.GrammarTools.GrammarInfo.CaptureContext
---@field __name "rule"
---@field name string

--- `{| ... |}`  
--- Represents a lua table.  
---@class SelenScript.GrammarTools.GrammarInfo.TableCapture : SelenScript.GrammarTools.GrammarInfo.CaptureContext
---@field __name "table"

--- `{ ... }`  
--- Represents a lua string.  
---@class SelenScript.GrammarTools.GrammarInfo.SimpleCapture : SelenScript.GrammarTools.GrammarInfo.CaptureContext
---@field __name "simple"

--- Leaf capture (no children).  
---@class SelenScript.GrammarTools.GrammarInfo.LeafCapture : SelenScript.GrammarTools.GrammarInfo.CaptureBase

--- `{}`  
---@class SelenScript.GrammarTools.GrammarInfo.PositionCapture : SelenScript.GrammarTools.GrammarInfo.LeafCapture
---@field __name "position"

--- `... -> "foobar"`  
---@class SelenScript.GrammarTools.GrammarInfo.StringCapture : SelenScript.GrammarTools.GrammarInfo.LeafCapture
---@field __name "string"
---@field value string
---@field _from_chars true?

--- * Not found in relabel, the following is from drelabel  
--- `... -> {nil}` or `... -> {true}` or `... -> {false}`  
---@class SelenScript.GrammarTools.GrammarInfo.ConstantCapture : SelenScript.GrammarTools.GrammarInfo.LeafCapture
---@field __name "constant"
---@field value any

--- `... -> def_function`  
---@class SelenScript.GrammarTools.GrammarInfo.FunctionCapture : SelenScript.GrammarTools.GrammarInfo.LeafCapture
---@field __name "function"
---@field name string

--- `=field_capture_name`  
---@class SelenScript.GrammarTools.GrammarInfo.BackrefCapture : SelenScript.GrammarTools.GrammarInfo.LeafCapture
---@field __name "backref"
---@field name string

--- A lazy catch all for anything that could return a string.  
---@class SelenScript.GrammarTools.GrammarInfo.AnyCapture : SelenScript.GrammarTools.GrammarInfo.LeafCapture
---@field __name "any"

--- A lazy catch all for anything that could return a string.  
---@class SelenScript.GrammarTools.GrammarInfo.SetCapture : SelenScript.GrammarTools.GrammarInfo.LeafCapture
---@field __name "set"
---@field values string[]


---@class SelenScript.GrammarTools.GrammarInfo
---@field grammar_tree SelenScript.GrammarTools.LPegPTree
---@field function_captures table<string,false|SelenScript.GrammarTools.GrammarInfo.CaptureBase>
---@field ignored_call_rules table<string,true>
---@field rules table<string,SelenScript.GrammarTools.GrammarInfo.Rule>
local GrammarInfo = {}
GrammarInfo.__index = GrammarInfo


---@param grammar_tree SelenScript.GrammarTools.LPegPTree
---@param function_captures table<string,false|SelenScript.GrammarTools.GrammarInfo.CaptureBase>?
---@param ignored_call_rules table<string,true>?
function GrammarInfo.new(grammar_tree, function_captures, ignored_call_rules)
	local self = setmetatable({
		grammar_tree = grammar_tree,
		function_captures = function_captures or {},
		ignored_call_rules = ignored_call_rules or {},
		rules = {},
	}, GrammarInfo)
	self:_process()
	return self
end

---@param capctx SelenScript.GrammarTools.GrammarInfo.CaptureContext
function GrammarInfo:is_empty(capctx)
	return capctx.__name == "capctx" and next(capctx.fields) == nil and #capctx.captures == 0
end
---@param capctx SelenScript.GrammarTools.GrammarInfo.CaptureContext
function GrammarInfo:is_single(capctx)
	return capctx.__name == "capctx" and next(capctx.fields) == nil and #capctx.captures == 1 and capctx.mode == nil
end

function GrammarInfo:_process()
	--- Remove useless CaptureContext nodes
	---@param capctx SelenScript.GrammarTools.GrammarInfo.CaptureBase|SelenScript.GrammarTools.GrammarInfo.CaptureContext
	local function check_fold_context(capctx, folded)
		if not (capctx.captures and capctx.fields) then
			return
		end
		---@cast capctx -SelenScript.GrammarTools.GrammarInfo.CaptureBase

		folded = folded or {}
		if folded[capctx] then
			return
		end
		folded[capctx] = true

		if capctx.__name == "table" and next(capctx.fields) == nil and #capctx.captures == 1 and capctx.mode == nil then
			---@type SelenScript.GrammarTools.GrammarInfo.CaptureBase|SelenScript.GrammarTools.GrammarInfo.CaptureContext
			local sole_child = capctx.captures[1]
			if sole_child.__name == "capctx" and sole_child.mode == nil then
				capctx.captures[1] = nil
				if sole_child.captures then
					for i, v in ipairs(sole_child.captures) do
						capctx.captures[i] = v
					end
				end
				if sole_child.fields then
					for i, v in pairs(sole_child.fields) do
						capctx.fields[i] = v
					end
				end
			end
		end

		for i=#capctx.captures,1,-1 do
			local cap = capctx.captures[i]
			check_fold_context(cap, folded)
			---@diagnostic disable-next-line: param-type-mismatch
			if self:is_single(cap) then
				---@cast cap SelenScript.GrammarTools.GrammarInfo.CaptureContext
				capctx.captures[i] = cap.captures[1]
			end
		end
		for i, cap in pairs(capctx.fields) do
			check_fold_context(cap, folded)
			---@diagnostic disable-next-line: param-type-mismatch
			if self:is_single(cap) then
				---@cast cap SelenScript.GrammarTools.GrammarInfo.CaptureContext
				capctx.fields[i] = cap.captures[1]
			end
		end
	end

	---@param node SelenScript.GrammarTools.LPegPTree.Node
	---@param capctx SelenScript.GrammarTools.GrammarInfo.CaptureContext
	local function process_recur(node, capctx)
		if node.tag == "not" or node.tag == "and" then
			-- Ensure we ingore tags which don't consume input
			return
		elseif node.tag == "seq" then
			---@type SelenScript.GrammarTools.GrammarInfo.CaptureContext
			local new_capctx = {
				__name = "capctx",
				captures = {},
				fields = {},
			}
			table.insert(capctx.captures, new_capctx)
			capctx = new_capctx
		elseif node.tag == "rep" then
			---@type SelenScript.GrammarTools.GrammarInfo.CaptureContext
			local new_capctx = {
				__name = "capctx",
				captures = {},
				fields = {},
				mode = "*",
			}
			table.insert(capctx.captures, new_capctx)
			capctx = new_capctx
		elseif node.tag == "choice" then
			---@type SelenScript.GrammarTools.GrammarInfo.CaptureContext
			local new_capctx = {
				__name = "capctx",
				captures = {},
				fields = {},
				mode = node[2].tag == "true" and "?" or "/",
			}
			table.insert(capctx.captures, new_capctx)
			capctx = new_capctx
		elseif node.tag == "capture" then
			if node.kind == "position" then
				---@type SelenScript.GrammarTools.GrammarInfo.PositionCapture
				local capture_node = {
					__name = "position",
				}
				table.insert(capctx.captures, capture_node)
			elseif node.kind == "string" then
				---@type SelenScript.GrammarTools.GrammarInfo.StringCapture
				local capture_node = {
					__name = "string",
					value = self.grammar_tree.keys[node.key],
				}
				table.insert(capctx.captures, capture_node)
			elseif node.kind == "constant" then
				local value = self.grammar_tree.keys[node.key]
				-- node.key == 0 == nil
				if value == "\"true\"" then
					value = true
				elseif value == "\"false\"" then
					value = false
				end
				---@type SelenScript.GrammarTools.GrammarInfo.ConstantCapture
				local capture_node = {
					__name = "constant",
					value = value,
				}
				table.insert(capctx.captures, capture_node)
			elseif node.kind == "function" then
				local name = self.grammar_tree.keys[node.key]
				if self.function_captures[name] ~= nil then
					if self.function_captures[name] then
						table.insert(capctx.captures, self.function_captures[name])
					end
				else
					---@type SelenScript.GrammarTools.GrammarInfo.FunctionCapture
					local capture_node = {
						__name = "function",
						name = name,
					}
					table.insert(capctx.captures, capture_node)
				end
			elseif node.kind == "backref" then
				---@type SelenScript.GrammarTools.GrammarInfo.BackrefCapture
				local capture_node = {
					__name = "backref",
					name = self.grammar_tree.keys[node.key],
				}
				table.insert(capctx.captures, capture_node)
			elseif node.kind == "simple" then
				---@type SelenScript.GrammarTools.GrammarInfo.SimpleCapture
				local new_capctx = {
					__name = "simple",
					captures = {},
					fields = {},
				}
				table.insert(capctx.captures, new_capctx)
				capctx = new_capctx
			elseif node.kind == "group" then
				---@type SelenScript.GrammarTools.GrammarInfo.CaptureContext
				local new_capctx = {
					__name = "capctx",
					captures = {},
					fields = {},
				}
				capctx.fields[self.grammar_tree.keys[node.key]] = new_capctx
				capctx = new_capctx
			elseif node.kind == "table" then
				---@type SelenScript.GrammarTools.GrammarInfo.TableCapture
				local new_capctx = {
					__name = "table",
					captures = {},
					fields = {},
				}
				table.insert(capctx.captures, new_capctx)
				capctx = new_capctx
			else
				error(("Unhandled capture kind '%s'"):format(node.kind))
			end
		elseif node.tag == "call" then
			local rule = self.rules[self.grammar_tree.keys[node.key]]
			if not self.ignored_call_rules[rule.name] then
				table.insert(capctx.captures, rule)
			end
		elseif node.tag == "set" then
			---@type SelenScript.GrammarTools.GrammarInfo.SetCapture
			local capture_node = {
				__name = "set",
				values = {},
			}
			for i, v in ipairs(node.set) do
				for byte=v[1],v[2] or v[1] do
					table.insert(capture_node.values, string.char(byte))
				end
			end
			table.insert(capctx.captures, capture_node)
		elseif node.tag == "char" then
			local last_cap = capctx.captures[#capctx.captures]
			---@diagnostic disable-next-line: undefined-field
			if last_cap and last_cap.__name == "string" and last_cap._from_chars and capctx.mode ~= "/" then
				---@cast last_cap SelenScript.GrammarTools.GrammarInfo.StringCapture
				last_cap.value = last_cap.value .. node.char
			else
				---@type SelenScript.GrammarTools.GrammarInfo.StringCapture
				local capture_node = {
					__name = "string",
					value = node.char,
					_from_chars = true,
				}
				table.insert(capctx.captures, capture_node)
			end
		elseif node.tag == "any" or node.tag == "utf8.range" then
			---@type SelenScript.GrammarTools.GrammarInfo.AnyCapture
			local capture_node = {
				__name = "any",
			}
			table.insert(capctx.captures, capture_node)
		end
		for i, child in ipairs(node) do
			process_recur(child, capctx)
		end
	end

	assert(self.grammar_tree.tree.tag == "grammar")
	for i, rule_node in ipairs(self.grammar_tree.tree) do
		assert(rule_node.tag == "rule")
		local xinfo = rule_node[1]
		assert(xinfo.tag == "xinfo")
		-- No idea why we are getting a rule with key of `0`
		if rule_node.key == 0 then
			goto continue
		end
		local name = self.grammar_tree.keys[rule_node.key]
		---@type SelenScript.GrammarTools.GrammarInfo.Rule
		local rule_capture = {
			__name = "rule",
			name = name,
			captures = {},
			fields = {},
		}
		self.rules[name] = rule_capture
	    ::continue::
	end
	for i, rule_node in ipairs(self.grammar_tree.tree) do
		assert(rule_node.tag == "rule")
		local xinfo = rule_node[1]
		assert(xinfo.tag == "xinfo")
		-- No idea why we are getting a rule with key of `0`
		if rule_node.key == 0 then
			goto continue
		end
		local name = self.grammar_tree.keys[rule_node.key]
		local rule_capture = self.rules[name]
		process_recur(xinfo, rule_capture)
		check_fold_context(rule_capture)
	    ::continue::
	end
end


return GrammarInfo
