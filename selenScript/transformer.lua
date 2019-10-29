local transformer = {}
transformer.__index = transformer


function transformer.new(settings)
	local self = setmetatable({}, transformer)
	self.settings = settings or {}
	self.diagnostics = {}
	self.transformers = {
		require "selenScript.transformers.statements".new(self),
		require "selenScript.transformers.values".new(self)
	}
	return self
end


function transformer:transform(ast)
	local foundTransformer = false
	for _, transformerObj in ipairs(self.transformers) do
		if transformerObj[ast.type] ~= nil then
			foundTransformer = true
			ast = transformerObj[ast.type](transformerObj, ast)
			break
		end
	end
	if not foundTransformer then
		local toRemove = {}
		for i, v in pairs(ast) do
			if type(v) == "table" and v.type ~= nil and i ~= "parent" then
				local newValue = self:transform(v)
				if newValue == nil and type(i) == "number" and #v <= i then
					table.insert(toRemove, i)
				else
					ast[i] = newValue
				end
			end
		end
		for i=#toRemove,1,-1 do
			local key = toRemove[i]
			table.remove(ast, key)
		end
	end
	return ast
end


return transformer
