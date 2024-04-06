local DEBUG_INFO_FLAGS = {
	["Lua 5.1"]="nSlufL",
	["Lua 5.2"]="nSltufL",
	["Lua 5.3"]="nSltufL",
	["Lua 5.4"]="flnrStuL",
}


---@class HookedStdout
---@field strs string[]
---@field debug debuginfo[]
---@field special (integer|any)[]  # Can be used externally, to interweave extra data, remaining sorted. integers are index into strs & debug.
---@field _originals table?
---@field _hooks table
local StdHook = {}
StdHook.__index = StdHook


function StdHook.new()
	local self = setmetatable({}, StdHook)

	self.strs = {}
	self.debug = {}
	self.special = {}

	self:_createHooks()

	return self
end

---@param data any  # Anything, besides a number.
function StdHook:addSpecialData(data)
	assert(type(data) ~= "number", "special data should not be a number.")
	table.insert(self.special, data)
end

function StdHook:hook()
	assert(self._originals == nil, "Attempt to hook when already hooked.")
	local _originals = {}
	self._originals = _originals

	_originals.stdout = io.stdout
	_originals.output = io.output
	_originals.write = io.write
	_originals.print = print

	local _hooks = self._hooks

	io.stdout = _hooks.stdout
	io.output = _hooks.output
	io.write = _hooks.write
	_G.print = _hooks.print
end

function StdHook:unhook()
	local _originals = assert(self._originals, "Attempt to unhook without previously hooking.")

	io.stdout = _originals.stdout
	io.output = _originals.output
	io.write = _originals.write
	_G.print = _originals.print

	self._originals = nil
end

function StdHook:_createHooks()
	local _hooks = {}
	self._hooks = _hooks

	_hooks.stdout = self:_create_mock_file()
	---@param file string|file*?
	_hooks.output = function(file)
		if file == nil then
			io.stdout = _hooks.stdout
		else
			io.stdout = self._originals.output(file)
		end
		return io.stdout
	end
	_hooks.write = function(...)
		return _hooks.stdout:__write(2, ...)
	end
	_hooks.print = function(...)
		local values = {...}
		for i=1,select("#", ...) do
			values[i] = tostring(values[i])
		end
		_hooks.stdout:__write(3, table.concat(values, "\t"), "\n")
	end
end

--- There is version dependent behaviour, Lua 5.4 results are used here.
---@return MockFile
function StdHook:_create_mock_file()
	local stdHook = self

	---@class MockFile : file*
	local file = {}

	---@param ... readmode
	---@return any
	---@return any ...
	---@nodiscard
	function file:read(...)
		return nil, "No error", 0
	end

	---@param ... string|number
	---@return file*?
	---@return string? errmsg
	function file:write(...)
		return self:__write(2, ...)
	end

	---@param n integer
	---@param ... string|number
	---@return file*?
	---@return string? errmsg
	function file:__write(n, ...)
		local values = {...}
		for i, v in ipairs(values) do
			if type(v) ~= "string" and type(v) ~= "number" then
				error(("bad argument #%s to 'write' (string expected, got %s)"):format(i, type(v)), 2)
			end
		end
		table.insert(stdHook.strs, table.concat(values, ""))
		-- Get flags for lua version, or default to Lua 5.1 if not found
		local debug_flags = DEBUG_INFO_FLAGS[_VERSION] or DEBUG_INFO_FLAGS["Lua 5.1"]
		table.insert(stdHook.debug, debug.getinfo(2, debug_flags))
		table.insert(stdHook.special, #stdHook.strs)
		return self, nil
	end

	function file:flush()
		-- Nothing to do.
	end

	function file:close()
		return nil, "cannot close mock file"
	end

	---@param ... readmode
	---@return fun():any, ...
	function file:lines(...)
		return function()
			error("No error")
		end
	end

	---@param whence? seekwhence
	---@param offset? integer
	---@return integer offset
	---@return string? errmsg
	function file:seek(whence, offset)
		error("Not implemented")
	end

	---@param mode vbuf
	---@param size? integer
	function file:setvbuf(mode, size)
		error("Not implemented")
	end

	return file
end


return StdHook
