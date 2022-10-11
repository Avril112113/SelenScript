local SourceMap = require "source-map"
local json = require "json"


local SourceMapTraceback = {
	--- 0: Lua default (Simply does nothing)
	--- 1: SelenScript simple (Default Lua traceback, replacing parts instead of using debug library)
	--- 2: SelenScript custom (Custom Selenscript traceback, requires debug library)
	mode = (debug~= nil and debug.getinfo ~= nil) and 2 or 1,

	---@type table<string,SourceMap>
	source_maps = {},
}


---@param path string
local function read_file(path)
	local f = io.open(path, "r")
	if f == nil then return nil end
	local data = f:read("*a")
	f:close()
	return data
end

local original_traceback = debug.traceback
---@param thread thread?
---@param f number|fun()
---@param what string|"n"|"S"|"l"|"t"|"u"|"f"|"L"
local function getinfo(thread, f, what)
	if thread == nil then
		return debug.getinfo(f, what)
	end
	return debug.getinfo(thread, f, what)
end

---@param thread thread?
---@param message any?
---@param level number?
local function traceback_custom(thread, message, level)
	local iterLevel = level+2
	local stack = {}
	while true do
		local data = getinfo(thread, iterLevel, "nSlufL")
		if data == nil then break end
		if data.func ~= SourceMapTraceback.xpcall_handler then
			table.insert(stack, data)
		end
		iterLevel = iterLevel + 1
	end
	local stackStrs = {}
	local parts = {"Stack trace: " .. (message and tostring(message) or "")}
	for i, data in ipairs(stack) do
		local sourceMap = SourceMapTraceback.source_maps[data.short_src]
		if sourceMap == nil then
			local mappingData = read_file(data.short_src .. ".map")
			SourceMapTraceback.source_maps[data.short_src] = mappingData and SourceMap.fromJson(json.decode(mappingData))
		end
		---@type SourceMap
		sourceMap = SourceMapTraceback.source_maps[data.short_src]
		local currentLine = data.currentline
		local shortSrc = data.short_src
		if sourceMap then
			local spans = sourceMap:getSpansAt(currentLine)
			if #spans >= 1 then
				currentLine = spans[1].originalLine
				shortSrc = spans[1].source
			end
		end
		stackStrs[i] = {
			line = currentLine >= 0 and tostring(currentLine) or "",
			from = shortSrc,
			name = data.name or tostring(data.func),
		}
	end
	local longestStackStr = 0
	for i, strs in ipairs(stackStrs) do
		for name, v in pairs(strs) do
			if #v > longestStackStr then
				longestStackStr = #v
			end
		end
	end
	for i, strs in ipairs(stackStrs) do
		table.insert(parts, ("\n\t%" .. longestStackStr .. "s : %s%s"):format(strs.from, strs.name, #strs.line > 0 and " @ " .. strs.line or ""))
	end
	return table.concat(parts)
end

---@param thread thread?
---@param message any?
---@param level number?
---@overload fun(message: string, level: number): string
---@overload fun(message: string): string
---@return string
function SourceMapTraceback.traceback(thread, message, level)
	if type(thread) ~= "thread" then
		level = message
		message = thread
		thread = nil
	end
	if level == nil then
		level = 0
	end
	if SourceMapTraceback.mode == 1 then
		return "TODO: SourceMapTraceback.mode=1"
	elseif SourceMapTraceback.mode == 2 then
		return traceback_custom(thread, message, level)
	else
		if thread == nil then
			-- FIXME: An extra newline gets added because of `message`, but the argument is required :c
			return original_traceback(message or "", level+2)
		end
		return original_traceback(thread, message, level+2)
	end
end

function SourceMapTraceback.xpcall_handler(...)
	print(SourceMapTraceback.traceback(...))
end

return SourceMapTraceback
