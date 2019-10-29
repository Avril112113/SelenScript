local helpers = require "selenScript.helpers"

local statements = {}
statements.__index = statements


function statements.new(transformer)
	local self = setmetatable({}, statements)
	self.transformer = transformer
	return self
end




return statements
