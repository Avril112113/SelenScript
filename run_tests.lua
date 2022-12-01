package.path = "?/init.lua;libs/?.lua;libs/?/init.lua;libs/?/?.lua;" .. package.path
package.cpath = "libs/" .. _VERSION:sub(5) .. "/?.dll;libs/?.dll;" .. package.cpath
require "logging".set_log_file("tests.log").windows_enable_ansi()


local TestLib = require "testlib"


local testResults = TestLib.run_tests("tests")
TestLib.print_results(testResults)
TestLib.write_results(testResults)
