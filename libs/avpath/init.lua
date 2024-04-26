-- Currently, all methods are implemented in pure Lua which supports Windows and Linux.
-- Any other OS has not been tested.


---@class AVPath
local AVPath = {}


AVPath.SEPERATOR = package and package.config:sub(1, 1) or "/"


---@param s       string|number
---@param pattern string|number
---@param repl    string|number|table|function
---@param n?      integer
---@return string
---@return integer count
---@nodiscard
local function recursive_gsub(s, pattern, repl, n)
	---@cast s string
	local c = 0
	while n == nil or c < n do
		local ns, cs = s:gsub(pattern, repl, 1)
		c = c + cs
		-- ns == s supports repl function return `nil` to stop recursion.
		if cs <= 0 or ns == s then
			break
		end
		s = ns
	end
	return s, c
end


--- Normalizes a path.
--- - Converts slashes to system/configured slashes
--- - Normalizes `.` and `..` if possible
--- - Removes trailing and double slashs
---@param path string
---@return string
function AVPath.norm(path)
	-- TODO: Some Windows paths like to a 'share' need to preserve the leading double slashes.
	path = path:gsub("[\\/]%.([\\/])", "%1")  -- Redundant current dir `.`
	path = recursive_gsub(
				path,
				"([\\/]*)([^\\/]+)[\\/]+%.%.",
				function(slashes, par)
					if par == ".." then return nil end
					return slashes
				end
			)  -- Process parent dir `..`
			:gsub("([^:])[\\/]+$", "%1")  -- Trailing slashes.
			:gsub("[\\/]+", AVPath.SEPERATOR)  -- Convert slashs and remove duplicates.
			:gsub("[\\/]%.$", "")  -- Trailing current dir `.`
	return path
end

--- Concatinates 2 or more paths together.
---@param parts string[]
---@return string
function AVPath.join(parts)
	return AVPath.norm(table.concat(parts, AVPath.SEPERATOR))
end

--- Weather or not a path is absolute.
---@param path string
---@return boolean
function AVPath.getabs(path)
	return path:match("^[\\/]") or path:match("^%w:[\\/]")
end

--- Get the absolute path.
---@param path string
---@param base string?
---@return string
function AVPath.abs(path, base)
	if AVPath.getabs(path) then
		return path
	end
	base = base or assert(AVPath.cwd(), "Unable to get current working directory.")
	return AVPath.norm(AVPath.join{base, path})
end

--- Get the last path segment (AKA filename or dirname)
---@param path string
---@return string
function AVPath.name(path)
	return path:match("[\\/]?([^\\/]+)$")
end

--- Gets all but the last path segments (AKA basedir or parent dir)
---@param path string
---@param pardir boolean?  # Default `true`, if parent dir unavailable in provided path, allows use of `..`, otherwise `.` will be returned.
---@return string
function AVPath.base(path, pardir)
	if #path <= 0 or path:match("^%.[\\/]*$") then
		return pardir == false and "." or ".."
	end
	local base = path:match("^(.*)[\\/][^\\/]+")
	if base == nil then
		base = "."
	elseif base == "" then
		base = AVPath.SEPERATOR
	end
	return base
end

--- Split the path and file extension.
--- If last segments begins with `.` then it will not be returned as the extension.
---@param path string
---@return string name, string ext
function AVPath.splitext(path)
	local base, ext = path:match("(.*)(%.[^\\/.]*)$")
	return base or path, ext or ""
end

--- Get the common path between many paths.
---@param paths string[]
---@return string
function AVPath.common(paths)
	local iters = {}
	local last_abs
	for i, s in ipairs(paths) do
		local isabs = AVPath.getabs(s)
		if last_abs ~= nil and last_abs ~= isabs then
			return ""
		end
		iters[i] = AVPath.norm(s):gmatch("[^\\/]+")
		last_abs = isabs
	end
	local parts = {}
	while true do
		local s = iters[1]()
		local do_break = false
		for i=2,#iters do
			local is = iters[i]()
			if is ~= s then
				do_break = true
				break
			end
		end
		if do_break then break end
		table.insert(parts, s)
	end
	-- Only needs to check first path, as they are checked to all be the same earlier.
	if #parts <= 0 and not AVPath.getabs(paths[1]) then
		return "."
	end
	-- Windows drive letters are already seperated by slashes.
	return (last_abs == "/" and "/" or "") .. table.concat(parts, AVPath.SEPERATOR)
end

--- Gets the path relative to another.
---@param path string
---@param base string?  # Default current dir.
---@return string
function AVPath.relative(path, base)
	base = AVPath.norm(base or ".")
	path = AVPath.norm(path)
	local common = AVPath.common{base, path}
	if common ~= "." then
		path = path:sub(#common+2, -1)
		base = base:sub(#common+1)
	end
	local parcount = 0
	for s in base:gmatch("[^\\/]+") do if s ~= "." then parcount = parcount + 1 end end
	if parcount > 0 then
		return AVPath.join{string.rep(".." .. AVPath.SEPERATOR, parcount), path}
	end
	return path
end

--- Checks if a path exists.
---@param path string
---@return boolean
function AVPath.exists(path)
	local f, _, code = io.open(path, "rb")
	-- Linux & Windows code `2`, "No such file or directory"
	if code == 2 then
		return false
	end
	if f then
		f:close()
	end
	return true
end

--- Checks if a path is a directory.
---@param path string
---@return boolean
function AVPath.isdir(path)
	-- On Linux, the dir will open but the read will error, code `21`.
	-- On Windows, the dir will error when trying to open, code `13`.
	local f, _, code = io.open(path, "rb")
	if code == 13 or (f and select(3, f:read(0)) == 21) then
		if f then f:close() end
		return true
	end
	return false
end

--- Checks if a path is a file.
---@param path string
---@return boolean
function AVPath.isfile(path)
	local f, _, code = io.open(path, "rb")
	if code ~= 2 and not (code == 13 or (f and select(3, f:read(0)) == 21)) then
		if f then f:close() end
		return true
	end
	if f then f:close() end
	return false
end

--- Gets the current working directory.
---@return string
function AVPath.cwd()
	---@type string?
	local cwd = os.getenv("PWD")
	if not cwd or #cwd <= 0 then
		cwd = io.popen("cd"):read("*l")
	end
	return (cwd and #cwd > 0 and cwd) or nil
end


return AVPath
