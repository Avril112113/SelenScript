function super(obj)
	return obj.__sls_inherits[#obj.__sls_inherits]
end

class FooCls
	function __tostring()
		return "<Customized: " .. tostring(super(self).__tostring(self)) .. ">"	
	end

	function __call()
		print("Fancy call, im super cool.")
		return super(self).__call(self)
	end
end

print(" -- print(FooCls) -- ")
print(FooCls)
print(" -- print(FooCls()) -- ")
print(FooCls())
