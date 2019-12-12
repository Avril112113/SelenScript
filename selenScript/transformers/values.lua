local helpers = require "selenScript.helpers"

local values = {}
values.__index = values


---@param transformer SS_Transformer
function values.new(transformer)
	local self = setmetatable({}, values)
	self.transformer = transformer
	return self
end


return values
