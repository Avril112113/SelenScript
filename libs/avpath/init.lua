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


-- Some might not be used, but are there for sanity.
local NORM_SPECIAL = {[".."]=true, ["."]=true, ["\\"]=true, ["/"]=true}
--- Normalizes a path.  
--- - Converts slashes to system/configured slashes  
--- - Normalizes `.` and `..` if possible  
--- - Removes trailing and double slashs (leading double slashes are preserved for windows network shares)  
---@param path string
---@return string
function AVPath.norm(path)
	local abs_part = AVPath.getabs(path)
	local parts = {}
	-- Remove the absolute part of the path, as it's added back at the end.
	-- This ensures no `..` can get in the way and this way prevents slash issues.
	if abs_part then
		path = path:sub(#abs_part+1)
	end
	-- Go through all parts of the path.
	for part in path:gmatch("[^\\/]+") do
		if part == ".." then
			-- If there is something to remove and it is valid to be removed.
			if #parts > 0 and not NORM_SPECIAL[parts[#parts]] then
				-- We can apply the pardir, as it's not `..` or `.`
				table.remove(parts, #parts)
			else
				-- Nothing to remove, so just preserve it in the path
				table.insert(parts, part)
			end
		elseif part == "." then
			-- Do nothing...
		else
			table.insert(parts, part)
		end
	end
	-- Ensure leading `./` if it's not absolute and doesn't start with `..` or `.` already
	if not abs_part and not NORM_SPECIAL[parts[1]] then
		table.insert(parts, 1, ".")
	end
	return (abs_part and abs_part:gsub("[\\/]", AVPath.SEPERATOR) or "") .. table.concat(parts, AVPath.SEPERATOR):gsub("^[\\/]([\\/])", "%1")
end

--- Concatinates 2 or more paths together.
---@param parts string[]
---@return string
function AVPath.join(parts)
	return AVPath.norm(table.concat(parts, AVPath.SEPERATOR))
end

--- Weather or not a path is absolute.
---@param path string
---@return string?
function AVPath.getabs(path)
	return path:match("^[\\/][\\/]?") or path:match("^%w:[\\/]")
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
	local last_windows_share
	for i, s in ipairs(paths) do
		local isabs = AVPath.getabs(s)
		if last_abs ~= nil and last_abs ~= isabs then
			return ""
		end
		local snorm = AVPath.norm(s)
		local is_window_share = not not snorm:match("^[\\/][\\/]")
		if last_windows_share ~= nil and last_windows_share ~= is_window_share then
			return ""
		end
		iters[i] = snorm:gmatch("[^\\/]+")
		last_abs = isabs
		last_windows_share = is_window_share
	end
	local parts = {}
	while true do
		local s = iters[1]()
		if s == nil then break end
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
		return last_windows_share and AVPath.SEPERATOR..AVPath.SEPERATOR or "."
	end
	-- Windows drive letters are already seperated by slashes.
	return ((last_windows_share and AVPath.SEPERATOR..AVPath.SEPERATOR) or (last_abs == "/" and "/" or "")) .. table.concat(parts, AVPath.SEPERATOR)
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
