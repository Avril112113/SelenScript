-- 'grammar.print.txt' is generated using lpeglabel built with debug mode.
-- Command: luajit ./tools/grammar_typing_gen/print_ptree.lua > ./tools/grammar_typing_gen/grammar.ptree.txt


package.path = "?/init.lua;libs/?.lua;libs/?/init.lua;libs/?/?.lua;" .. package.path
package.cpath = "libs/" .. _VERSION:sub(5) .. "/?.dll;libs/?.dll;" .. package.cpath
package.cpath = "C:/Users/avril/AppData/Roaming/luajit/systree/lib/lua/5.1/?.dll;" .. package.cpath

local Parser = require "SelenScript.parser.parser"
local lpeglabel = require "lpeglabel"


local parser, errors = Parser.new()
---@cast parser -?

local parts = {}
for i, v in pairs(parser.ast_defs._bound_methods) do
	table.insert(parts, ("%s = \"%s\""):format(i, v))
end
print(("=[%s  ]"):format(table.concat(parts, "  ")))
lpeglabel.ptree(parser.grammar)
