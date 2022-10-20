-- Created by: Dude112113
-- Version: 1.3
local original_print = print

local socket = require "socket"
local colors = require "terminal_colors"


-- TODO: log to file
local logging = {
	logging_source = debug.getinfo(1).source,
	LEVELS = {
		DEBUG = colors.debug .. "DEBUG" .. colors.reset,
		INFO = colors.info .. "INFO" .. colors.reset,
		WARN = colors.warn .. "WARN" .. colors.reset,
		ERROR = colors.error .. "ERROR" .. colors.reset,
	},
}
logging.LEVELS.DEFAULT = logging.LEVELS.DEBUG


function logging.get_source()
	local i = 0
	while true do
		local data = debug.getinfo(i)
		if data == nil then
			break
		elseif data.source ~= logging.logging_source and data.source ~= "=[C]" then
			break
		end
		i = i + 1
	end
	return debug.getinfo(i).source:sub(2, -1):gsub("/init", ""):gsub(".lua", ""):gsub("/", ".")
end

---@param log_type string
---@param s any
---@param ... any
function logging._log(log_type, s, ...)
	local source = logging.get_source()
	local prefix = colors.fix .. "[" .. log_type .. colors.fix .. "]\t" .. colors.reset .. source .. colors.fix
	prefix = prefix .. ": "
	local msgParts = {prefix .. colors.reset .. tostring(s)}
	for _, v in ipairs({...}) do
		table.insert(msgParts, "\t")
		table.insert(msgParts, tostring(v))
	end
	table.insert(msgParts, colors.reset)
	local str = table.concat(msgParts):gsub("(\r?\n\r?)", "%1" .. colors.strip(prefix):gsub("[^\t]", " "))
	original_print(str)
	if logging.sock ~= nil then
		logging.sock:send(str .. "\n")
	end
end

---@param s any
---@param ... any
function logging.print(s, ...)
	logging._log(logging.LEVELS.DEFAULT, s, ...)
end
print = logging.print

---@param s any
---@param ... any
function logging.print_debug(s, ...)
	logging._log(logging.LEVELS.DEFAULT, s, ...)
end
---@diagnostic disable-next-line: lowercase-global
print_debug = logging.print_debug

---@param s any
---@param ... any
function logging.print_info(s, ...)
	logging._log(logging.LEVELS.INFO, s, ...)
end
---@diagnostic disable-next-line: lowercase-global
print_info = logging.print_info

---@param s any
---@param ... any
function logging.print_warn(s, ...)
	logging._log(logging.LEVELS.WARN, s, ...)
end
---@diagnostic disable-next-line: lowercase-global
print_warn = logging.print_warn

---@param s any
---@param ... any
function logging.print_error(s, ...)
	logging._log(logging.LEVELS.ERROR, s, ...)
end
---@diagnostic disable-next-line: lowercase-global
print_error = logging.print_error


--- Requires LuaJIT
--- https://stackoverflow.com/questions/64919350/enable-ansi-sequences-in-windows-terminal
function logging.windows_enable_ansi()
	local ffi = require"ffi"
	ffi.cdef[[
	typedef int BOOL;
	static const int INVALID_HANDLE_VALUE               = -1;
	static const int STD_OUTPUT_HANDLE                  = -11;
	static const int ENABLE_VIRTUAL_TERMINAL_PROCESSING = 4;
	intptr_t GetStdHandle(int nStdHandle);
	BOOL GetConsoleMode(intptr_t hConsoleHandle, int* lpMode);
	BOOL SetConsoleMode(intptr_t hConsoleHandle, int dwMode);
	]]
	---@diagnostic disable: undefined-field
	local console_handle = ffi.C.GetStdHandle(ffi.C.STD_OUTPUT_HANDLE)
	assert(console_handle ~= ffi.C.INVALID_HANDLE_VALUE)
	local prev_console_mode = ffi.new"int[1]"
	assert(ffi.C.GetConsoleMode(console_handle, prev_console_mode) ~= 0, "This script must be run from a console application")
	assert(ffi.C.SetConsoleMode(console_handle, bit.bor(prev_console_mode[0], ffi.C.ENABLE_VIRTUAL_TERMINAL_PROCESSING or 0)) ~= 0)
	---@diagnostic enable: undefined-field
end

function logging.remote_connect(ip, port)
	ip = ip or "localhost"
	port = port or 3429
	print_info("Connecting to logging serve server")
	local sock = socket.tcp()
	sock:settimeout(1)
	local ok, err = sock:connect(ip, port)
	if err ~= nil then
		print_error("remote_connect()", err)
		return
	end
	logging.sock = sock
end

--- WARNING: This function will loop forever
function logging.remote_serve(ip, port)
	ip = ip or "0.0.0.0"
	port = port or 3429
	logging.server = socket.bind(ip, port)
	while true do
		local client = logging.server:accept()
		original_print(("------------------------ logging remote connection from %s:%s ------------------------"):format(client:getsockname()))
		client:settimeout(5)
		while true do
			local line, err = client:receive()
			if err ~= nil then
				print_error("remote_serve()", err)
				client:close()
				break
			else
				original_print(line)
			end
		end
	end
end


return logging

