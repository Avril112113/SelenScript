-- Lib to read the output of `lpeglabel.ptree()` for grammar analysis.
-- `lpeglabel.ptree()` requires lpeglabel to be built with debug mode, which doesn't come with the default rockspec.


---@alias LPegTreeNode.Tag "char"|"set"|"any"|"true"|"false"|"utf8.range"|"rep"|"seq"|"choice"|"not"|"and"|"call"|"opencall"|"rule"|"xinfo"|"grammar"|"behind"|"capture"|"run-time"|"throw"
---@alias LPegTreeNode.CaptureKind "close"|"position"|"constant"|"backref"|"argument"|"simple"|"table"|"function"|"query"|"string"|"num"|"substitution"|"fold"|"runtime"|"group"

---@class SelenScript.GrammarTools.LPegPTree.Node
---@field [integer] SelenScript.GrammarTools.LPegPTree.Node
---@field tag LPegTreeNode.Tag
---@field raw string  # Raw data.
---@field n integer?  # xinfo: Index into grammar rules  grammar: child count?.
---@field key integer?  # Key index into keys
---@field rule integer?  # Rule index in grammar node of tree (root node)
---@field char string?  # A single char
---@field set {[1]:integer,[2]:integer?}[]?  # A set of 1 or 2 numbers, which represent a single or a range of chars respectively.
---@field kind LPegTreeNode.CaptureKind?


---@class SelenScript.GrammarTools.LPegPTree
---@field keys table<integer,string>
---@field names_map table<string,string>  # table<"...",name>
local LPegPTree = {}
LPegPTree.__index = LPegPTree


--- Flattens chains of seq and choice into one.
---@param node SelenScript.GrammarTools.LPegPTree.Node
function LPegPTree:_flatten_node(node, flattened)
	--- Recursively flatten nodes with a spesific tag,  
	--- where the 1st element is anything and the 2nd has the same tag.  
	--- Stops when the 2nd element is not the same tag, and moves both of it's elements to the initial node.  
	---@param node SelenScript.GrammarTools.LPegPTree.Node
	---@param tag LPegTreeNode.Tag
	local function _flatten_2s(node, tag)
		---@type SelenScript.GrammarTools.LPegPTree.Node
		local ptr = node
		while true do
			if ptr[2] and ptr[2].tag == tag then
				-- Ensure we don't duplicate the same node (initial node)
				if node ~= ptr then
					table.insert(node, ptr[1])
				end
				ptr = table.remove(ptr, 2)
			else
				-- Ensure we don't duplicate the same node
				-- This could happen by finishing on the initial node (because it's not chained)
				if node ~= ptr then
					-- Final 2 need to be moved.
					table.insert(node, ptr[1])
					table.insert(node, ptr[2])
				end
				break
			end
		end
	end

	flattened = flattened or {}
	if flattened[node] then return node end
	flattened[node] = true
	for i, v in ipairs(node) do
		if not flattened[v] then
			if v.tag == "seq" or v.tag == "choice" then
				_flatten_2s(v, v.tag)
			end
			self:_flatten_node(v, flattened)
		end
	end
	return node
end


---@param s string
function LPegPTree.new(s)
	local self = setmetatable({}, LPegPTree)
	self.keys = {}
	self.names_map = {}

	local lines = {}
	for line in s:gmatch("[^\n\r]+") do
		table.insert(lines, line)
	end
	local i = 1
	if lines[1]:sub(1, 2) == "=[" then
		self:process_names_array(lines[i])
		i = i + 1
	end
	self:process_keys_array(lines[i])
	i = i + 1
	self:process_tree(lines, i)

	return self
end

---@param line string
function LPegPTree:process_names_array(line)
	assert(line:sub(1, 2) == "=[" and line:sub(-1, -1) == "]")
	line = line:sub(3, -2)
	for name, value_str in line:gmatch("([%w_%d]+) = (%b\"\")  ") do
		self.names_map[value_str] = name
	end
end

---@param line string
function LPegPTree:process_keys_array(line)
	assert(line:sub(1, 1) == "[" and line:sub(-1, -1) == "]")
	line = line:sub(2, -2)
	for index, name in line:gmatch("(%d+) = ([^%s]+)  ") do
		self.keys[tonumber(index)] = name
	end
	for index, name in line:gmatch("(%d+) = (%b\"\")  ") do
		self.keys[tonumber(index)] = self.names_map[name] or name
	end
end

---@param lines string[]
---@param init integer
function LPegPTree:process_tree(lines, init)
	---@type SelenScript.GrammarTools.LPegPTree.Node[]
	local node_stack = {}
	for i=init,#lines do
		local line = lines[i]
		local depth = #line:match("^ *")/2 + 1

		local node = self:process_tree_line(line:match("^ *(.*)$"))

		local parent = node_stack[depth-1]
		if parent ~= nil then
			table.insert(parent, #parent+1, node)
		end
		while #node_stack >= depth do
			table.remove(node_stack, #node_stack)
		end
		table.insert(node_stack, #node_stack+1, node)
	end
	---@type SelenScript.GrammarTools.LPegPTree.Node
	self.tree = node_stack[1]
	self:_flatten_node(node_stack[1])
end

---@param line string
---@return SelenScript.GrammarTools.LPegPTree.Node
function LPegPTree:process_tree_line(line)
	local tag = line:match("^([%w-_]+)")
	---@type SelenScript.GrammarTools.LPegPTree.Node
	local node = {
		tag = tag,
		raw = line,
	}
	local f_name = "process_tag_" .. tag:gsub("%-", "_")
	local f = self[f_name]
	if f == nil then
		print_warn(("Missing tag handler for '%s'"):format(tag))
	else
		f(self, node, line:match("^%w+%s*(.*)$"))
	end
	return node
end

---@param node SelenScript.GrammarTools.LPegPTree.Node
---@param line string
function LPegPTree:process_tag_char(node, line)
	node.char = line:match("^'(.*)'$")
	if node.char == nil then
		local n = tonumber("0x" .. line:match("^%((.*)%)$"))
		node.char = n and string.char(n) or nil
	end
end

---@param node SelenScript.GrammarTools.LPegPTree.Node
---@param line string
function LPegPTree:process_tag_any(node, line)
end

---@param node SelenScript.GrammarTools.LPegPTree.Node
---@param line string
function LPegPTree:process_tag_set(node, line)
	if line:sub(1, 1) == "[" and line:sub(-1, -1) == "]" then
		node.set = {}
		for ns1, ns2 in line:gmatch("%(([^)-]*)%-?([^)]*)%)") do
			if ns2 then
				table.insert(node.set, {tonumber("0x" .. ns1), tonumber("0x" .. ns2)})
			else
				table.insert(node.set, {tonumber("0x" .. ns1)})
			end
		end
	end
end

---@param node SelenScript.GrammarTools.LPegPTree.Node
---@param line string
function LPegPTree:process_tag_true(node, line)
end

---@param node SelenScript.GrammarTools.LPegPTree.Node
---@param line string
function LPegPTree:process_tag_false(node, line)
end

-- TODO: utf8.range

---@param node SelenScript.GrammarTools.LPegPTree.Node
---@param line string
function LPegPTree:process_tag_rep(node, line)
end

---@param node SelenScript.GrammarTools.LPegPTree.Node
---@param line string
function LPegPTree:process_tag_seq(node, line)
end

---@param node SelenScript.GrammarTools.LPegPTree.Node
---@param line string
function LPegPTree:process_tag_choice(node, line)
end

---@param node SelenScript.GrammarTools.LPegPTree.Node
---@param line string
function LPegPTree:process_tag_not(node, line)
end

---@param node SelenScript.GrammarTools.LPegPTree.Node
---@param line string
function LPegPTree:process_tag_and(node, line)
end

---@param node SelenScript.GrammarTools.LPegPTree.Node
---@param line string
function LPegPTree:process_tag_call(node, line)
	local key, rule_index = line:match("^key: (%d+)  %(rule: (%d+)%)$")
	node.key = tonumber(key)
	node.rule = tonumber(rule_index)
end

-- TODO: opencall

---@param node SelenScript.GrammarTools.LPegPTree.Node
---@param line string
function LPegPTree:process_tag_rule(node, line)
	node.key = tonumber(line:match("^key: (%d+)$"))
end

---@param node SelenScript.GrammarTools.LPegPTree.Node
---@param line string
function LPegPTree:process_tag_xinfo(node, line)
	-- TODO: Figure out what this value really is
	node.n = tonumber(line:match("^n: (%d+)$"))
end

---@param node SelenScript.GrammarTools.LPegPTree.Node
---@param line string
function LPegPTree:process_tag_grammar(node, line)
	node.n = tonumber(line)
end

-- TODO: behind

---@param node SelenScript.GrammarTools.LPegPTree.Node
---@param line string
function LPegPTree:process_tag_capture(node, line)
	local kind, key = line:match("^kind: '([%w_]*)'  key: (%d*)$")
	node.kind, node.key = kind, tonumber(key)
end

---@param node SelenScript.GrammarTools.LPegPTree.Node
---@param line string
function LPegPTree:process_tag_run_time(node, line)
end

-- TODO: throw

---@param tree SelenScript.GrammarTools.LPegPTree.Node?
---@return string
function LPegPTree:tostring(tree)
	tree = tree or self.tree
	local json = require "json"
	local lines = {}
	if tree == self.tree then
		local names_parts = {}
		for id, rule in pairs(self.keys) do
			table.insert(names_parts, ("%s=%s"):format(id, rule))
		end
		table.insert(lines, table.concat(names_parts, " "))
		table.insert(lines, "")
	end
	local function recur_tree(node, depth)
		depth = depth or 0
		local fields = {}
		local node_sorted = {}
		for i, v in pairs(node) do
			table.insert(node_sorted, i)
		end
		table.sort(node_sorted, function(a, b)
			if type(a) == type(b) then
				return a > b
			end
			return type(a) > type(b)
		end)
		for _, i in pairs(node_sorted) do
			local v = node[i]
			if type(i) ~= "number" and i ~= "raw" and i ~= "tag" then
				if type(v) == "string" then
					v = ("'%s'"):format(v:gsub("\n", "\\n"):gsub("\r", "\\r"):gsub("\t", "\\t"))
				elseif type(v) == "table" then
					v = json.encode(v)
				elseif type(v) == "number" and i == "key" then
					v = self.keys[v] and ("#%s:%s"):format(v, self.keys[v]) or v
				elseif type(v) == "number" and i == "rule" then
					if self.tree[v + 1] and self.tree[v + 1].tag == "rule" then
						local name_index = self.tree[v + 1].key
						v = self.keys[name_index] and ("#%s:%s"):format(v, self.keys[name_index]) or v
					end
				end
				table.insert(fields, ("%s=%s"):format(i, v))
			end
		end
		table.insert(lines, ("%s%s %s"):format(string.rep("  ", depth), node.tag, table.concat(fields, " ")))
		for i, v in ipairs(node) do
			recur_tree(v, depth + 1)
		end
	end
	recur_tree(tree)
	return table.concat(lines, "\n")
end


return LPegPTree
