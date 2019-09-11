-- currently using love2d as this laptop does not have luajit setup, and love2d use's luajit

package.path = package.path .. ";libs/?.lua;libs/?/init.lua"
package.cpath = package.cpath .. ";libs/?.dll"
require "printToFile"


function love.load(...)
	local args = ({...})[1]

	for _, file in ipairs(args) do
		file = file:gsub("%.lua$", "")
		print("------ Running:" .. file .. ".lua ------")
		dofile(file..".lua")
	end
	print("------ ------ ------ ------")

	print("Exit.")
	os.exit()
end
