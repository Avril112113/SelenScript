local parse = require("selenScript.parser").parse

local default = require("selenScript.helpers").default_value


local file = {}
file.__index = file


function file.new(settings)
	local self = setmetatable({}, file)

	self.settings = {
		path=settings.path or error("settings.path was omited"),

		include_provided_deps=default(settings, true),
	}

	self.diagnostics = {}

	self:changed()
	local first_diagnostic = self.diagnostics[1]
	if first_diagnostic ~= nil and first_diagnostic.file_not_found == true then
		error(first_diagnostic.msg)
	end

	return self
end

function file:changed()
	local f = io.open(self.settings.path, "r")
	if f == nil then
		self:add_diagnostic {
			serverity="warn",
			start=1,
			finish=1,
			msg="failed to open file '" .. self.path .. "'",
			file_not_found=true  -- only used to identify this error for file.new()
		}
		return
	end
	self.code = f:read("*a")
	f:close()

	self.parse_result = parse(self.code)
	for _, err in pairs(self.parse_result.errors) do
		self:add_diagnostic {
			serverity="error",
			start=err.start,
			finish=err.finish,
			msg=err.msg,
			fix=err.fix,
			ast=err.ast,
		}
	end
end

function file:complete(pos)
	local completions = {}
	error("file:complete() not implemented")
	return completions
end


function file:add_diagnostic(diagnostic)
	table.insert(self.diagnostics, diagnostic)
end

return file
