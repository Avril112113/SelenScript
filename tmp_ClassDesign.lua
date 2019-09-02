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
			return "<Class " .. self.__sls_clsName .. " at " .. getTblAddr(self) .. ">"
		else
			return "<Object of " .. tostring(cls) .. " at " .. getTblAddr(self) .. ">"
		end
	end
	return setmetatable(cls, cls)
end


local ClassA = __sls_createClass("ClassA")
ClassA.t = "A"
ClassA.a = "Im from ClassA"

local ClassB = __sls_createClass("ClassB")
table.insert(ClassB.__sls_inherits, ClassA)
ClassB.t = "B"
ClassB.b = "Im from ClassB"
function ClassB:__sls__tostring()
	return "<ClassB OVERRIDE>"
end

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

print("ClassB.b", ClassB.b)
print("ClassB.a", ClassB.a)
print("ClassA.b", ClassA.b)
