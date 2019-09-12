require("tests/test/__sls_provided_deps")local function super(obj)return obj.__sls_inherits[#obj.__sls_inherits]
end
local FooCls=__sls_createClass('FooCls')function FooCls:__tostring()return "<Customized: "..tostring(super(self).__tostring(self))..">"
end
function FooCls:__call()print("Fancy call, im super cool.")return super(self).__call(self)
end
print("str")print(FooCls)print("call")print(FooCls())