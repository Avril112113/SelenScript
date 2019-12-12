local n = for i=0,10 do
	break i if i > 5
end
print(n)

----------

local pos = for i, v in pairs({"a", "b", "c", "d"}) do
	if v == "c" then
		break i
	end
end
print(pos)

----------

local i = 0
local ret_i, someStr = while true do
	i = i + 1
	if i >= 3 then
		break i, "yep, this is stringy"
	end
end
print(i, ret_i, someStr)

----------

for i=1,1 do
	print("Before expr stmt.")
	local t = do
		break  -- this should break the `for` loop
		return "Break above this return should break the for loop..."
	end
	print("After expr stmt.")
end
