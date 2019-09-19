-- this file contains commonly used stuff
-- its here due to transpiler.lua and vm.lua using the same code


local common = {}


function common.assign_local(ast, file)
	return ast.varlist.type ~= "varlist" and (ast.scope == "local" or (ast.scope == "" and file.settings.default_local))
end


return common
