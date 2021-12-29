overload function add(a: number, b: number)
	return a + b
end
overload function add(a: string, b: string)
	return a .. b
end

--- Lua Output (based on `overloading_tests.lua`)

function add(a, b)
    return a + b
end
add = selenscript.lib.overload(add, {args={"number", "number"}})
function add(a, b)
    return a .. b
end
add = selenscript.lib.overload(add, {args={"string", "string"}})