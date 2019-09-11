local helpers = require "selenScript.helpers"

local default = helpers.default_value


local project = {}
project.__index = project

function project.new(settings)
	local self = setmetatable({}, project)

	self.src_dir = settings.src_dir or error("setting.src_dir was omitted")
	self.out_dir = settings.out_dir or settings.src_dir

	self.provided_deps_out = settings.provided_deps_out or self.out_dir .. "/__sls_provided_deps.lua"
	self.provided_deps_require = settings.provided_deps_require or "__sls_provided_deps"

	self.settings = {
		default_local =default(settings.default_local, true),  -- odd space, syntax colors messed up :/
		globals=settings.globals or helpers.default_globals()
	}

	self.files = {}

	return self
end

function project:write_provided_deps()
	local f = io.open(self.provided_deps_out, "w")
	if f == nil then
		return false, "failed to write file '" .. self.provided_deps_out .. "'"
	else
		f:write(self:str_deps())
		f:close()
		return true, nil
	end
end

function project:str_deps()
	local str = ""
	local gotten_deps = {}
	for _, file in pairs(self.files) do
		for dep_name, dep in pairs(file.provided_deps) do
			str = str .. helpers.str_dep(dep_name, dep, gotten_deps)
		end
	end
	return str
end

return project
