-- currently using love2d as this laptop does not have luajit setup, and love2d use's luajit

package.path = package.path .. ";libs/?.lua;libs/?/init.lua"
package.cpath = package.cpath .. ";libs/?.dll"
require "printToFile"


function love.load(...)
	local args = ({...})[1]
	local file = args[1] or "run_tests"

	require(file)

	print("Exit.")
	os.exit()
end
