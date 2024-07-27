local Config = require "avtest.config"


---@class AvTest.GroupResults
---@field group AvTest.Group
---@field out AvTest.HookedStdout
---@field err string?
---@field tests AvTest.TestResult[]
---@field groups AvTest.GroupResults[]
---@field fails integer
local GroupResults = {}
GroupResults.__index = GroupResults


---@param group AvTest.Group
function GroupResults.new(group)
	return setmetatable({
		group=group,
		out=group.out,
		err=group.err,
		tests={},
		groups={},
		fails=0,
	}, GroupResults)
end

---@param testResult AvTest.TestResult
function GroupResults:addTestResult(testResult)
	table.insert(self.tests, testResult)
	if testResult:hasFailed() then
		self.fails = self.fails + 1
	end
end

---@param groupResults AvTest.GroupResults
function GroupResults:addGroupResults(groupResults)
	table.insert(self.groups, groupResults)
	if groupResults:hasFailed() then
		self.fails = self.fails + 1
	end
end

function GroupResults:hasFailed()
	return self.fails > 0 or self.err
end


return GroupResults
