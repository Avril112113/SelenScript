local TestResult = require "avtest.testresult"
local StdHook = require "avtest.std_hook"


---@class Test
---@field name string
---@field group Group
---@field f fun():any?
---@field path string?
local Test = {}
Test.__index = Test


---@param name string
---@param f fun():any?
---@param path string?
function Test.new(name, group, f, path)
	return setmetatable({
		name=name,
		group=group,
		f=f,
		path=path,
	}, Test)
end

---@return TestResult
function Test:runTest()
	local result = TestResult.new(self)
	---@type HookedStdout
	result.out = StdHook.new()
	self.group._runningTestResult = result
	result.out:hook()
	local ok, err = xpcall(self.f, debug.traceback)
	result.out:unhook()
	self.group._runningTestResult = nil
	if not ok then
		---@cast err -boolean
		---@cast err +string
		if err:find("__ASSERT__") then
			result.err = "Assertion failed."
		else
			result.err = err
		end
	elseif err then
		result.err = tostring(err)
	end
	return result
end


return Test
