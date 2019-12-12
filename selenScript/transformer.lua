local parser = require "selenScript.parser"


---@class SS_Transformer
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
	self.last_var_num = 0
	return self
end


function transformer:getVarName()
	local var = "__sls" .. self.last_var_num
	self.last_var_num = self.last_var_num + 1
	return var
end

function transformer:transform(ast, transformOnlyChildren)
	if transformOnlyChildren ~= true then
		for _, transformerObj in ipairs(self.transformers) do
			if transformerObj[ast.type] ~= nil then
				return transformerObj[ast.type](transformerObj, ast)
			end
		end
	end

	local i = 1
	while i <= #ast do
		local v = ast[i]
		if type(v) == "table" and v.type ~= nil and i ~= "parent" then
			local newValues = {self:transform(v)}
			local newValue = newValues[1]
			if newValue == nil and type(i) == "number" and #v <= i then
				table.remove(ast, i)
			else
				ast[i] = newValue
				newValue.parent = ast
				i = i + 1
			end
			if #newValues > 1 then
				for valueIndex=2,#newValues do
					local value = newValues[valueIndex]
					table.insert(ast, i, value)
					i = i + 1
				end
			end
		else
			i = i + 1
		end
	end
	for i, v in pairs(ast) do
		if type(v) == "table" and v.type ~= nil and i ~= "parent" and not (type(i) == "number" and i <= #ast) then
			local _ast = self:transform(v)
			ast[i] = _ast
			_ast.parent = ast
		end
	end
	return ast
end


return transformer
