---@class FunctionSignature
local FunctionSignature = {
	---@type string[] # type
	args=nil
}


-- This would need to be much more complex for actual use in SelenScript
local function isOfType(value, typename)
	return typename == "any" or type(value) == typename
end
local function signatureMatch(signature, args)
	for i, argSig in ipairs(signature) do
		local arg = args[i]
		if not isOfType(arg, argSig) then
			return false
		end
	end
	return true
end
local function strTblValueTypes(tbl)
	local s = ""
	for i, v in ipairs(tbl) do
		if i > 1 then
			s = s .. ", "
		end
		s = s .. type(v)
	end
	return s
end
local function strTblValues(tbl)
	local s = ""
	for i, v in ipairs(tbl) do
		if i > 1 then
			s = s .. ", "
		end
		s = s .. v
	end
	return s
end


local overloadedFunctionMT = {}
function overloadedFunctionMT:__call(...)
	local args = {...}
	local matches = {}
	for _, overload in ipairs(self) do
		if signatureMatch(overload.signature.args, args) then
			table.insert(matches, overload)
		end
	end
	if #matches == 1 then
		return matches[1].f(...)
	elseif #matches > 1 then
		local conflictedArgsStr = ""
		for _, overload in ipairs(matches) do
			conflictedArgsStr = conflictedArgsStr .. "\n > (" .. strTblValues(overload.signature.args) .. ")"
		end
		error("Conflicting overloads for (" .. strTblValueTypes(args) .. ")" .. conflictedArgsStr)
	elseif #matches < 1 and self.default then
		return self.default(...)
	elseif #matches < 1 then
		error("Failed to find overload for (" .. strTblValueTypes(args) .. ") and has no default overload.")
	end
end
---@param orig function|table # table = already overloaded function
---@param f function
---@param signature FunctionSignature
local function overload(orig, f, signature)
	if type(orig) == "table" then
		table.insert(orig, {f=f, signature=signature})
		return orig
	end
	return setmetatable({{f=f, signature=signature}}, overloadedFunctionMT)
end


-- not required, if you assign eg `add = overload(...)`
-- but doing this will make that assignment not needed
local add = setmetatable({}, overloadedFunctionMT)
overload(add, function(a, b)
	print("NOTE: used (string, string)")
	return a .. b
end, {
	args={"string", "string"}
})
overload(add, function(a, b)
	print("NOTE: used (string, any)")
	return a .. tostring(b)
end, {
	args={"string", "any"}
})

print(add("potato ", "string"))
print(add("Error: ", 404))
