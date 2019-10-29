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
	for _, transformerObj in ipairs(self.transformers) do
		if transformerObj[ast.type] ~= nil then
			ast = transformerObj[ast.type](transformerObj, ast)
			break
		end
	end
	return ast
end


return transformer
