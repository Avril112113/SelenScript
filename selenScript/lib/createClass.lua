local getTblAddr = require "selenScript.lib.getTblAddr"


local metamethods = {
	-- Special
	"__index",
	"__newindex",
	"__mode",
	"__call",
	-- "__metatable",
	"__tostring",
	"__len",
	"__pairs",
	"__ipairs",
	-- "__gc",
	-- Mathmatical
	"__unm",
	"__add",
	"__sub",
	"__mul",
	"__div",
	"__idiv",
	"__mod",
	"__pow",
	"__concat",
	-- Bitwise (Lua 5.3+)
	"__band",
	"__bor",
	"__bxor",
	"__bnot",
	"__shl",
	"__shr",
	-- Comparison
	"__eq",
	"__lt",
	"__le",
}


local BaseClass = {
	__class_name="BaseClass",
	__inherits={}
}
BaseClass.__class = BaseClass
function BaseClass:__index(index)
	-- TODO: fix infiniate recursion
	local value
	local cls = rawget(self, "__class")
	value = rawget(cls, index)
	if value == nil then
		for _, v in ipairs(rawget(cls, "__inherits")) do
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
		obj:__init(...)
		return obj
	else
		error("attempt to call an object value " .. tostring(self) .. "", 2)
	end
end
function BaseClass:__tostring()
	if self:is_class() then
		return "<Class " .. self.__class_name .. " at " .. getTblAddr(self) .. ">"
	else
		return "<Object of " .. tostring(self.__class) .. " at " .. getTblAddr(self) .. ">"
	end
end
function BaseClass:__init(...)
	if #({...}) > 0 then error("__init() does not take any arguments.", 2) end
end
function BaseClass:is_class()
	return rawget(self, "__class_name") ~= nil
end

for _, name in ipairs(metamethods) do
	if rawget(BaseClass, name) == nil then
		rawset(BaseClass, name, function(self, ...)
			return self[name](self, ...)
		end)
	end
end

local function createClass(clsName)
	local cls = {
		__class_name=clsName,
		__inherits={
			BaseClass
		}
	}
	cls.__class = cls
	for _, name in ipairs(metamethods) do
		rawset(cls, name, rawget(BaseClass, name))
	end
	return setmetatable(cls, cls)
end


return createClass
