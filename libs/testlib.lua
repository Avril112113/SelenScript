-- Author: Dude112113
-- Version: 1.0


local plpath = require "pl.path"
local pldir = require "pl.dir"
local logging = require "logging"
local colors = require "terminal_colors"


---@alias TestLib.TestLog {[integer]:any, level:1|2}

---@class TestLib.TestResult
---@field name string
---@field f fun()
---@field log TestLib.TestLog[]
---@field status string
---@field msg string?
local TestResult

---@class TestLib.TestResults
---@field path string
---@field status string
---@field statusMsg string?
---@field tests TestLib.TestResult[]
---@field log TestLib.TestLog[]
local TestsResult


---@class TestLib
local TestLib = {
	STATUS = {
		-- TestResult
		FAIL = colors.bright_red .. "FAIL" .. colors.reset,
		PASS = colors.bright_green .. "PASS" .. colors.reset,
		-- TestResults
		UNKNOWN = colors.bright_yellow .. "UNKNOWN" .. colors.reset,
		FAIL_LOAD = colors.bright_red .. "FAIL_LOAD" .. colors.reset,
		FAIL_EXEC = colors.bright_red .. "FAIL_EXEC" .. colors.reset,
		LOADED = colors.bright_green .. "LOADED" .. colors.reset,
	},
}


---@param basepath string
---@param testPathResults (table<string,TestLib.TestResults>|TestLib.TestResults[])?
---@return table<string,TestLib.TestResults>|TestLib.TestResults[]
function TestLib.run_tests(basepath, testPathResults)
	testPathResults = testPathResults or {}
	for path, isDir in pldir.dirtree(basepath) do
		if not isDir then
			local filename = plpath.basename(path)
			if filename:gsub("%d%_+", ""):sub(1, 5) == "test_" and filename:sub(-4, -1) == ".lua" then
				---@type TestLib.TestResults
				local testResults = {
					path = path,
					tests = {},
					log = {},
					status = TestLib.STATUS.UNKNOWN,
					statusMsg = nil,
				}
				testPathResults[path] = testResults
				table.insert(testPathResults, testResults)
				TestLib._testResult = testResults
				---@type TestLib.TestResult
				local currentTest
				local f, loadErr = loadfile(path, "t")
				if f == nil then
					testResults.status = TestLib.STATUS.FAIL_LOAD
					testResults.statusMsg = loadErr or "NO_MSG"
					table.insert(testResults.log, {level=logging.LEVELS.ERROR, testResults.status, testResults.statusMsg})
				else
					local original_log = logging._log
					logging._log = function(log_type, ...)
						table.insert(currentTest ~= nil and currentTest.log or testResults.log, {level=log_type, ...})
					end
					xpcall(f, function(msg)
						testResults.status = TestLib.STATUS.FAIL_EXEC
						testResults.statusMsg = debug.traceback(msg, 1)
						table.insert(testResults.log, {level=logging.LEVELS.ERROR, testResults.status, testResults.statusMsg})
					end)
					testResults.status = TestLib.STATUS.LOADED
					for _, test in ipairs(testResults.tests) do
						currentTest = test
						test.status = TestLib.STATUS.PASS
						xpcall(test.f, function(msg)
							test.status = TestLib.STATUS.FAIL
							test.msg = msg
							test.trace = debug.traceback(msg, 1)
							table.insert(test.log, {level=logging.LEVELS.ERROR, test.trace})
						end)
					end
					logging._log = original_log
				end
				TestLib._testResult = nil
			end
		end
	end
	return testPathResults
end

---@param testPathResults table<string,TestLib.TestResults>|TestLib.TestResults[]
---@param print_logs boolean?  # Print logs on failed tests
function TestLib.print_results(testPathResults, print_logs)
	for _, testResults in ipairs(testPathResults) do
		local passCount = 0
		for _, test in ipairs(testResults.tests) do
			if test.status == TestLib.STATUS.PASS then
				passCount = passCount + 1
			end
		end
		print_info(("~ File: %s (%s) (%s%s/%s%s passed)"):format(
			testResults.path,
			testResults.status .. (testResults.statusMsg and " : "..testResults.statusMsg or ""),
			passCount == #testResults.tests and colors.bright_green or colors.bright_red, passCount, #testResults.tests, colors.reset
		))
		for _, log in ipairs(testResults.log) do
			logging._log(log.level, "  " .. TestLib._stringify_log(log, "  "))
		end
		for _, test in ipairs(testResults.tests) do
			local failed = test.status ~= TestLib.STATUS.PASS
			local coloredStatus = failed and (colors.bright_red .. test.status .. colors.reset) or (colors.bright_green .. test.status .. colors.reset)
			print_info(("  ~ Test: %s\t(%s)"):format(test.name, coloredStatus))
			if failed and print_logs == true then
				for _, log in ipairs(test.log) do
					logging._log(log.level, "    " .. TestLib._stringify_log(log, "    "))
				end
			end
		end
	end
end

---@param testPathResults table<string,TestLib.TestResults>|TestLib.TestResults[]
function TestLib.write_results(testPathResults)
	for _, testResults in ipairs(testPathResults) do
		local logFile = assert(io.open(testResults.path .. ".log", "w"))
		local passCount = 0
		for _, test in ipairs(testResults.tests) do
			if test.status == TestLib.STATUS.PASS then
				passCount = passCount + 1
			end
		end
		logFile:write(("%s (%s)\n%s/%s tests passed.\n\n"):format(testResults.path, colors.strip(testResults.status), passCount, #testResults.tests))
		for _, log in ipairs(testResults.log) do
			logFile:write(colors.strip("[" .. log.level .. "]\t" .. TestLib._stringify_log(log, "        ") .. "\n"))
		end
		for _, test in ipairs(testResults.tests) do
			logFile:write(("~~~~~~~ Test: %s\t(%s)\n"):format(test.name, colors.strip(test.status)))
			for _, log in ipairs(test.log) do
				logFile:write(colors.strip("[" .. log.level .. "]\t" .. TestLib._stringify_log(log, "        ") .. "\n"))
			end
			logFile:write("\n")
		end
		logFile:close()
	end
end

---@param log TestLib.TestLog
---@param indent string?
function TestLib._stringify_log(log, indent)
	local parts = {}
	for _, part in ipairs(log) do
		-- TODO: Better stringify, eg, tables.
		local s = tostring(part)
		if indent ~= nil then
			s = s:gsub("\n", "\n" .. indent)
		end
		table.insert(parts, s)
	end
	return table.concat(parts, "\t")
end

function TestLib.test(name, f)
	assert(TestLib._testResult.tests[name] == nil, ("Test with name '%s' already exists."):format(name))
	local test = {
		name = name,
		f = f,
		log = {},
	}
	TestLib._testResult.tests[name] = test
	table.insert(TestLib._testResult.tests, test)
end

---@generic T
---@param condition T
---@param msg any?
---@param ... any
---@return T, any ...
function TestLib.assert(condition, msg, ...)
	return assert(condition, msg, ...)
end

---@param tbl table  # The table to check
---@param partial table  # The table containing fields that are required to match
---@param _recur boolean?  # Used internally
function TestLib.assert_table_match(tbl, partial, _recur)
	local failedFields = {}
	local hasFailedField = false
	for k, v in pairs(partial) do
		if type(v) == "table" and type(tbl[k]) == "table" then
			local childFailedFields = TestLib.assert_table_match(tbl[k], v, true)
			if childFailedFields ~= nil then
				failedFields[k] = childFailedFields
				hasFailedField = true
			end
		elseif tbl[k] ~= v then
			failedFields[k] = true
			hasFailedField = true
		end
	end
	if not _recur and hasFailedField then
		local lines = {"Table didn't match:"}
		local function processFailedField(fields, original, expected, path)
			for k, v in pairs(fields) do
				if type(v) == "table" then
					processFailedField(v, original[k], expected[k], path .. "." .. k)
				else
					local expectedQuote = type(expected[k]) == "string" and (expected[k]:find("\"") and "'" or "\"") or "`"
					local originalQuote = type(original[k]) == "string" and (original[k]:find("\"") and "'" or "\"") or "`"
					table.insert(lines, ("%s.%s expected %s%s%s but got %s%s%s"):format(
						path, k,
						expectedQuote, expected[k],expectedQuote,
						originalQuote, original[k], originalQuote
					))
				end
			end
		end
		processFailedField(failedFields, tbl, partial, "TABLE")
		error(table.concat(lines, "\n"), 1)
	elseif hasFailedField then
		return failedFields
	end
end


package.loaded["testlib"] = TestLib
return TestLib
