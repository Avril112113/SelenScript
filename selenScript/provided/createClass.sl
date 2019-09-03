if __sls_createClass == nil then
	function __sls_createClass(clsName)
		local cls = {
			__sls_clsName=clsName,
			__sls_inherits={}
		}
		function cls:__index(index)
			local value
			local __index = rawget(cls, "__sls__index")
			if __index ~= nil then value = __index(self, index) end
			value = rawget(cls, index)
			if value == nil then
				for _, v in ipairs(rawget(cls, "__sls_inherits")) do
					value = v[index]
					if value ~= nil then return value end
				end
			end
			return value
		end
		function cls:__call(...)
			local __call = rawget(cls, "__sls__call")
			if __call ~= nil then
				return __call(self, ...)
			end
			if self ~= cls then error("attempt to call a object value (" .. tostring(self) .. ")", 1) end
			local obj = setmetatable({}, cls)
			return obj
		end
		function cls:__tostring()
			local __tostring = rawget(cls, "__sls__tostring")
			if __tostring ~= nil then
				return __tostring(self)
			end
			if cls == self then
				return "<Class " .. self.__sls_clsName .. " at " .. __sls_getTblAddr(self) .. ">"
			else
				return "<Object of " .. tostring(cls) .. " at " .. __sls_getTblAddr(self) .. ">"
			end
		end
		return setmetatable(cls, cls)
	end
end
