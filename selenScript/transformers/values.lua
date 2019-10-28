local helpers = require "selenScript.helpers"

local values = {}
values.__index = values


function values.new(transformer)
	local self = setmetatable({}, values)
	self.transformer = transformer
	return self
end


values["nil"] = function(self, ast)
	return ast
end


return values
