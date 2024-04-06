local Config = require "avtest.config"


---@class GroupResults
---@field group Group
---@field out HookedStdout
---@field err string?
---@field tests TestResult[]
---@field groups GroupResults[]
---@field fails integer
local GroupResults = {}
GroupResults.__index = GroupResults


---@param group Group
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

---@param testResult TestResult
function GroupResults:addTestResult(testResult)
	table.insert(self.tests, testResult)
	if testResult:hasFailed() then
		self.fails = self.fails + 1
	end
end

---@param groupResults GroupResults
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
