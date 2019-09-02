-- currently using love2d as this laptop does not have luajit setup, and love2d use's luajit

package.path = package.path .. ";libs/?.lua;libs/?/init.lua"
package.cpath = package.cpath .. ";libs/?.dll"
require "printToFile"

require "run_tests"

print("Exit.")
os.exit()
