-- This file will be removed in the future, once a system for managing multiple files is worked on


local ReLabel = require "relabel"
local Json = require "json"
local SourceMapLib = require "source-map"


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
function SourceMap:generate(src, out, srcFile, outFile)
	table.sort(self.links, function (a, b)
		return a.start > b.start
	end)
	local sourceMap = SourceMapLib.new()
	sourceMap:setFile(outFile)
	for i, link in ipairs(self.links) do
		local out_start_ln, out_start_col = ReLabel.calcline(out, link.start)
		local out_finish_ln, out_finish_col = ReLabel.calcline(out, link.finish)
		local src_start_ln, src_start_col = ReLabel.calcline(src, link.node.start)
		local src_finish_ln, src_finish_col = ReLabel.calcline(src, link.node.finish)
		local name
		-- local name = type(link.node.name) == "string" and link.node.name or nil
		-- if link.node.value ~= nil then
		-- 	if name ~= nil then
		-- 		name = name .. "=" .. tostring(link.node.value)
		-- 	else
		-- 		name = "=" .. tostring(link.node.value)
		-- 	end
		-- end
		sourceMap:addSourceMapping(srcFile, src_start_ln, src_start_col, out_start_ln, out_start_col, name)
		sourceMap:addSourceMapping(srcFile, src_finish_ln, src_finish_col, out_finish_ln, out_finish_col)
	end
	return Json.encode(sourceMap:toJson())
end


return SourceMap
