---@class SS_Program
local program = {
	---@type table
	settings=nil,
	---@type table<string,SS_File>
	files=nil,
	---@type table<string,SS_Symbol>
	globals=nil
}
program.__index = program


function program.new(settings)
	local self = setmetatable({}, program)
	self.settings = settings or {}
	self.files = {}
	self.globals = {}

	return self
end


---@param file SS_File
function program:addFile(file)
	if file.program ~= nil then
		error("File is already in a program")
	end

	self.files[file.filepath] = file
	file.program = self
end


return program
