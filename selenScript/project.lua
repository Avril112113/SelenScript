local default = require("selenScript.helpers").default_value


local project = {}
project.__index = project

function project.new(settings)
	local self = setmetatable({}, project)

	self.src_dir = settings.src_dir or error("setting.src_dir was omitted")
	self.out_dir = settings.out_dir or settings.src_dir

	self.files = {}

	return self
end

return project
