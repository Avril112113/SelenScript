local Utils = {}


---@param path string
---@param binary boolean?
---@return string data
function Utils.readFile(path, binary)
	local f = assert(io.open(path, "r" .. (binary == true and "b" or "")))
	local data = f:read("*a")
	f:close()
	return data
end

---@param path string
---@param data string
---@param binary boolean?
function Utils.writeFile(path, data, binary)
	local f = assert(io.open(path, "w" .. (binary == true and "b" or "")))
	f:write(data)
	f:close()
end

function Utils.merge(from, into, overwrite)
	if overwrite == nil then overwrite = true end
	into = into or {}
	for i, v in pairs(from) do
		if overwrite or into[i] == nil then
			if type(v) == "table" then
				if into[i] ~= nil then
					Utils.merge(v, into[i])
				else
					into[i] = Utils.deepcopy(v)
				end
			else
				into[i] = v
			end
		elseif not overwrite and type(v) == "table" and type(into[i]) == "table" then
			Utils.merge(v, into[i], overwrite)
		end
	end
	return into
end

---@generic T : table
---@param tbl T
---@return T
function Utils.shallowcopy(tbl)
	local t = {}
	for i, v in pairs(tbl) do
		t[i] = v
	end
	return t
end

---@generic T : table
---@param tbl T
---@param preserve_mt boolean?
---@param references table?
---@return T
function Utils.deepcopy(tbl, preserve_mt, references)
	references = references or {}
	local t = {}
	references[tbl] = t
	for i, v in pairs(tbl) do
		if type(v) == "table" then
			t[i] = references[v] or Utils.deepcopy(v, preserve_mt, references)
			if preserve_mt then
				setmetatable(t[i], getmetatable(v))
			end
		else
			t[i] = v
		end
	end
	return t
end

-- Simplifed from https://gist.github.com/sapphyrus/fd9aeb871e3ce966cc4b0b969f62f539
function Utils.deepeq(t1, t2)
	if type(t1) ~= type(t2) then
		return false
	elseif type(t1) ~= "table" or type(t2) ~= "table" then
		return t1 == t2
	end

	-- iterate over t1
	for key1, value1 in pairs(t1) do
		local value2 = t2[key1]
		if value2 == nil or Utils.deepeq(value1, value2) == false then
			return false
		end
	end

	--- check keys in t2 but missing from t1
	for key2, _ in pairs(t2) do
		if t1[key2] == nil then return false end
	end
	return true
end

---@param tbl table
---@param value any
---@generic K, V
---@param iter (fun(table: table<K, V>, index?: K):K, V)?
---@return string|any?
function Utils.find_key(tbl, value, iter)
	iter = iter or pairs
	for i, v in iter(tbl) do
        if v == value then
            return i
        end
    end
    return nil
end

function Utils.keys_sort(a, b)
	if (type(a) == "number" and type(b) == "number") or (type(a) == "string" and type(b) == "string") then
		return a < b
	elseif type(a) == type(b) then
		return tostring(a) < tostring(b)
	elseif type(a) == "number" or type(b) == "number" then
		return type(a) == "number"
	else
		-- Fallback to *something* that does not error.
		return tostring(a) < tostring(b)
	end
end


---@generic K,V
---@param tbl table<K,V>
---@param comp? fun(a: K, b: K):boolean
---@return fun():K,V
function Utils.sorted_pairs(tbl, comp)
	local keys = {}
	for i, v in pairs(tbl) do
		table.insert(keys, i)
	end
	table.sort(keys, comp or Utils.keys_sort)
	local i = 0
	return function()
		i = i + 1
		if i > #keys then
			return nil
		end
		return keys[i], tbl[keys[i]]
	end
end

---@param text string
---@return string
function Utils.escape_pattern(text)
	return (text:gsub("(%W)", "%%%1"))
end

local ESCAPE_SEQUENCES_MAP = {
	["\a"]="\\a", ["\b"]="\\b", ["\f"]="\\f", ["\n"]="\\n", ["\r"]="\\r", ["\t"]="\\t", ["\v"]="\\v",
	["\\a"]="\\\\a", ["\\b"]="\\\\b", ["\\f"]="\\\\f", ["\\n"]="\\\\n", ["\\r"]="\\\\r", ["\\t"]="\\\\t", ["\\v"]="\\\\v",
}
---@param text string
---@return string
function Utils.escape_sequences(text)
	return (text:gsub("[\a\b\f\n\r\t\v]", function(s)
		return ESCAPE_SEQUENCES_MAP[s]
	end))
end
---@param text string
---@return string
function Utils.escape_escape_sequences(text)
	return (text:gsub("\\[abfnrtv]", function(s)
		return ESCAPE_SEQUENCES_MAP[s]
	end))
end

do
	---@diagnostic disable-next-line: param-type-mismatch
	local signum, hours, minutes = os.date("%z"):match("([+-])(%d%d)(%d%d)")
	Utils.timezone_offset = tonumber(signum..hours)*3600 + tonumber(signum..minutes)*60
end

--- Parse ISO format timestamp from the GitHub API
--- Returns time in UTC
---@param s string # Format of "2024-07-04T09:35:14Z"
function Utils.parse_github_timestamp(s)
	local t_date = {isdst=false}
	t_date.year, t_date.month, t_date.day, t_date.hour, t_date.min, t_date.sec = s:match("(%d+)%-(%d+)%-(%d+)T(%d+):(%d+):(%d+)Z")
	return t_date
end

--- Intended for debugging and error output.
---@param value any
function Utils.tostring(value)
	-- TODO: Improve this
	if type(value) == "string" then
		return ("%q"):format(value)
	end
	return tostring(value)
end


return Utils
