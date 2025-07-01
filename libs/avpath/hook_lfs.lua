local _, lfs = pcall(require, "lfs")

if not lfs then return end

local AvPath = require "avpath.base"


--- Gets the current working directory.
---@return string?
function AvPath.cwd()
	local cwd = lfs.currentdir()
	return (cwd and #cwd > 0 and cwd) or nil
end
