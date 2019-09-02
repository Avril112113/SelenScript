class FooClass
	clsVar = 300

	function __new(self)
		self.objVar = 222
	end
	function __tostring(self)
		return tostring(self)
	end
	-- all metamethods work here
end

foo = FooClass()
print(foo.clsVar == FooClass.clsVar) -- Result: true
print(foo.objVar == 222, FooClass.objVar == nil) -- Result: true, true
foo.clsVar = -300
print(foo.clsVar == FooClass.clsVar) -- Result: false

-- Full Syntax Potential
class BarClass extends FooClass implements SomeInterface
	foo: string
	bar = "hi"

	@decorator
	function f()
	end

	function f2()
	end
end
