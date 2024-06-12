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

---@param text string
---@return string
function Utils.escape_pattern(text)
	return (text:gsub("(%W)", "%%%1"))
end


return Utils
