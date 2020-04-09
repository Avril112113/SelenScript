local parser = require "selenScript.parser"
local binder = require "selenScript.binder"
local transpiler = require "selenScript.transpiler"
local transformer = require "selenScript.transformer"


---@class SS_Program
local program = {
	---@type table
	settings=nil,
	---@type table<string,table>
	files=nil
}
program.__index = program


---@param settings table
function program.new(settings)
	local self = setmetatable({}, program)
	self.settings = settings or {}
	if self.settings.defaultLocals == nil then self.settings.defaultLocals = true end
	if self.settings.indent == nil then self.settings.indent = "\t" end
	if self.settings.targetVersion == nil then self.settings.targetVersion = "5.4" end
	if self.settings.src == nil then self.settings.src = "./" end
	if self.settings.out == nil then self.settings.out = "./" end
	self.files = {}

	return self
end


---@param source_file SS_SourceFile
function program:bindSourceFile(source_file)
	local binderInstance = binder.new(source_file)
	source_file.binder = binderInstance
	binderInstance:bind(source_file.block)
end

---@param source_file SS_SourceFile
function program:checkSourceFile(source_file)
	-- checker.checker(source_file)
	error("TODO")
end

---@param source_file SS_SourceFile
---@return string
function program:transpileSourceFile(source_file)
	local transformerInstance = transformer.new(self.settings)
	source_file.transformer = transformerInstance
	local transformedAST = transformerInstance:transform(source_file.block)
	local transpilerInstance = transpiler.new(self.settings)
	source_file.transpiler = transpilerInstance
	local luaSrc = transpilerInstance:transpile(transformedAST)
	return luaSrc
end

---@param source_file SS_SourceFile
function program:transpileAndWriteSourceFile(source_file)
	local luaSrc = self:transpileSourceFile(source_file)
	local localFilePath = source_file.filePath:gsub("%.sel$", ".lua")
	if localFilePath == source_file.filePath then
		localFilePath = localFilePath .. ".lua"
	end
	local f = io.open(self.settings.out .. localFilePath, "w")
	if f == nil then
		error("Failed to write file at " .. self.settings.out .. source_file.filePath)
	end
	f:write(luaSrc)
	f:close()
	return luaSrc
end

---@param source_file SS_SourceFile
function program:addSourceFile(source_file)
	local startTime = os.clock()
	program:bindSourceFile(source_file)
	local endTime = os.clock()
	source_file.bindTime = endTime - startTime
	self.files[source_file] = source_file
end

---@param filepath string
---@return SS_SourceFile
function program:addSourceFileByPath(filepath)
	local f = io.open(self.settings.src .. filepath, "r")
	if f == nil then
		error("Failed to find file " .. self.settings.src .. filepath)
	end
	local src = f:read("*a")
	f:close()
	local source_file = parser.parse(filepath, src, true)
	self:addSourceFile(source_file)
	return source_file
end


return program
