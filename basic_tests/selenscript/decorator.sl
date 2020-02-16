function default(f, ...)
	local defs = {...}
	-- return a new function that calls the supplied function `f` with the default parameters `defs`
	-- and any other parameters that might be supplied when the new function is called
	return function(...) return f(unpack(defs), ...) end
end

@default(3)
@default(9)
function foo(a)
	return a
end
-- LUA (Formatted)
function foo(a)
	return a
end
foo = default(default(foo, 3), 9)

-- the reason we deinfe the function first then redefine with the dectorator it instead of just using
-- it directly as an argument to the decorator is because for example
-- `function t:foo() end`, we want to preserve the special nature of `:`

print(foo()) -- Result: 3
