local relabel = require "relabel"


local SourceMap = {}
SourceMap.__index = SourceMap


function SourceMap.new()
	return setmetatable({
		links={}
	}, SourceMap)
end

---@param node ASTNode @ The source node that is being mapped
---@param start number @ The position in the output this node starts
---@param finish number @ The position in the output this node finishes
function SourceMap:link(node, start, finish)
	table.insert(self.links, {node=node, start=start, finish=finish})
end

---@param src string @ The source code for line and column calculations
---@param out string @ The output code for line and column calculations
function SourceMap:generate(src, out)
	table.sort(self.links, function (a, b)
		return a.start == b.start and a.node.start < b.node.start or a.start < b.start
	end)
	local parts = {}
	for i, link in ipairs(self.links) do
		local out_start_ln, out_start_col = relabel.calcline(out, link.start)
		local out_finish_ln, out_finish_col = relabel.calcline(out, link.finish)
		table.insert(parts, "@" .. out_start_ln .. ":" .. out_start_col)
		table.insert(parts, "~")
		table.insert(parts, out_finish_ln .. ":" .. out_finish_col)
		table.insert(parts, "\t->\t")
		local src_start_ln, src_start_col = relabel.calcline(src, link.node.start)
		local src_finish_ln, src_finish_col = relabel.calcline(src, link.node.finish)
		table.insert(parts, src_start_ln .. ":" .. src_start_col)
		table.insert(parts, "~")
		table.insert(parts, src_finish_ln .. ":" .. src_finish_col)
		table.insert(parts, " (" .. link.node.type .. ")")
		if type(link.node.name) == "string" then
			table.insert(parts, " `" .. tostring(link.node.name) .. "`")
		end
		if link.node.value ~= nil then
			table.insert(parts, " " .. tostring(link.node.value))
		end
		table.insert(parts, "\n")
	end
	return table.concat(parts)
end


return SourceMap
