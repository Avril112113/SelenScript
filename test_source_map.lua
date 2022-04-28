local SourceMapTraceback = {
	--- 0: Lua default
	--- 1: SelenScript simple (Uses Lua default with replacing, for compatibility)
	--- 2: SelenScript custom (Uses full custom, uses debug library extensively)
	mode = (debug~= nil and debug.getinfo ~= nil) and 2 or 1,

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

---@param mapdata string
local function parse_mapdata(mapdata)
	local lines = {}
	---@type string
	for linedata in mapdata:gmatch("(.-)\n") do
		-- These are all strings right now
		local
			out_start_ln, out_start_col,
			out_finish_ln, out_finish_col,
			src_start_ln, src_start_col,
			src_finish_ln, src_finish_col,
			node_type = linedata:match("^@(%d+):(%d+)~(%d+):(%d+)\t%->\t(%d+):(%d+)~(%d+):(%d+) %((%w+)%)")
		-- And we convert them to numbers
		out_start_ln, out_start_col = tonumber(out_start_ln), tonumber(out_start_col)
		out_finish_ln, out_finish_col = tonumber(out_finish_ln), tonumber(out_finish_col)
		src_start_ln, src_start_col = tonumber(src_start_ln), tonumber(src_start_col)
		src_finish_ln, src_finish_col = tonumber(src_finish_ln), tonumber(src_finish_col)
		local line = lines[out_start_ln] or {}
		lines[out_start_ln] = line
		table.insert(line, {
			out={
				start={line=out_start_ln, column=out_start_col},
				finish={line=out_finish_ln, column=out_finish_col},
			},
			src={
				start={line=src_start_ln, column=src_start_col},
				finish={line=src_finish_ln, column=src_finish_col},
			},
			node_type=node_type,
		})
	end
	return lines
end


local original_traceback = debug.traceback
---@param thread thread
---@param f number|fun()
---@param what string|"n"|"S"|"l"|"t"|"u"|"f"|"L"
local function getinfo(thread, f, what)
	if thread == nil then
		return debug.getinfo(f, what)
	end
	return debug.getinfo(thread, f, what)
end

---@param thread thread|nil
---@param message any|nil
---@param level number|nil
local function traceback_custom(thread, message, level)
	local iterlevel = level+2
	local stack = {}
	while true do
		local data = getinfo(thread, iterlevel, "nSlufL")
		if data == nil then break end
		if data.func ~= SourceMapTraceback.xpcall_handler then
			table.insert(stack, data)
		end
		iterlevel = iterlevel + 1
	end
	local stack_strs = {}
	local parts = {"Stack trace: " .. (message and tostring(message) or "")}
	for i, data in ipairs(stack) do
		local map = SourceMapTraceback.source_maps[data.short_src]
		if map == nil then
			-- TODO: This is very crude, fix this
			local mapdata = read_file(data.short_src .. ".map")
			SourceMapTraceback.source_maps[data.short_src] = mapdata and parse_mapdata(mapdata) or false
		end
		map = SourceMapTraceback.source_maps[data.short_src]
		local currentline = data.currentline
		local short_src = data.short_src
		if map then
			local line = map[currentline]
			if line ~= nil then
				currentline = line[1].src.start.line
				short_src = short_src:gsub("%.lua", ".sel")
			end
		end
		stack_strs[i] = {
			line = currentline >= 0 and tostring(currentline) or "",
			from = short_src,
			name = data.name or tostring(data.func),
		}
	end
	local stack_strs_lens = {}
	for i, strs in ipairs(stack_strs) do
		for name, v in pairs(strs) do
			if stack_strs_lens[name] == nil then
				stack_strs_lens[name] = #v
			elseif stack_strs_lens[name] < #v then
				stack_strs_lens[name] = #v
			end
		end
	end
	for i, strs in ipairs(stack_strs) do
		table.insert(parts, "\n\t" .. string.rep(" ", stack_strs_lens.from-#strs.from) .. strs.from .. " : " .. strs.name .. (#strs.line > 0 and " @ " .. strs.line or ""))
	end
	return table.concat(parts)
end

---@param thread thread|nil
---@param message any|nil
---@param level number|nil
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
			-- An extra newline gets added because of `message`, but the argument is required :c
			return original_traceback(message or "", level+2)
		end
		return original_traceback(thread, message, level+2)
	end
end

function SourceMapTraceback.xpcall_handler(...)
	print(SourceMapTraceback.traceback(...))
end

return SourceMapTraceback
