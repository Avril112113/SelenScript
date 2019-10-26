print ""

local out = io.open("out.txt", "w")
local _print = print
function print(...)
	local args = {...}
	local str = ""
	for i=1,#args do
		local v = args[i]
		if v == nil then
			str = str .. "nil"
		else
			str = str .. tostring(v)
		end
		if #args ~= i then
			str = str .. "\t"
		end
	end
	_print(str)
	str = str .. "\n"
	out:write(str)
end
