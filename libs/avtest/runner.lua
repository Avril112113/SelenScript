local TestGroup = require "avtest.group"
local Config = require "avtest.config"


---@param path string
local function standardize_path(path)
	return (path:gsub("\\", "/"):gsub("//+", "/"):gsub("^./", ""):gsub("/$", ""))
end


---@class AvTestRunner
local Runner = {}
Runner.__index = Runner


function Runner.new()
	---@class AvTestRunner # Allow field injection
	local self = setmetatable({}, Runner)

	self._output_file_enabled = false
	self._output_file_shared = true
	self._errored_always_to_console = true
	self._output_file_strip_colors = true

	self._main_group = TestGroup.new(".")

	---@type string[]
	self._whitelist = {}
	---@type string[]
	self._blacklist = {}

	return self
end

--- Sets if logs files should be written with each tests output.
--- This will hide the output of non-errored tests from the console by default.
---@param enabled boolean
function Runner:setOutputFileEnabled(enabled)
	self._output_file_enabled = not not enabled
	return self
end

--- Sets if each test gets it's own log file or if all within the same group share the same file.
---@param enabled boolean
function Runner:setOutputFilePerTest(enabled)
	self._output_file_shared = not enabled
	return self
end

--- Sets if the output of failing tests are displayed in the console regardless of other settings.
--- false means only in the log file.
---@param enabled boolean
function Runner:setErroredAlwaysToConsole(enabled)
	self._errored_always_to_console = not not enabled
	return self
end

--- true will strip colors from the log files.
---@param enabled boolean
function Runner:setOutputFileStripColors(enabled)
	self._output_file_strip_colors = not not enabled
	return self
end

--- Paths should be relative
--- Note that whitelists are only applied to addFile/addDir afterwards.
---@param path string
function Runner:addWhitelist(path)
	if type(path) ~= "string" or #path <= 0 then return self end
	table.insert(self._whitelist, standardize_path(path))
	return self
end

--- Paths should be relative
--- Note that blacklists are only applied to addFile/addDir afterwards.
---@param path string
function Runner:addBlacklist(path)
	if type(path) ~= "string" or #path <= 0 then return self end
	table.insert(self._blacklist, standardize_path(path))
	return self
end

---@param path string
function Runner:_filterTest(path)
	if #self._blacklist > 0 then
		for _, blacklist_path in ipairs(self._blacklist) do
			-- Adding trailing backslash and +1 to ensure the partial match is per path segment
			if (path .. "/"):sub(1, #blacklist_path + 1) == blacklist_path .. "/" then
				return false
			end
		end
	end
	if #self._whitelist > 0 then
		for _, whitelist_path in ipairs(self._whitelist) do
			-- Adding trailing backslash and +1 to ensure the partial match is per path segment
			if (path .. "/"):sub(1, #whitelist_path+1) == (whitelist_path .. "/"):sub(1, #path+1) then
				return true
			end
		end
	end
	return #self._whitelist <= 0
end

--- Paths should be relative
---@param path string
function Runner:addFile(path)
	if type(path) ~= "string" or #path <= 0 then return self end
	path = standardize_path(path)
	if not self:_filterTest(path) then return self end
	self._main_group:loadFile(path)
	return self
end

--- Paths should be relative
---@param path string
function Runner:addDir(path)
	if type(path) ~= "string" or #path <= 0 then return self end
	path = standardize_path(path)
	if not self:_filterTest(path) then return self end
	local groups = {}
	groups = self._main_group:loadFolder(path, true, function (tpath) return self:_filterTest(tpath) end)
	for _, group in ipairs(groups) do
		group.name = ("%s/%s"):format(path, group.name)
	end
	return self, groups
end

---@param main_results GroupResults
function Runner:_processResults(main_results)
	---@type string[]
	local results_out_parts = {}
	---@type table<any,file*>
	local log_files = {}

	---@param results TestResult
	---@param prefix string?
	local function process_test_results(results, prefix)
		prefix = (prefix or "/") .. results.test.name
		---@type string[]
		local test_out_parts = {}
		local checksSuffix = ""
		if #results.checks > 0 then
			local failedChecks = 0
			for _, check in ipairs(results.checks) do
				if check.fail then
					failedChecks = failedChecks + 1
				end
			end
			checksSuffix = (" - %s%s/%s%s"):format(failedChecks > 0 and Config.PREFIX_FAIL or Config.PREFIX_PASS, #results.checks-failedChecks, #results.checks, Config.RESET)
		end
		table.insert(test_out_parts, ("%s[%s%s%s]%s - %s%s%s"):format(Config.PREFIX_TAG, Config.PREFIX_GROUP, prefix, Config.PREFIX_TAG, Config.RESET, results:hasFailed() and (Config.PREFIX_FAIL.."FAIL") or (Config.PREFIX_PASS.."PASS"), Config.RESET, checksSuffix))
		local parts = {}
		local function tostring_parts()
			if #parts <= 0 then return end
			local line_prefix = ("    %s[OUT]: "):format(Config.PREFIX_TAG)
			local line_nl = "\n" .. string.rep(" ", #Config.stripColors(line_prefix))
			table.insert(test_out_parts, ("%s%s%s%s"):format(line_prefix, Config.PREFIX_TEXT, table.concat(parts, ""):gsub("\n+$", ""):gsub("\n", line_nl), Config.RESET))
			parts = {}
		end
		for _, data in ipairs(results.out.special) do
			if type(data) == "number" then
				---@cast data number
				table.insert(parts, results.out.strs[data])
			else
				---@cast data TestCheck
				tostring_parts()
				local check = data
				local line_prefix = ("    %s[CHECK]:%3s:%s%s: "):format(Config.PREFIX_TAG, check.line, (check.fail and Config.PREFIX_FAIL or Config.PREFIX_PASS) .. check.name, Config.PREFIX_TAG)
				local line_nl = "\n" .. string.rep(" ", #Config.stripColors(line_prefix))
				table.insert(test_out_parts, ("%s%s%s%s"):format(line_prefix, Config.PREFIX_TEXT, (check.msg and check.msg:gsub("\n", line_nl) or ""), Config.RESET))
			end
		end
		tostring_parts()
		if results.err ~= nil then
			local line_prefix = ("    %s[%sERROR%s]: "):format(Config.PREFIX_TAG, Config.PREFIX_ERR, Config.PREFIX_TAG)
			local line_nl = "\n" .. string.rep(" ", #Config.stripColors(line_prefix))
			table.insert(test_out_parts, ("%s%s%s%s"):format(line_prefix, Config.PREFIX_TEXT, tostring(results.err):gsub("\n", line_nl), Config.RESET))
		end

		return table.concat(test_out_parts, "\n")
	end

	---@param results GroupResults
	local function process_group_results(results, prefix)
		prefix = (prefix or "") .. results.group.name .. "/"
		---@type string[]
		local group_out_parts = {}
		local total = #results.tests + #results.groups
		table.insert(group_out_parts, ("%s[%s%s%s]%s - %s%s/%s%s"):format(Config.PREFIX_TAG, Config.PREFIX_GROUP, prefix, Config.PREFIX_TAG, Config.RESET, (results.err or results.fails > 0) and Config.PREFIX_FAIL or Config.PREFIX_PASS, total-results.fails, total, Config.RESET))
		if results.out ~= nil and #results.out.strs > 0 then
			local line_prefix = ("    %s[OUT]: "):format(Config.PREFIX_TAG)
			local line_nl = "\n" .. string.rep(" ", #Config.stripColors(line_prefix))
			table.insert(group_out_parts, ("%s%s%s%s"):format(line_prefix, Config.PREFIX_TEXT, table.concat(results.out.strs, ""):gsub("\n+$", ""):gsub("\n", line_nl), Config.RESET))
		end
		if results.err ~= nil then
			local line_prefix = ("    %s[%sERROR%s]: "):format(Config.PREFIX_TAG, Config.PREFIX_ERR, Config.PREFIX_TAG)
			local line_nl = "\n" .. string.rep(" ", #Config.stripColors(line_prefix))
			table.insert(group_out_parts, ("%s%s%s%s"):format(line_prefix, Config.PREFIX_TEXT, results.err:gsub("\n", line_nl), Config.RESET))
		end
		if #results.tests <= 0 and #results.groups <= 0 then
			table.insert(group_out_parts, ("    %sNo tests or groups...%s"):format(Config.PREFIX_TAG, Config.RESET))
		end
		-- local f_group = self._output_to_file and self._output_file_shared and assert(io.open(test.test.path .. ".log", "w")) or nil
		for _, test in ipairs(results.tests) do
			local test_out = process_test_results(test, prefix)
			if self._output_file_enabled then
				if self._output_file_shared then
					local f = log_files[test.test.path] or assert(io.open(test.test.path .. ".log", "w"))
					log_files[test.test.path] = f
					f:write((self._output_file_strip_colors and Config.stripColors(test_out) or test_out) .. "\n\n\n")
				else
					local f = assert(io.open(test.test.path .. "." .. test.test.name:gsub("[?!\\/ ]+", "-") .. ".log", "w"))
					f:write((self._output_file_strip_colors and Config.stripColors(test_out) or test_out) .. "\n")
					f:close()
				end
			end
			if not self._output_file_enabled or (test:hasFailed() and self._errored_always_to_console) then
				table.insert(group_out_parts, test_out)
			end
		end

		local group_out = table.concat(group_out_parts, "\n")
		table.insert(results_out_parts, group_out)

		for _, subgroup in ipairs(results.groups) do
			process_group_results(subgroup, prefix)
		end
	end

	process_group_results(main_results)

	for _, f in pairs(log_files) do
		f:close()
	end

	return table.concat(results_out_parts, "\n")
end

function Runner:runTests()
	---@type table<Test|Group,string>
	local full_name_map = {}
	---@param group Group
	---@param path string
	local function recur(group, path)
		full_name_map[group] = standardize_path(path)
		for _, test in ipairs(group.tests) do
			full_name_map[test] = standardize_path(path .. "/" .. test.name)
		end
		for _, subgroup in ipairs(group.groups) do
			recur(subgroup, path .. "/" .. subgroup.name)
		end
	end
	recur(self._main_group, self._main_group.name)
	local results = self._main_group:runTests(function(obj)
		return full_name_map[obj] ~= nil and self:_filterTest(full_name_map[obj])
	end)
	print(self:_processResults(results))

	local tests_total = 0
	local tests_fails = 0
	local checks_total = 0
	local checks_fails = 0
	---@param groupResults GroupResults
	local function recurCountResults(groupResults)
		for _, testResult in ipairs(groupResults.tests) do
			tests_total = tests_total + 1
			if testResult:hasFailed() then
				tests_fails = tests_fails + 1
			end
			for _, check in ipairs(testResult.checks) do
				checks_total = checks_total + 1
				if check.fail then
					checks_fails = checks_fails + 1
				end
			end
		end
		for _, subGroupResults in ipairs(groupResults.groups) do
			recurCountResults(subGroupResults)
		end
	end
	recurCountResults(results)

	print()
	print(("%sTotal Tests:  %s%s"):format(Config.PREFIX_TAG, tests_total, Config.RESET))
	print(("%sTests Passed: %s%s%s"):format(Config.PREFIX_TAG, Config.PREFIX_PASS, tests_total-tests_fails, Config.RESET))
	print(("%sTests Failed: %s%s%s"):format(Config.PREFIX_TAG, results.fails > 0 and Config.PREFIX_FAIL or Config.PREFIX_PASS, tests_fails, Config.RESET))
	print()
	print(("%sTotal Checks:  %s%s"):format(Config.PREFIX_TAG, checks_total, Config.RESET))
	print(("%sChecks Passed: %s%s%s"):format(Config.PREFIX_TAG, Config.PREFIX_PASS, checks_total-checks_fails, Config.RESET))
	print(("%sChecks Failed: %s%s%s"):format(Config.PREFIX_TAG, results.fails > 0 and Config.PREFIX_FAIL or Config.PREFIX_PASS, checks_fails, Config.RESET))
end


return Runner