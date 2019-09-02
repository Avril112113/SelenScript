export local function foo() end  -- NOTE: local not required

local var = 32
export var  -- NOTE: the given name is used for export
export var as var2you

export local foobar = "foobar"

-- this works, but should not be used like this
export function tbl.func() end
export tbl.val = "im a value"
