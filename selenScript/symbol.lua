local parser = require "selenScript.parser"


---@class SS_Symbol
local symbol = {}
symbol.__index = symbol


function symbol.new(tbl)
	local self = setmetatable({}, symbol)
	self.key = tbl.key or error("Symbol must have a key")
	self.value = tbl.value or parser.defs["nil"](-1, -1)
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
