---@class SS_Symbol
local symbol = {}
symbol.__index = symbol


function symbol.new(tbl)
	local self = setmetatable({}, symbol)
	self.name = tbl.name or error("Symbol must have a name")
	self.value = tbl.value or {type="nil", start=-1, finish=-1}
	self.declarations = {}
	self.references = {}

	return self
end
function symbol:addDeclaration(ast)
	table.insert(self.declarations, ast)
end
function symbol:addReference(ast)
	table.insert(self.references, ast)
end


return symbol
