local Utils = {}


---@param path string
---@return string data
function Utils.readFile(path)
	local f = assert(io.open(path, "r"))
	local data = f:read("*a")
	f:close()
	return data
end

---@param path string
---@param data string
function Utils.writeFile(path, data)
	local f = assert(io.open(path, "w"))
	f:write(data)
	f:close()
end

---@param modpath string
---@return string
function Utils.modPathParent(modpath)
	return (modpath:gsub("(.*)%..*$","%1"))
end

---@param modpath string
---@return string
function Utils.modPathToPath(modpath)
	return (modpath:gsub("%.", "/"))
end

---@param modpath string
---@return string
function Utils.modPathToDir(modpath)
	return (modpath:gsub("%.", "/"):gsub("(.*)/.*$","%1"))
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
---@return T
function Utils.deepcopy(tbl)
	local t = {}
	for i, v in pairs(tbl) do
		if type(v) == "table" then
			t[i] = Utils.deepcopy(v)
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


return Utils
