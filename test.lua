package.path = "?/init.lua;libs/?.lua;libs/?/init.lua;libs/?/?.lua;" .. package.path
package.cpath = "libs/" .. _VERSION:sub(5) .. "/?.dll;libs/?.dll;" .. package.cpath
require "logging".set_log_file("out.log").windows_enable_ansi()


local PRINT_COMMENTS = false
local PRINT_PARSED_AST = false
local PRINT_TRANSFORMED_AST = false


local function read_file(path)
	local f = assert(io.open(path, "r"))
	local data = f:read("*a")
	f:close()
	return data
end
local function write_file(path, data)
	local f = assert(io.open(path, "w"))
	f:write(data)
	f:close()
	return data
end

local Json = require "json"

local Parser = require "SelenScript.parser.parser"
local AST = require "SelenScript.parser.ast"
local Emitter = require "SelenScript.emitter.emitter"
local Transformer = require "SelenScript.transformer.transformer"

-- function debug.relabelDbgFilter(name)
-- 	return name ~= "Sp" and name ~= "Sc" and name ~= "Comment" and name ~= "LineComment" and name ~= "LongComment"
-- end

local parser, errors = Parser.new()
if #errors > 0 then
	print_error("-- Grammar Errors: " .. #errors .. " --")
	for _, v in ipairs(errors) do
		print_error((v.id or "NO_ID") .. ": " .. v.msg)
	end
end

write_file("test_ss_built_grammar.relabel", parser ~= nil and parser.grammar_src or "")

if parser == nil then
	print_warn("Exit early, parser object is nil")
	os.exit(-1)
	return  -- Make diagnostics happy
end

local input_path = "test_input.sel"
local source = read_file(input_path)
local ast_source, errors, comments = parser:parse(source, input_path)

if #errors > 0 then
	print_error("-- Parse Errors: " .. #errors .. " --")
	for _, v in ipairs(errors) do
		print_error(v.id .. ": " .. v.msg)
	end
end

if PRINT_COMMENTS then
	print_info("-- Comments: " .. #comments .. " --")
	for _, v in ipairs(comments) do
		print(AST.tostring_ast(v))
	end
end

if PRINT_PARSED_AST then
	print_info("-- Parsed AST: --")
	print(AST.tostring_ast(ast_source))
end

local transformer = Transformer.new("ss_to_lua")
local errors = transformer:transform(ast_source)

if #errors > 0 then
	print_error("-- Transform Errors: " .. #errors .. " --")
	for _, v in ipairs(errors) do
		print_error(v.id .. ": " .. v.msg)
	end
end

if PRINT_TRANSFORMED_AST then
	print_info("-- Transformed AST: --")
	print(AST.tostring_ast(ast_source))
end

local emitter_lua = Emitter.new("lua", {
	math_always_parenthesised = false
})
local output_lua_source, source_map = emitter_lua:generate(ast_source)
write_file("test_input.lua", tostring(output_lua_source))
write_file("test_input.lua.map", tostring(source_map:generate(source, output_lua_source, "test_input.sel", "test_input.lua")))

local SourceMap = require "source-map"
local inSourceMap = SourceMap.fromJson(Json.decode(read_file("test_input.lua.map")))
print(inSourceMap.sourceRoot .. " : " .. inSourceMap.file)
for generatedLine, columnList in ipairs(inSourceMap.mappings) do
	for _, column in ipairs(columnList) do
		print(("%s:%s:%s\t->\t%s:%s:%s%s"):format(
			inSourceMap.file, generatedLine, column.generatedColumn,
			column.source, column.originalLine, column.originalColumn,
			column.name and " ("..column.name..")" or ""
		))
	end
end

print_info("-- Finished --")
