local addressCache = setmetatable({}, {__mode="k"})
local function getTblAddr(tbl)
	local mt = getmetatable(tbl)
	setmetatable(tbl, nil)
	if addressCache[tbl] ~= nil then return addressCache[tbl] end
	local address = tostring(tbl):gsub("^%w+: ", "")
	setmetatable(tbl, mt)
	addressCache[tbl] = address
	return address
end

return getTblAddr
