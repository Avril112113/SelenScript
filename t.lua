if __sls_getTblAddr==(nil) or __sls_addressCache==(nil) then
__sls_addressCache=setmetatable({},{__mode="k"})
function __sls_getTblAddr(tbl)local mt=getmetatable(tbl)
if __sls_addressCache[tbl]~=(nil) then
return __sls_addressCache[tbl]
end
local __tostring=mt.__tostring
mt.__tostring=(nil)
local address=tostring(tbl):gsub("^%w+: ","")
mt.__tostring=__tostring
__sls_addressCache[tbl]=address
return address
end
end
if __sls_createClass==(nil) then
function __sls_createClass(clsName)local cls={__sls_clsName=clsName,__sls_inherits={}}
function cls:__index(index)local value
local __index=rawget(cls,"__sls__index")
if __index~=(nil) then
value=__index(self,index)
end
value=rawget(cls,index)
if value==(nil) then
for _,v in ipairs(rawget(cls,"__sls_inherits")) do
value=v[index]
if value~=(nil) then
return value
end
end
end
return value
end
function cls:__call(...)local __call=rawget(cls,"__sls__call")
if __call~=(nil) then
return __call(self,...)
end
if self~=cls then
error("attempt to call a object value ("..(tostring(self)..")"),1)end
local obj=setmetatable({},cls)
return obj
end
function cls:__tostring()local __tostring=rawget(cls,"__sls__tostring")
if __tostring~=(nil) then
return __tostring(self)
end
if cls==self then
return "<Class "..(self.__sls_clsName..(" at "..(__sls_getTblAddr(self)..">")))
else return "<Object of "..(tostring(cls)..(" at "..(__sls_getTblAddr(self)..">")))
end
end
return setmetatable(cls,cls)
end
end
local FooClass=__sls_createClass('FooClass')FooClass.foo="im foo..."
FooClass.both="im defined in FooClass"
local BarClass=__sls_createClass('BarClass')BarClass.bar="im bar..."
BarClass.both="im defined in BarClass"
local TestClass=__sls_createClass('TestClass')table.insert(TestClass.__sls_inherits,FooClass)table.insert(TestClass.__sls_inherits,BarClass)function TestClass.test(self)print(tostring(self)..":test()")end
print("inherit count",#TestClass.__sls_inherits)TestClass:test()local obj=TestClass()
obj:test()print(tostring(TestClass.foo))print(tostring(obj.foo))print(tostring(obj.both))