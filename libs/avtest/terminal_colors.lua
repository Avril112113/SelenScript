-- Created by: Avril112113
-- Version: 1.2

local colors = {}

---@param s string
---@return string
function colors.strip(s)
	return (s:gsub("\x1b[%[%]][%d;]*m", ""))
end

colors.CSI = "\x1b["
colors.OSC = "\x1b]"

colors.reset = colors.CSI .. "0m"
colors.bold = colors.CSI .. "1m"
colors.faint = colors.CSI .. "2m"
colors.italic = colors.CSI .. "3m"
colors.underline = colors.CSI .. "4m"
colors.strike = colors.CSI .. "9m"

colors.black = colors.CSI .. "30m"
colors.red = colors.CSI .. "31m"
colors.green = colors.CSI .. "32m"
colors.yellow = colors.CSI .. "33m"
colors.blue = colors.CSI .. "34m"
colors.magenta = colors.CSI .. "35m"
colors.cyan = colors.CSI .. "36m"
colors.white = colors.CSI .. "37m"
colors.bright_black = colors.CSI .. "30;1m"
colors.bright_red = colors.CSI .. "31;1m"
colors.bright_green = colors.CSI .. "32;1m"
colors.bright_yellow = colors.CSI .. "33;1m"
colors.bright_blue = colors.CSI .. "34;1m"
colors.bright_magenta = colors.CSI .. "35;1m"
colors.bright_cyan = colors.CSI .. "36;1m"
colors.bright_white = colors.CSI .. "37;1m"

colors.bg_black = colors.CSI .. "40m"
colors.bg_red = colors.CSI .. "41m"
colors.bg_green = colors.CSI .. "42m"
colors.bg_yellow = colors.CSI .. "43m"
colors.bg_blue = colors.CSI .. "44m"
colors.bg_magenta = colors.CSI .. "45m"
colors.bg_cyan = colors.CSI .. "46m"
colors.bg_white = colors.CSI .. "47m"
colors.bg_bright_black = colors.CSI .. "40;1m"
colors.bg_bright_red = colors.CSI .. "41;1m"
colors.bg_bright_green = colors.CSI .. "42;1m"
colors.bg_bright_yellow = colors.CSI .. "43;1m"
colors.bg_bright_blue = colors.CSI .. "44;1m"
colors.bg_bright_magenta = colors.CSI .. "45;1m"
colors.bg_bright_cyan = colors.CSI .. "46;1m"
colors.bg_bright_white = colors.CSI .. "47;1m"

colors.error = colors.bright_red
colors.warn = colors.CSI .. "38;5;208m"
colors.info = colors.CSI .. "38;5;27m"
colors.debug = colors.CSI .. "38;5;119m"
colors.fix = colors.CSI .. "38;5;244m"


return colors
