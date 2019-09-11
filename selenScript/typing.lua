-- This file is dedicated to providing typing info using EmmyLua
-- and is only used when the types can't be supplied in existing code

---@class SS_NewFileArgs
local newFileArgs = {
	-- path to a file (`.sl` or `.lua` for example)
	---@type string
	path=nil,

	--- can be provided if not path can be provided (ignored if path is used)
	---@type string
	code=nil,

	--- can be used to force the type the file is known as (required is path is not supplied)
	---@type string
	type=nil
}
