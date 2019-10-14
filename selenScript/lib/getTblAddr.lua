local addressCache = setmetatable({}, {__mode="k"})
local function getTblAddr(tbl)
	local mt = getmetatable(tbl)
	if addressCache[tbl] ~= nil then return addressCache[tbl] end
	local __tostring = rawget(mt, "__tostring")
	rawset(mt, "__tostring", nil)
	local address = tostring(tbl):gsub("^%w+: ", "")
	rawset(mt, "__tostring", __tostring)
	addressCache[tbl] = address
	return address
end

return getTblAddr
