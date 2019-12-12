local getTblAddr = require "selenScript.lib.getTblAddr"


local function malformationCheck(cls)
	assert(rawget(cls, "__address") ~= nil, "Class malformation check failed (missing __address)")
	assert(rawget(cls, "__name") ~= nil, "Class malformation check failed (missing __name)")
	assert(rawget(cls, "__class") ~= nil, "Class malformation check failed (missing __class)")
	assert(rawget(cls, "__inherits") ~= nil, "Class malformation check failed (missing __inherits)")
end

local function generateBinaryOpMtFunc(metamethod)
	local notImplemented = metamethod .. " is not implemented in the class {name} or its sub-classes"
	return function(tbl, other)
		local mm = tbl[metamethod]
		if mm ~= nil then
			return mm(tbl, other)
		else
			error(notImplemented:gsub("{name}", rawget(tbl, "__name") or rawget(rawget(tbl, "__class"), "__name")))
		end
	end
end

local _classMt = {}
_classMt.__index=function(tbl, key)
	local __index = rawget(tbl, "__index")
	if __index == nil then
		local value = rawget(tbl, key)
		if value ~= nil then
			return value
		end
		local __inherits = rawget(tbl, "__inherits") or rawget(rawget(tbl, "__class"), "__inherits")
		for _, cls in ipairs(__inherits) do
			value = cls[key]
			if value ~= nil then
				return value
			end
		end
	elseif type(__index) == "table" then
		return tbl[key]
	elseif type(__index) == "function" then
		return __index(tbl, key)
	else
		error("Unsupported __index type " .. type(__index) .. " for class " .. (rawget(tbl, "__name") or rawget(rawget(tbl, "__class"), "__name")))
	end
end
_classMt.__tostring=function(tbl)
	local mm = tbl.__tostring
	if mm ~= nil then
		local result = mm(tbl)
		if type(result) ~= "string" then
			error("__tostring in class " .. (rawget(tbl, "__name") or rawget(rawget(tbl, "__class"), "__name")) .. " must return a string, not '" .. type(result) .. "'")
		end
		return result
	elseif rawget(tbl, "__name") ~= nil then
		return "<Class " .. (rawget(tbl, "__name") or rawget(rawget(tbl, "__class"), "__name")) .. " at " .. rawget(tbl, "__address") .. ">"
	else
		return "<Object of class " .. tostring(tbl.__class) .. " at " .. rawget(tbl, "__address") .. ">"
	end
end
_classMt.__add=generateBinaryOpMtFunc("__add")
_classMt.__sub=generateBinaryOpMtFunc("__sub")
_classMt.__mul=generateBinaryOpMtFunc("__mul")
_classMt.__div=generateBinaryOpMtFunc("__div")
_classMt.__mod=generateBinaryOpMtFunc("__mod")
_classMt.__pow=generateBinaryOpMtFunc("__pow")
_classMt.__unm=generateBinaryOpMtFunc("__unm")
_classMt.__idiv=generateBinaryOpMtFunc("__idiv")
_classMt.__concat=generateBinaryOpMtFunc("__concat")

_classMt.__band=generateBinaryOpMtFunc("__band")
_classMt.__bor=generateBinaryOpMtFunc("__bor")
_classMt.__bxor=generateBinaryOpMtFunc("__bxor")
_classMt.__bnot=generateBinaryOpMtFunc("__bnot")
_classMt.__shl=generateBinaryOpMtFunc("__shl")
_classMt.__shr=generateBinaryOpMtFunc("__shr")

_classMt.__eq=function(tbl)
	local mm = tbl.eq
	if mm ~= nil then
		return mm(tbl)
	else
		return rawequal(tbl)
	end
end
_classMt.__lt=generateBinaryOpMtFunc("__lt")

_classMt.__le=function(tbl, other)
	local __le = tbl.__le
	if __le ~= nil then
		return __le(tbl, other)
	-- Lua 5.4 requires this and wont just use `__lt`
	elseif tbl.__lt ~= nil then
		return not (tbl > other)
	else
		error("__le or __lt is not implemented in the class " .. (rawget(tbl, "__name") or rawget(rawget(tbl, "__class"), "__name")) .. " or its sub-classes")
	end
end
_classMt.__len=function(tbl)
	local mm = tbl.len
	if mm ~= nil then
		return mm(tbl)
	else
		return rawlen(tbl)
	end
end
_classMt.__newindex=function(tbl, index, value)
	local mm = tbl.__newindex
	if mm ~= nil then
		return mm(tbl, index, value)
	else
		rawset(tbl, index, value)
	end
end
-- _classMt.__gc=function(tbl)
-- 	if tbl.__gc ~= nil then
-- 		return tbl.__gc(tbl)
-- 	end
-- end,
_classMt.__close=function(tbl, err)
	local mm = tbl.close
	if mm ~= nil then
		return mm(tbl, err)
	else
		error("__close is not implemented in the class " .. (rawget(tbl, "__name") or rawget(rawget(tbl, "__class"), "__name")) .. " or its sub-classes")
	end
end
_classMt.__call=function(tbl, ...)
	local mm = tbl.call
	if mm ~= nil then
		return mm(tbl, ...)
	else
		error("__call is not implemented in the class " .. (rawget(tbl, "__name") or rawget(rawget(tbl, "__class"), "__name")) .. " or its sub-classes")
	end
end


local function createClass(name)
	local cls = {}
	cls.__address = getTblAddr(cls)
	cls.__name = name
	cls.__class = cls
	cls.__inherits = {}
	function cls:__addInherits(other)
		malformationCheck(other)
		table.insert(rawget(cls, "__inherits"), other)
	end
	function cls:new(...)
		local obj = {}
		obj.__class = self
		obj.__address = getTblAddr(obj)
		obj.__inherits = {self}
		if obj.__new ~= nil then
			obj.__new(obj, ...)
		elseif #({...}) > 0 then
			error("Attempt to create new object of class " .. (cls.name or cls.__class.__name) .. " but does not accept any arguments")
		end
		return setmetatable(obj, _classMt)
	end
	return setmetatable(cls, _classMt)
end


local MajorClass = createClass("MajorClass")
MajorClass.someValue = "I am some value"
function MajorClass:__new()
	-- NOTE: self == obj NOT self == MajorClass
	print("Woop Woop!")
end
-- function MajorClass:__tostring()
-- 	return "<Working " .. self.__address .. ">"
-- end
print(MajorClass, MajorClass.someValue)

local MinorClass = createClass("MinorClass")
MinorClass:__addInherits(MajorClass)
print(MinorClass, MinorClass.someValue)

local majorObject = MajorClass:new()
majorObject.majorVar = 303
print(majorObject, majorObject.majorVar, majorObject.someValue)

local minorObject = MajorClass:new()
minorObject.minorVar = 404
print(minorObject, minorObject.minorVar, minorObject.someValue, minorObject.majorVar)
