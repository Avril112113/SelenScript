local luzer = require("luzer")

local jit = require "jit"

package.path = "?/init.lua;libs/?.lua;libs/?/init.lua;libs/?/?.lua;" .. package.path
if jit.os == "Windows" then
	package.cpath = "?.dll;libs/" .. _VERSION:sub(5) .. "/?.dll;libs/?.dll;" .. package.cpath
else
	package.cpath = "?.so;libs/" .. _VERSION:sub(5) .. "/?.so;libs/?.so;" .. package.cpath
end
require "logging".set_log_file("test_local/out.log", true).windows_enable_ansi()


local Parser = require "SelenScript.parser.parser"
local AST = require "SelenScript.parser.ast"
local Emitter = require "SelenScript.emitter.emitter"
local Transformer = require "SelenScript.transformer.transformer"


local parser, errors = Parser.new({
	selenscript=true,
})
assert(parser)
assert(#errors == 0)

local transformer = Transformer.new("ss_to_lua")

local emitter_lua = Emitter.new("lua", {})


local function TestOneInput(buf)
	local fdp = luzer.FuzzedDataProvider(buf)

	local source = fdp:consume_string(512)
	if source == "0" then
		error("Tehee")
	end

	local ast_source, perrors, comments = parser:parse(source)
	local terrors = transformer:transform(ast_source)
	local output_lua_source, source_map = emitter_lua:generate(ast_source)
	return (#perrors > 0 or #terrors > 0) and -1 or 0
end

local args = {
    only_ascii = 1,
    print_pcs = 1,
	corpus = "fuzz_corpus",
}
luzer.Fuzz(TestOneInput, nil, args)
