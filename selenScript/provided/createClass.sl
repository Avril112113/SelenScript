if __sls_createClass == nil then
	local BaseClass = {
		__sls_clsName="BaseClass",
		__sls_inherits={}
	}
	BaseClass.__class = BaseClass
	function BaseClass:__index(index)
		local value
		local cls = rawget(self, "__class")
		value = rawget(cls, index)
		if value == nil then
			for _, v in ipairs(rawget(cls, "__sls_inherits")) do
				if v ~= self then
					value = v[index]
					if value ~= nil then return value end
				end
			end
		end
		return value
	end
	function BaseClass:__call(...)
		if self:is_class() then
			local obj = setmetatable({
				__class=self
			}, self)
			return obj
		else
			error("attempt to call an object value (" .. tostring(self) .. ")")
		end
	end
	function BaseClass:__tostring()
		if self:is_class() then
			return "<Class " .. self.__sls_clsName .. " at " .. __sls_getTblAddr(self) .. ">"
		else
			return "<Object of " .. tostring(self.__class) .. " at " .. __sls_getTblAddr(self) .. ">"
		end
	end
	function BaseClass:is_class()
		return rawget(self, "__sls_clsName") ~= nil
	end
	function __sls_createClass(clsName)
		local cls = {
			__sls_clsName=clsName,
			__sls_inherits={
				BaseClass
			}
		}
		cls.__class = cls
		cls.__index = BaseClass.__index
		return setmetatable(cls, cls)
	end
end
