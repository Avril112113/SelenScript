-- This file is dedicated to providing typing info using EmmyLua
-- and is only used when the types can't be supplied in existing code

---@class SS_NewFileArgs
local newFileArgs = {
	-- path to a file (ending with `.sl` or `.lua` for example)
	---@type string
	path=nil,
	--- should we watch the file for change's
	--- ignored when `path` is not provided
	---@type boolean
	watch=true,
	--- automatically write the output to the file when any change is made
	--- ignored when `path` is not provided
	---@type boolean
	auto_transpile=true,

	--- can be provided if not path can be provided
	--- ignored if `path` is used
	---@type string
	code=nil,
	--- provide with `code` arg, used for test code and saves having to re-parse the same thing 2 times
	--- ignored if `path` is used
	parse_result=nil,

	--- can be used to force the type the file is known as
	--- defaults to `sl` if `code` is used
	--- gets retrived from the file extention if `path` is used
	---@type string
	type=nil,

	--- allow writing to files (if false, no output will be written to disk)
	---@type boolean
	allow_file_write=true,
	---@class SS_NewFileArgs_provided_deps
	provided_deps={
		--- weather or not to write a seperate file for all dependencies on the current project
		--- is no project then just its own file
		---@type boolean
		seperate_file=true,
		--- should we include the dependencies in the output file
		--- ignored if seperate_file is true
		---@type boolean
		include_in_file=true
	}
}
