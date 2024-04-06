local Config = require "avtest.config"


--- TODO: Typing for TestAssertion
---@alias TestCheck {name:string,line:integer,fail:boolean,msg:string?,value:any?}


---@class TestResult
---@field test Test
---@field out HookedStdout
---@field err string?
---@field checks TestCheck[]
local TestResult = {}
TestResult.__index = TestResult


---@param test Test
function TestResult.new(test)
	return setmetatable({
		test=test,
		checks={},
	}, TestResult)
end

---@param check TestCheck
function TestResult:addCheck(check)
	table.insert(self.checks, check)
	self.out:addSpecialData(check)
end

function TestResult:hasFailed()
	for _, check in ipairs(self.checks) do
		if check.fail then
			return true
		end
	end
	return self.err ~= nil
end


return TestResult
