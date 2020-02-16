-- local T: <metaimplements Addable<T>, implements Addable<T>>
-- local function add(a: T, b: T) -> "getmetatable(T).__add(a, b)"
-- 	return a + b
-- end

local function add(a: TA, b: TB) where TA<metaimplements Addable<T>>, TB<metaimplements Addable<T>> -> "getmetatable(T).__add(a, b)"
	return a + b
end
