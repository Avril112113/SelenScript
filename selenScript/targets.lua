local targets = {}

local base={
	-- list of node types from ast
	breakable={
		["while"]=true,
		["for_each"]=true,
		["for_range"]=true,
		["repeat"]=true
	},
	hasGoto=false,
	-- used if the variable name is defined local but the assignment is global
	globalDefinedLocal="getfenv()"
}

targets["5.1"] = {

}
targets["jit"] = {
	inherit=targets["5.1"],
	hasGoto=true
}
targets["5.2"] = {
	inherit=targets["5.1"],
	hasGoto=true,
	globalDefinedLocal="_ENV"
}
targets["5.3"] = {
	inherit=targets["5.2"]
}
targets["5.4"] = {
	inherit=targets["5.3"]
}


for _, tbl in pairs(targets) do
	local mt = {}
	local inherits = rawget(tbl, "inherit")
	function mt:__index(key)
		return rawget(tbl, key) or
			   (inherits ~= nil and inherits[key]) or
			   base[key]
	end
	setmetatable(tbl, mt)
end

return targets
