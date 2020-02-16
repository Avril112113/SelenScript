---@class SS_Transpiler
local transpiler = {}
transpiler.__index = transpiler


function transpiler.new(settings)
	local self = setmetatable({}, transpiler)
	self.settings = settings or {}
	self.diagnostics = {}
	self.transpilers = {
		require "selenScript.transpiler.operators".new(self),
		require "selenScript.transpiler.values".new(self),
		require "selenScript.transpiler.statements".new(self),
	}
	return self
end


function transpiler:transpile(ast)
	local foundTranspiler = false
	local luaCode
	for _, transpilerObj in ipairs(self.transpilers) do
		if transpilerObj[ast.type] ~= nil then
			foundTranspiler = true
			luaCode = transpilerObj[ast.type](transpilerObj, ast)
			break
		end
	end
	if not foundTranspiler then
		table.insert(self.diagnostics, {
			type="internal",
			start=ast.start,
			finish=ast.finish,
			msg="missing transpiler or transformer for type " .. tostring(ast.type)
		})
		luaCode = "--[[ missing transpiler or transformer for type " .. tostring(ast.type) .. " ]]"
	end
	return luaCode
end


return transpiler
