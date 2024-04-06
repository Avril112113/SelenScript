local args = {...}

package.path = package.path .. "libs/?.lua;libs/?/init.lua;test/libs/?.lua;test/libs/?/init.lua;"
package.cpath = package.cpath .. "libs/" .. _VERSION:sub(5) .. "/?.dll;libs/?.dll;"


local AvTest = require "avtest.init"


AvTest.Runner.new()
	:setOutputFileEnabled(true)
	:setOutputFilePerTest(true)
	:setOutputFileStripColors(false)
	:addWhitelist(args[1])
	:addBlacklist("./tests/test_utils.lua")
	:addBlacklist("./tests/parser/lua/lua_official_tests/tests")
	:addBlacklist("./tests/parser/selenscript/typing.lua")
	:addDir("./tests")
	:runTests()
