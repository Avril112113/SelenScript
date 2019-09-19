local parse = require("selenScript.parser").parse
local transpiler = require "selenScript.transpiler"
local helpers = require "selenScript.helpers"
local vm = require "selenScript.vm"

local default = helpers.default_value


local file = {}
file.__index = file


--- results unexpected
--- a lot of stuff will not work
--- used for testing mostly
function file.new_fake(parse_result)
	local self = setmetatable({}, file)
	self.settings = {
		include_provided_deps=false,
		default_local=false
	}
	self.diagnostics = {}
	self.parse_result = parse_result
	self.ast = parse_result.ast
	return self
end

function file.new(settings)
	local self = setmetatable({}, file)

	self.project = settings.project
	if self.project ~= nil then
		table.insert(self.project.files, self)
	end

	self.settings = {
		path=settings.path or error("settings.path was omitted"),
		include_provided_deps=default(settings, true),
		default_local =settings.default_local,  -- odd space, syntax colors messed up :/
		globals=settings.globals
	}
	if self.settings.default_local == nil then
		if self.project == nil then
			self.settings.default_local = true
		else
			self.settings.default_local = default(self.project.settings.default_local, true)
		end
	end
	if self.settings.globals == nil then
		if self.project == nil then
			self.settings.globals = helpers.default_globals()
		else
			self.settings.globals = self.project.settings.globals or helpers.default_globals()
		end
	end

	self.diagnostics = {}

	self:changed()
	local first_diagnostic = self.diagnostics[1]
	if first_diagnostic ~= nil and first_diagnostic.type == "file_not_found" then
		error(first_diagnostic.msg)
	end

	return self
end

function file:changed()
	local f = io.open(self.settings.path, "r")
	if f == nil then
		self:add_diagnostic {
			serverity="warn",
			type="file_not_found",
			start=1,
			finish=1,
			msg="failed to open file '" .. self.path .. "'"
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
			type=err.type,
			start=err.start,
			finish=err.finish,
			msg=err.msg,
			fix=err.fix,
			ast=err.ast,
		}
	end

	self:create_new_vm()

	local ok, lua_output, trans = pcall(transpiler.transpile, self)
	if not ok then
		self:add_diagnostic {
			serverity="warn",
			type="transpiler_error",
			start=1,
			finish=1,
			msg="Transpiler Error:\n" .. tostring(lua_output)
		}
	else
		self.provided_deps = trans.provided_deps

		if self.project ~= nil then
			if self.settings.include_provided_deps then
				lua_output = 'require"' .. self.project.provided_deps_require .. '"\n' .. lua_output
			end
			self:write_file(lua_output)
			self.project:write_provided_deps()
		else
			if self.settings.include_provided_deps then
				lua_output = self:str_deps() .. lua_output
			end
			self:write_file(lua_output)
		end
	end
end

function file:create_new_vm()
	local ok, errOrVm = pcall(vm.new, self.ast, self)
	if not ok then
		self:add_diagnostic {
			serverity="warn",
			type="vm_create_error",
			start=1,
			finish=1,
			msg="VM Creation Error:\n" .. tostring(errOrVm)
		}
	else
		self.vm = errOrVm
	end
end
function file:run_vm()
	local ok, errOrBlock = pcall(self.vm.run, self.vm, self.ast)
	if not ok then
		self:add_diagnostic {
			serverity="warn",
			type="vm_run_error",
			start=1,
			finish=1,
			msg="VM Run Error:\n" .. tostring(errOrBlock)
		}
	else
		self.vm.block = errOrBlock
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
			type="file_not_found",
			start=1,
			finish=1,
			msg="failed to write file '" .. self:get_output_path() .. "'"
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
