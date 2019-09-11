local parser = require "selenScript.parser"
local transpiler = require "selenScript.transpiler"


---@class SS_File
local file = {
	---@type string
	path=nil,
	---@type string
	type=nil,
	---@type string
	code=nil,
	parse_result=nil,
	ast=nil,
	---@type SS_Project
	project=nil,
}
file.__index = file

---@param path string
function file.nameFromPath(path)
	return path:match("([^/\\]+)%..*$")
end


---@param args SS_NewFileArgs
function file.newFile(args)
	local self = setmetatable({}, file)
	-- TODO: args.path should be made abslosute path
	if args.path ~= nil then
		self.path = args.path
		self.type = args.type
		if self.type == nil then
			if self.path:sub(#self.path-3, #self.path) == ".lua" then
				self.type = "lua"
			elseif self.path:sub(#self.path-2, #self.path) == ".sl" then
				self.type = "sl"
			else
				error("arg 'type' was not supplied, and was not able to find it from 'path' arg")
			end
		end
		self.name = args.name
		if self.name == nil then
			self.name = file.nameFromPath(self.path)
		end

		self.watch = args.watch
		if self.watch ~= false then
			-- TODO: add watcher
		end

		self.auto_transpile = args.auto_transpile
		if self.auto_transpile == nil then
			self.auto_transpile = true
		end

		self:file_changed()
	elseif args.parse_result ~= nil or args.code ~= nil then
		assert(args.code ~= nil, "arg 'codde' was omitted")
		self.type = args.type or "sl"
		self.code = args.code
		self.parse_result = args.parse_result
		if self.parse_result == nil then
			self.parse_result = parser.parse(self.code)
		end
		self.ast = self.parse_result.ast
	else
		error("arg 'path' and 'parse_result' was omitted")
	end

	--- this table might be IN the project's globals
	self.globals = setmetatable({}, {__mode="v"})

	return self
end

---@param project SS_Project
function file:update_project(project)
	if self.project then
		self.project.files[self.path] = nil
		self.project.globals[self.path] = nil
	end

	self.project = project

	project.files[self.path] = file
	self.project.globals[self.path] = self.globals

	if self.path ~= nil then
		self:file_changed()
	end
end

function file:file_changed()
	local f= io.open(self.path, "r")
	if f == nil then
		print("WARNING: failed to open file '" .. self.path .. "'")
		return
	end
	self.code = f:read("*a")
	f:close()

	self.parse_result = parser.parse(self.code)
	self.ast = self.parse_result.ast  -- short hand for self.parse_result.ast

	self.diagnostics = {}
	for i, err in pairs(self.parse_result.errors) do
		table.insert(self.diagnostics, {
			serverity="error",
			start=err.start,
			finish=err.finish,
			msg=err.msg,
			fix=err.fix,
			ast=err.ast
		})
	end

	self:ast_changed()
end

function file:ast_changed()
	local luaOutput, trans = transpiler.transpile(self)
	if self.auto_transpile then
		local ok, err = self:write_file(luaOutput)
		if not ok then
			table.insert(self.diagnostics, {
				serverity="warn",
				start=1,
				finish=1,
				msg=err,
			})
		end
	end
end

---@param pos number
function file:complete(pos)
	local completions = {}
	print("file:complete() not implemented")
	return completions
end


---@param data string
function file:write_file(data)
	if self.path == nil then
		return false, "file does not has a path"
	end
	local out_path = self.path .. ".lua"
	local f = io.open(out_path, "w")
	if f == nil then
		return false, "failed to open file"
	end
	f:write(data)
	f:close()
	return true, nil
end


return file
