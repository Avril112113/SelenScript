local verstr = _VERSION:sub(5)

package.path = "?/init.lua;libs/?.lua;libs/?/init.lua;libs/?/?.lua;" .. package.path
package.cpath = "libs/" .. verstr .. "/?.dll;libs/?.dll;" .. package.cpath
require "printToFile"


local function run(args)
	for _, file in ipairs(args) do
		file = file:gsub("%.lua$", "")
		print("------ Running:" .. file .. ".lua ------")
		dofile(file..".lua")
	end
	print("------ ------ ------ ------")

	print("Exit.")
	os.exit()
end


if love ~= nil then
	function love.load(...)
		run(({...})[1])
	end
else
	local args = {...}
	run(args)
end