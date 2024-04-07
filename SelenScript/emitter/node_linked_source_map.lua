-- This file will be removed in the future, once a system for managing multiple files is worked on


local ReLabel = require "relabel"
local Json = require "json"
local SourceMapLib = require "source-map"


---@class NodeLinkedSourceMap
---@field links {node:ASTNode, src_pos:integer, out_pos:integer}[]
local NodeLinkedSourceMap = {}
NodeLinkedSourceMap.__index = NodeLinkedSourceMap


function NodeLinkedSourceMap.new()
	return setmetatable({
		links={}
	}, NodeLinkedSourceMap)
end

---@param node ASTNode # The source node that is being mapped
---@param src_pos number # The position in the output this node starts
---@param out_pos number # The position in the output this node starts
function NodeLinkedSourceMap:link(node, src_pos, out_pos)
	table.insert(self.links, {node=node, src_pos=src_pos, out_pos=out_pos})
end

---@param src string # The source code for line and column calculations
---@param out string # The output code for line and column calculations
function NodeLinkedSourceMap:generate(src, out, srcFile, outFile)
	table.sort(self.links, function (a, b)
		return a.out_pos > b.out_pos
	end)
	local sourceMap = SourceMapLib.new()
	sourceMap:setFile(outFile)
	for i, link in ipairs(self.links) do
		local src_start_ln, src_start_col = ReLabel.calcline(src, link.src_pos)
		local out_start_ln, out_start_col = ReLabel.calcline(out, link.out_pos)
		local name = type(link.node.name) == "string" and link.node.name or nil
		if link.node.value ~= nil then
			if name ~= nil then
				name = name .. "=" .. tostring(link.node.value)
			else
				name = "=" .. tostring(link.node.value)
			end
		end
		sourceMap:addSourceMapping(srcFile, src_start_ln, src_start_col, out_start_ln, out_start_col, name)
	end
	sourceMap:addSourceContent(srcFile, src)
	return Json.encode(sourceMap:toJson())
end


return NodeLinkedSourceMap
