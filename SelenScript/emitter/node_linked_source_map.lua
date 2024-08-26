local SourceMapLib = require "source-map"
local AvCalcline = require "avcalcline"


---@class SelenScript.NodeLinkedSourceMap
---@field links {node:SelenScript.ASTNodes.Node|SelenScript.ASTNodes.expression|SelenScript.ASTNodes.name, src_pos:integer, out_pos:integer}[]
local NodeLinkedSourceMap = {}
NodeLinkedSourceMap.__index = NodeLinkedSourceMap


function NodeLinkedSourceMap.new()
	return setmetatable({
		links={}
	}, NodeLinkedSourceMap)
end

---@param node SelenScript.ASTNodes.Node # The source node that is being mapped
---@param src_pos number # The position in the source this node starts
---@param out_pos number # The position in the output this node starts
function NodeLinkedSourceMap:link(node, src_pos, out_pos)
	table.insert(self.links, {node=node, src_pos=src_pos, out_pos=out_pos})
end

---@param outSrc string # The output code for line and column calculations
---@param outPath string # The output file path
function NodeLinkedSourceMap:generate(outSrc, outPath)
	table.sort(self.links, function (a, b)
		return a.out_pos > b.out_pos
	end)
	local out_avcalcline = AvCalcline.new(outSrc)
	local sourceMap = SourceMapLib.new()
	sourceMap:setFile(outPath)
	for i, link in ipairs(self.links) do
		---@type SelenScript.ASTNodes.Source
		local source_node = link.node.source
		if link.node.type == "source" then
			---@diagnostic disable-next-line: cast-local-type
			source_node = link.node
		elseif not link.node.source then
			print_warn(("Missing source field on node of type '%s'"):format(link.node.type))
			goto continue
		end
		local src_start_ln, src_start_col = source_node:calcline(link.src_pos)
		local out_start_ln, out_start_col = out_avcalcline:calcline(link.out_pos)
		local name = type(link.node.name) == "string" and link.node.name or nil
		if link.node.value ~= nil then
			if name ~= nil then
				name = name .. "=" .. tostring(link.node.value)
			else
				name = "=" .. tostring(link.node.value)
			end
		end
		sourceMap:addSourceMapping(source_node.file, src_start_ln, src_start_col, out_start_ln, out_start_col, name)
		if not sourceMap.sourcesContent[source_node.file] then
			sourceMap:addSourceContent(source_node.file, source_node.src)
		end
	    ::continue::
	end
	return sourceMap
end


return NodeLinkedSourceMap
