-- this file contains commonly used stuff
-- its here due to transpiler.lua and vm.lua using the same code


local common = {}


function common.assign_local(ast, file)
	local isNamesOnly = true
	if ast.varlist.type == "varlist" then
		for i, v in ipairs(ast.varlist) do
			if v.expr ~= nil or v.index ~= nil then
				isNamesOnly = false
				break
			end
		end
	end
	return isNamesOnly and (ast.scope == "local" or (ast.scope == "" and file.settings.default_local))
end


return common
