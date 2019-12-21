-- [[
global global_result = "I should be global"
local local_result = "I should be local"
default_scope_result = "I should be in the default scope"

interface TestInterface
	foo: string
	bar: number
	f: function->TestInterface
end

local testInterfaceTbl: TestInterface = {
	foo="foo?",
	bar=404,
	f=function() return {} end
}


local if_expr_result = if true then 1 else 2
print("if_expr_result", if_expr_result and "Working" or ">>> BROKEN")

local do_expr_result = do
	return "Working"
end
print("do_expr_result", do_expr_result or ">>> BROKEN")


local do_expr_result = do
	return do
		return "Working"
	end
end
print("do_expr_result", do_expr_result or ">>> BROKEN")


local while_expr_result = while true do
	break "Working"
end
print("while_expr_result", while_expr_result or ">>> BROKEN")


local continue_result = 0
for i=1,10 do
	if i > 5 then continue end
	continue_result = continue_result + 1
end
print("continue_result", continue_result == 5 and "Working" or ">>> BROKEN")


local function dec(f)
	return function() f("Working") end
end
@dec()
local function use_decorater(arg) print("use_decorater", arg or ">>> BROKEN") end
use_decorater()
--]]
