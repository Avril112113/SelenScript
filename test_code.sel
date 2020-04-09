-- Special typing, where `T` is passed in
interface Addable<T>
	-- gets `a` and `b` which are the same type as `T`
	-- returns same type as `T`
	__add: function(a: T, b: T)->T
end
-- Selenscript, typing with fancy thing
-- type `T` is not to this scope, but only in the scope of the function
-- `where T` basically says that T should have the following
-- `metaimplements Addable<T>` means that T's metatable should implement the interface `Addable`
-- `<T>` tells the `Addable` interface that `T` in the interface it's self is the same as our `T`
local function add(a: T, b: T) where T metaimplements Addable<T> -> "getmetatable(T).__add(a, b)"
	-- No diagnostic as T's metatable implements __add
	return a + b
end

local f: function<{a=T, b=T}, <T>>
local f: function(a: T, b: T)->T
