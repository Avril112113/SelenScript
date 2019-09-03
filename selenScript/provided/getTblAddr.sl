if __sls_getTblAddr == nil or __sls_addressCache == nil then
	__sls_addressCache = setmetatable({}, {__mode="k"})
	function __sls_getTblAddr(tbl)local mt = getmetatable(tbl)
		if __sls_addressCache[tbl] ~= nil then return __sls_addressCache[tbl] end
		local __tostring = mt.__tostring
		mt.__tostring = nil
		local address = tostring(tbl):gsub("^%w+: ", "")
		mt.__tostring = __tostring
		__sls_addressCache[tbl] = address
		return address
	end
end