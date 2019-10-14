--[[
local testfile = "test.sl"
local testdir = "tests/test/"  -- dont forget to end with a slash


local selen = require "selenScript"


local f = io.open(testdir .. testfile, "r")
local filedata = f:read("*a")
f:close()

local ast = selen.parser.parse(filedata)
local vm = selen.VM()
]]


local createClass = require "selenScript.lib.createClass"


local Cls = createClass("Cls")
local Cls2 = createClass("Cls2")
table.insert(Cls2.__inherits, Cls)


Cls.a = 1
print(Cls2.a)
