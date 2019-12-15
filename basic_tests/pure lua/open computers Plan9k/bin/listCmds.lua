local ocCodeComplete = require("ocCodeComplete")
local shell = require("shell")

opts, args = shell.parse(...)

for i,v in pairs(opts) do
	if v ~= opts[1] then
		_ENV[v] = require(v)
	end
end

local data = ocCodeComplete.complete(opts[1], _ENV)
for i, v in pairs(data) do
	print(i, opts[1]..v)
end
