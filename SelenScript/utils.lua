local Utils = {}


---@param path string
---@return string data
function Utils.readFile(path)
	local f = assert(io.open(path, "r"))
	local data = f:read("*a")
	f:close()
	return data
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

---@param tbl table
---@param value any
---@return string|any?
function Utils.find_key(tbl, value)
	for i, v in pairs(tbl) do
        if v == value then
            return i
        end
    end
    return nil
end


return Utils
