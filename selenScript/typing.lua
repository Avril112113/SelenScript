-- This file is dedicated to providing typing info using EmmyLua
-- and is only used when the types can't be supplied in existing code

---@class SS_NewFileArgs
local newFileArgs = {
	-- path to a file (ending with `.sl` or `.lua` for example)
	---@type string
	path=nil,

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
	type=nil
}
