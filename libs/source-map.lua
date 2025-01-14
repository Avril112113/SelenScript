-- Created by Avril112113
-- Only supports source-map version 3
-- Spec: https://docs.google.com/document/d/1U1RGAehQwRypUTovF1KRlpiOFze0b-_2gc6fAH0KY0k
-- The `sections` field is NOT supported

local Base64VQL = (function()
	-- Based on https://github.com/Rich-Harris/vlq/blob/master/src/index.js
	local charToInt = {}
	local intToChar = {}
	local BASE64_CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/="
	for i=1,#BASE64_CHARS do
		local char = BASE64_CHARS:sub(i, i)
		charToInt[char] = i-1
		intToChar[i-1] = char
	end
	local function encodeInt(n)
		local s = ""
		if n < 0 then
			n = bit.bor(bit.lshift(-n, 1), 1)
		else
			n = bit.lshift(n, 1)
		end
		repeat
			local clamped = bit.band(n, 31)
			n = bit.rshift(n, 5)
			if n > 0 then
				clamped = bit.bor(clamped, 32)
			end
			s = s .. intToChar[clamped]
		until not (n > 0)
		return s
	end
	return {
		---@param str string
		decode=function(str)
			local result = {}
			local shift = 0
			local value = 0
			for i=1,#str do
				local char = str:sub(i, i)
				local int = assert(charToInt[char], "Invalid base64 character")
				local hasContinuationBit = bit.band(int, 32) ~= 0
				int = bit.band(int, 31)
				value = value + bit.lshift(int, shift)
				if hasContinuationBit then
					shift = shift + 5
				else
					local shouldNegate = bit.band(value, 1) ~= 0
					value = bit.rshift(value, 1)
					if shouldNegate then
						table.insert(result, value == 0 and -0x80000000 or -value)
					else
						table.insert(result, value)
					end

					value = 0
					shift = 0
				end
			end
			return result
		end,
		---@param values number[]
		encode=function(values)
			local parts = {}
			for i, v in ipairs(values) do
				table.insert(parts, encodeInt(v))
			end
			return table.concat(parts)
		end,
	}
end)()

---@alias SourceMapColumnMapping {source:string,originalLine:number,originalColumn:number,generatedLine:number,generatedColumn:number,name:string?,generatedColumnFinish:number?}
---@class SourceMap
---@field version 3
---@field file string
---@field sourceRoot string
---@field sources string[]
---@field sourcesKVMap table<string,integer>
---@field sourcesContent table<string,string>
---@field names string[]
---@field namesKVMap table<string,integer>
---@field mappings SourceMapColumnMapping[][] # array<generatedLine, SourceMapFileMapping[sorted:>OriginalColumn]>
--- NOTE: originalLine and originalColumn starts at 1 (not for the json output)
local SourceMap = {
	__name = "SourceMap",
	WARN_WRONG_ORDER = false,
	WARN_OVERRIDE_COLUMN = false
}
SourceMap.__index = SourceMap


function SourceMap.new()
	return setmetatable({
		version=3,  -- We don't support any other version
		file="",
		sourceRoot="",
		sources={},
		sourcesKVMap={},
		sourcesContent={},
		names={},
		namesKVMap={},
		mappings={}
	}, SourceMap)
end

---@param tbl table<string, any>
function SourceMap.fromJson(tbl)
	local self = SourceMap.new()
	assert(tbl.version == self.version, "Unsupported source-map version")
	self.file = tbl.file
	self.sourceRoot = tbl.sourceRoot or self.sourceRoot
	self.sources = tbl.sources
	for i, v in ipairs(tbl.sources) do
		self.sourcesKVMap[v] = i
	end
	self.sourcesContent = tbl.sourcesContent or {}
	for i=1,#self.sources do
		if self.sourcesContent[i] == nil then
			self.sourcesContent[i] = false
		end
	end
	self.names = tbl.names or self.names
	for i, v in ipairs(self.names) do
		self.namesKVMap[v] = i
	end
	local sourceIndex = 1
	local originalLine = 1
	local originalColumn = 1
	local nameIndex = 1
	local generatedLine = 1
	for lineStr in tbl.mappings:gmatch("([^;]+)") do
		local generatedColumn = 1
		for columnStr in lineStr:gmatch("([^,]+)") do
			local mapping = Base64VQL.decode(columnStr)
			generatedColumn = generatedColumn + mapping[1]
			if #mapping >= 4 then
				sourceIndex = sourceIndex + mapping[2]
				originalLine = originalLine + mapping[3]
				originalColumn = originalColumn + mapping[4]
				if #mapping >= 5 then
					nameIndex = nameIndex + mapping[5]
				end
				self:addSourceMapping(
					self.sources[sourceIndex],
					originalLine,
					originalColumn,
					generatedLine,
					generatedColumn,
					#mapping >= 5 and self.names[nameIndex] or nil
				)
			end
		end
		generatedLine = generatedLine + 1
	end
	self:computeColumnSpans()
	return self
end

---@param file string
function SourceMap:setFile(file)
	self.file = file
end

---@param path string
function SourceMap:setSourceRoot(path)
	self.sourceRoot = path
end

---@param source string
function SourceMap:addSource(source)
	if self.sourcesKVMap[source] == nil then
		table.insert(self.sources, source)
		table.insert(self.sourcesContent, false)
		self.sourcesKVMap[source] = #self.sources
	end
end

---@param source string
---@param content string
function SourceMap:addSourceContent(source, content)
	if self.sourcesKVMap[source] == nil then
		self:addSource(source)
	end
	self.sourcesContent[self.sourcesKVMap[source]] = content
end

---@param name string
function SourceMap:addName(name)
	if self.namesKVMap[name] == nil then
		table.insert(self.names, name)
		self.namesKVMap[name] = #self.names
	end
end

---@param source string
---@param originalLine number
---@param originalColumn number
---@param generatedLine number
---@param generatedColumn number
---@param name string?
function SourceMap:addSourceMapping(source, originalLine, originalColumn, generatedLine, generatedColumn, name)
	self:addSource(source)  -- Adds if not already
	if name ~= nil then
		self:addName(name)  -- Adds if not already
	end
	-- This allows us to use `ipairs`, it saves complexity when converting to mappings to string
	for i=#self.mappings+1,generatedLine do
		self.mappings[i] = {}
	end
	local columnMappings = self.mappings[generatedLine]
	local insertPos = #columnMappings+1
	while true do
		local mapping = columnMappings[insertPos-1]
		if mapping == nil or mapping.generatedColumn < generatedColumn then
			break
		end
		insertPos = insertPos - 1
	end
	if self.WARN_WRONG_ORDER and insertPos ~= #columnMappings+1 then
		print("source-map warning: Added mapping in wrong order, this may affect performance.")
	end
	---@see SourceMapFileMapping
	local column = {
		originalLine = originalLine,
		originalColumn = originalColumn,
		generatedLine = generatedLine,
		generatedColumn = generatedColumn,
		name = name,
		source = source,
	}
	local prevMapping = columnMappings[insertPos-1]
	if prevMapping ~= nil and prevMapping.generatedColumn == generatedColumn then
		columnMappings[insertPos-1] = column
		if self.WARN_OVERRIDE_COLUMN then
			print("source-map warning: Overwriting previously mapped column.")
		end
	else
		table.insert(columnMappings, insertPos, column)
	end
end

--- NOTE: You will need to replace `false` values in `sourcesContent` with a value representing `null` for your json encoder
---@param optimise boolean? # Default true, will join separate sections for generated that are identical for original.
function SourceMap:toJson(optimise)
	local mapping = {}
	local lastSourceIndex = 0
	local lastOriginalLine = 0
	local lastOriginalColumn = 0
	local lastNameIndex = 0
	for generatedLine, columnMappings in ipairs(self.mappings) do
		local lastGeneratedColumn = 0
		local columnStrs = {}
		local last_values
		for _, column in ipairs(columnMappings) do
			local values = {
				column.generatedColumn - 1 - lastGeneratedColumn,
				self.sourcesKVMap[column.source] - 1 - lastSourceIndex,
				column.originalLine - 1 - lastOriginalLine,
				column.originalColumn - 1 - lastOriginalColumn
			}
			if column.name ~= nil then
				table.insert(values, self.namesKVMap[column.name] - 1 - lastNameIndex)
			end
			if optimise == false or last_values == nil or values[2] ~= 0 or values[3] ~= 0 or values[4] ~= 0 or (values[5] ~= last_values[5] and values[5] ~= 0) then
				table.insert(columnStrs, Base64VQL.encode(values))
				lastGeneratedColumn = column.generatedColumn - 1
				lastSourceIndex = self.sourcesKVMap[column.source] - 1
				lastOriginalLine = column.originalLine - 1
				lastOriginalColumn = column.originalColumn - 1
				if column.name ~= nil then
					lastNameIndex = self.namesKVMap[column.name] - 1
				end
			end
			last_values = values
		end
		table.insert(mapping, table.concat(columnStrs, ","))
	end
	local includeSourcesContent = false
	for i, v in pairs(self.sourcesContent) do
		if v ~= false then
			includeSourcesContent = true
			break
		end
	end
	return {
		version = self.version,
		file = self.file,
		sourceRoot = self.sourceRoot,
		sources = self.sources,
		sourcesContent = includeSourcesContent and self.sourcesContent or nil,
		names = self.names,
		mappings = table.concat(mapping, ";")
	}
end

function SourceMap:computeColumnSpans()
	for _, columnMappings in ipairs(self.mappings) do
		for i, column in ipairs(columnMappings) do
			local next = columnMappings[i+1]
			if next == nil then
				column.generatedColumnFinish = math.huge
			else
				column.generatedColumnFinish = next.generatedColumn-1
			end
		end
	end
end

--- Inclusive, spans must fall within and not partially outside of given range
---@param generatedLineStart number
---@param generatedColumnStart number
---@param generatedLineFinish number
---@param generatedColumnFinish number
---@return SourceMapColumnMapping[]
function SourceMap:getSpansInRange(generatedLineStart, generatedColumnStart, generatedLineFinish, generatedColumnFinish)
	local spans = {}
	local isSingleLine = generatedLineStart ~= generatedLineFinish
	for _, column in ipairs(self.mappings[generatedLineStart]) do
		if (not isSingleLine or column.generatedColumn >= generatedColumnStart) and column.generatedColumnFinish <= generatedColumnFinish then
			table.insert(spans, column)
		end
	end
	for i=generatedLineStart+1,generatedLineFinish-1 do
		for _, column in ipairs(self.mappings[i]) do
			table.insert(spans, column)
		end
	end
	if isSingleLine then
		for _, column in ipairs(self.mappings[generatedLineFinish]) do
			if column.generatedColumnFinish <= generatedColumnFinish then
				table.insert(spans, column)
			end
		end
	end
	return spans
end

---@param generatedLine number
---@param generatedColumn number?
---@return SourceMapColumnMapping[]
function SourceMap:getSpansAt(generatedLine, generatedColumn)
	if self.mappings[generatedLine] ~= nil then
		if generatedColumn == nil then
			return self.mappings[generatedLine]
		end
		local spans = {}
		for _, column in ipairs(self.mappings[generatedLine]) do
			if generatedColumn >= column.generatedColumn and generatedColumn <= column.generatedColumnFinish then
				table.insert(spans, column)
			end
		end
		return spans
	end
	return {}
end


return SourceMap
