local Utils = {}


function Utils.readFile(path)
	local f = assert(io.open(path, "r"))
	local data = f:read("*a")
	f:close()
	return data
end

function Utils.modPathParent(modpath)
	return modpath:gsub("(.*)%..*$","%1")
end

function Utils.modPathToPath(modpath)
	return modpath:gsub("%.", "/")
end

function Utils.modPathToDir(modpath)
	return modpath:gsub("%.", "/"):gsub("(.*)/.*$","%1")
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

function Utils.shallowcopy(tbl)
	local t = {}
	for i, v in pairs(tbl) do
		t[i] = v
	end
	return t
end

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


return Utils
