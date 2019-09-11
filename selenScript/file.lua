local parse = require("selenScript.parser").parse
local transpiler = require "selenScript.transpiler"
local provided = require "selenScript.provided"
local helpers = require "selenScript.helpers"

local default = helpers.default_value


local file = {}
file.__index = file


function file.new(settings)
	local self = setmetatable({}, file)

	self.settings = {
		path=settings.path or error("settings.path was omitted"),

		include_provided_deps=default(settings, true),
	}
	self.project = settings.project
	if self.project ~= nil then
		table.insert(self.project.files, self)
	end

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
	self.ast = self.parse_result.ast
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

	local lua_output, trans = transpiler.transpile(self)
	self.provided_deps = trans.provided_deps

	if self.project ~= nil then
		self:write_file('require("__sls_provided_deps")' .. lua_output)
		self.project:write_provided_deps()
	else
		self:write_file(self:str_deps() .. lua_output)
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

function file:write_file(lua_output)
	local f = io.open(self:get_output_path(), "w")
	if f == nil then
		self:add_diagnostic {
			serverity="warn",
			start=1,
			finish=1,
			msg="failed to write file '" .. self:get_output_path() .. "'",
			file_not_found=true  -- only used to identify this error for file.new()
		}
	else
		f:write(lua_output)
		f:close()
	end
end

function file:get_output_path()
	local path = self.settings.path
	if self.project ~= nil then
		path = self.project.out_dir .. "/" .. path:gsub("^" .. self.project.out_dir, "")
	end
	print(path)
	return self.settings.path:gsub("%.sl$", "") .. ".lua"
end

function file:str_deps()
	local str = ""
	local gotten_deps = {}
	for dep_name, dep in pairs(self.provided_deps) do
		str = str .. helpers.str_dep(dep_name, dep, gotten_deps)
	end
	return str
end

return file
