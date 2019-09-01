print ""

local out = io.open("out.txt", "w")
local _print = print
function print(...)
	local args = {...}
	local str = ""
	for i, v in ipairs(args) do
		str = str .. tostring(v)
		if #args ~= i then
			str = str .. "\t"
		end
	end
	_print(str)
	str = str .. "\n"
	out:write(str)
end
