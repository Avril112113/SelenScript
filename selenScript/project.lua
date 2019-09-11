---@class SS_Project
local project = {}
project.__index = project

function project.new()
	local self = setmetatable({}, project)
	self.settings = {
		default_local=true
	}
	---@type table<string,SS_File>
	self.files = {}
	---@type table<string,table>
	self.globals = setmetatable({}, {__mode="v"})

	return self
end

---@param file SS_File
function project:addFile(file)
	file:update_project(self)
end


return project
