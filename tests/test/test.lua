require("tests/test/__sls_provided_deps")local FooClass=__sls_createClass('FooClass')FooClass.clsVar=300
function FooClass:__new(self)self.objVar=222
end
function FooClass:__tostring(self)return tostring(self)
end
foo=FooClass()
print(foo.clsVar==FooClass.clsVar)print(foo.objVar==222,FooClass.objVar==(nil))foo.clsVar=-300
print(foo.clsVar==FooClass.clsVar)local BarClass=__sls_createClass('BarClass')table.insert(BarClass.__sls_inherits,FooClass)BarClass.bar="hi"
function BarClass:f()end
BarClass.f=decorator(BarClass.f)function BarClass:f2()end
