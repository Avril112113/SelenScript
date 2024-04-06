local lfs = require "lfs"

local TestGroup = require "avtest.group"


---@param path string
---@param recursive boolean
---@param filter (fun(path:string):boolean)?
---@return Group[]
---@diagnostic disable-next-line: duplicate-set-field
function TestGroup:loadFolder(path, recursive, filter)
	local groups = {}
	for sub in lfs.dir(path) do
		local subpath = path .. "/" .. sub
		local attributes = lfs.attributes(subpath)
		if attributes.mode == "file" and sub:sub(-4, -1) == ".lua" then
			if not filter or filter(subpath) then
				table.insert(groups, self:loadFile(subpath))
			end
		elseif attributes.mode == "directory" and recursive and sub:sub(1, 1) ~= "." then
			if not filter or filter(subpath) then
				local group = TestGroup.new(sub)
				self:addGroup(group)
				group:loadFolder(subpath, recursive, filter)
				table.insert(groups, group)
			end
		end
	end
	return groups
end
