local Test = require "avtest.test"


local function reprValue(value)
	if type(value) == "string" then
		value = value:gsub("\t", "\\t"):gsub("\n", "\\n"):gsub("\r", "\\r")
		if value:find("\"") then
			return ("'%s'"):format(value)
		end
		return ("\"%s\""):format(value)
	elseif type(value) == "table" and value.toString then
		return value:toString()
	elseif type(value) == "table" and value.tostring then
		return value:tostring()
	end
	return tostring(value)
end

local function reprKey(key)
	if type(key) == "string" and not key:find("[\n\r\t.]") then
		return "." .. key
	end
	return ("[%s]"):format(reprValue(key))
end

local function round(exact, quantum)
	local quant, frac = math.modf(exact/quantum)
	return quantum * (quant + (frac > 0.5 and 1 or 0))
end


local TestEnv = {}


---@param TEST {group:Group,path:string?}
function TestEnv.create(TEST)
	---@class TestEnv
	---@field group Group # Set in group.lua
	---@field path string? # Set in group.lua
	TEST = TEST

	---@param name string
	---@param f fun()
	function TEST.addTest(name, f)
		local test = Test.new(name, TEST.group, f, TEST.path)
		return TEST.group:addTest(test)
	end


	--- If value is nil or false, fail. (no error thrown)
	---@param name string
	---@param value any?
	---@param msg any?
	function TEST.check(name, value, msg)
		if TEST.group._runningTestResult then
			TEST.group._runningTestResult:addCheck({
				name=name and tostring(name) or "check",
				line=debug.getinfo(2).currentline,
				fail=not value,
				value=value,
				msg=msg and tostring(msg) or tostring(value),
			})
		else
			error("Missing _runningTestResult?")
		end
	end

	--- If value is nil or false, fail. (errors)
	---@param name string
	---@param value any?
	---@param msg any?
	function TEST.assert(name, value, msg)
		if TEST.group._runningTestResult then
			TEST.group._runningTestResult:addCheck({
				name=name and tostring(name) or "assert",
				line=debug.getinfo(2).currentline,
				fail=not value,
				value=value,
				msg=msg and tostring(msg) or tostring(value),
			})
		else
			error("Missing _runningTestResult?")
		end
		if not value then
			error("__ASSERT__", 2)
		end
	end

	---@param value any
	---@param expected any
	---@param epsilon number?
	function TEST.eq(value, expected, epsilon)
		if epsilon then
			value = round(value, epsilon)
			expected = round(expected, epsilon)
		end
		if value ~= expected then
			return false, ("%s ~= %s"):format(reprValue(value), reprValue(expected))
		end
		return true, reprValue(value)
	end

	---@param value table
	---@param expected table
	---@param ignoreExtras boolean?
	---@param epsilon number?
	function TEST.eqShallow(value, expected, ignoreExtras, epsilon)
		ignoreExtras = ignoreExtras == true
		for i, v in pairs(expected) do
			local tv, ev = value[i], v
			if epsilon and type(tv) == "number" then tv = round(tv, epsilon) end
			if epsilon and type(ev) == "number" then ev = round(ev, epsilon) end
			if tv ~= ev then
				return false, ("`value%s` not as expected: %s ~= %s"):format(reprKey(i), reprValue(tv), reprValue(ev))
			end
		end
		if not ignoreExtras then
			for i, v in pairs(value) do
				local tv, ev = v, expected[i]
				if epsilon and type(tv) == "number" then tv = round(tv, epsilon) end
				if epsilon and type(ev) == "number" then ev = round(ev, epsilon) end
				if tv ~= ev then
					return false, ("`value%s` not as expected: %s ~= %s"):format(reprKey(i), reprValue(tv), reprValue(ev))
				end
			end
		end
		return true
	end

	---@param value table
	---@param expected table
	---@param ignoreExtras boolean?
	---@param epsilon number?
	---@param preindex string?
	function TEST.eqDeep(value, expected, ignoreExtras, epsilon, preindex)
		preindex = preindex or ""
		ignoreExtras = ignoreExtras == nil and false or ignoreExtras
		for i, v in pairs(expected) do
			local tv, ev = value[i], v
			if epsilon and type(tv) == "number" then tv = round(tv, epsilon) end
			if epsilon and type(ev) == "number" then ev = round(ev, epsilon) end
			if type(tv) == "table" and type(ev) == "table" then
				local ok, err = TEST.eqDeep(tv, ev, ignoreExtras, epsilon, reprKey(i))
				if not ok then
					return ok, err
				end
			elseif tv ~= ev then
				return false, ("`value%s%s` not as expected: %s ~= %s"):format(preindex, reprKey(i), reprValue(tv), reprValue(ev))
			end
		end
		if not ignoreExtras then
			for i, v in pairs(value) do
				local tv, ev = v, expected[i]
				if epsilon and type(tv) == "number" then tv = round(tv, epsilon) end
				if epsilon and type(ev) == "number" then ev = round(ev, epsilon) end
				if type(tv) == "table" and type(ev) == "table" then
					local ok, err = TEST.eqDeep(v, expected[i], ignoreExtras, epsilon, reprKey(i))
					if not ok then
						return ok, err
					end
				elseif tv ~= ev then
					return false, ("`value%s%s` not as expected: %s ~= %s"):format(preindex, reprKey(i), reprValue(tv), reprValue(ev))
				end
			end
		end
		return true
	end

	return TEST
end


return TestEnv
