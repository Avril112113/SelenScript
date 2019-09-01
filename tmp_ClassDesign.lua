-- TODO: get metamethods woking on class', note that the names might need to be mangled
--       during transpilation but i do not wan't this

local __sls_addressCache = {}
local function getTblAddr(tbl)
	local mt = getmetatable(tbl)
	if __sls_addressCache[tbl] ~= nil then return __sls_addressCache[tbl] end
	local __tostring = mt.__tostring
	mt.__tostring = nil
	local address = tostring(tbl):gsub("^%w+: ", "")
	mt.__tostring = __tostring
	__sls_addressCache[tbl] = address
	return address
end


local function __sls_createClass(clsName)
	local cls = {
		__sls_clsName=clsName,
		__sls_inherits={}
	}
	function cls:__index(index)
		local value = rawget(cls, index)
		if value == nil then
			for _, v in ipairs(cls.inherits) do
				value = v[index]
				if value ~= nil then return value end
			end
		end
		return value
	end
	function cls:__call()
		if self ~= cls then error("attempt to call a object value (" .. tostring(self) .. ")", 1) end
		local obj = setmetatable({}, cls)
		return obj
	end
	function cls:__tostring()
		if cls == self then
			return "<Class " .. self.__sls_clsName .. " at " .. getTblAddr(self) .. ">"
		else
			return "<Object of " .. tostring(cls) .. " at " .. getTblAddr(self) .. ">"
		end
	end
	return setmetatable(cls, cls)
end


local ClassA = __sls_createClass("ClassA")
ClassA.t = "A"

local ClassB = __sls_createClass("ClassB")
ClassB.t = "B"

print("ClassA", ClassA)
print("ClassB", ClassB)
local objA = ClassA()
local objB = ClassB()
print("objA", objA)
print("objB", objB)

objA.t = "objA"
print("objA.t", objA.t)
print("objB.t", objB.t)
print("ClassA.t", ClassA.t)
print("ClassB.t", ClassB.t)

print("pcall(objA)", pcall(objA))
