---@type AvTest.TestEnv
TEST = nil


require "avtest.ext"

return {
	Config=require("avtest.config"),
	TestGroup=require("avtest.group"),
	Test=require("avtest.test"),
	Runner=require("avtest.runner"),
}
