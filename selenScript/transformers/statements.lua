local helpers = require "selenScript.helpers"

local statements = {}
statements.__index = statements


function statements.new(transformer)
	local self = setmetatable({}, statements)
	self.transformer = transformer
	return self
end


function statements:assign(ast)
	return ast
end


return statements
