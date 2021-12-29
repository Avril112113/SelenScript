local RePreProcess = require "repreprocess"
local ReLabel = require "drelabel"

local ParserErrors = require "SelenScript.parser.errors"
local Utils = require "SelenScript.utils"
local AST = require "SelenScript.parser.ast"

local GRAMMAR_DIRECTORY = Utils.modPathToPath(Utils.modPathParent(Utils.modPathParent(...)) .. ".grammar")

-- Builds up a relabel grammer from seperated parts
local Grammar = {
	files = {
		["LuaBase.relabel"]=false,
		["Lua.relabel"]=false,
		["SelenScript.relabel"]=false,
		["SelenScriptBase.relabel"]=false,
	},
	cache = {},
	CORE_GRAMMAR = [[
#include EntryPoint
]],
}


--- Build the relabel grammar from the seperated files using RePreProcess
---@param declarations table<string,boolean>|nil @ Potentially mutated during call
---@param entry_point string @ Override the entry point
---@return boolean, string, Error[] @ TODO: make all errors ErrorBase, they are not currently
function Grammar.build(declarations, entry_point)
	declarations = declarations or {}
	local rpp = RePreProcess.new()
	-- TODO: convert errors from rpp:process() to our error objects
	local entry_code = Grammar.CORE_GRAMMAR
	if entry_point ~= nil then
		entry_code = "entry <- " .. entry_point
	end
	local ok, result, all_errors = rpp:process(entry_code)
	if not ok then table.insert(all_errors, ParserErrors.UNIDENTIFIED(result, tostring(result))) end
	if not ok then
		return ok, nil, all_errors
	end
	for file, data in pairs(Grammar.files) do
		if not data then
			data = Utils.readFile(GRAMMAR_DIRECTORY .. "/" .. file)
			Grammar.files[file] = data
		end
		-- TODO: convert errors from rpp:process() to our error objects
		---@diagnostic disable-next-line: redefined-local
		local ok, result, errors = rpp:process(data)
		if not ok then table.insert(all_errors, ParserErrors.UNIDENTIFIED(result, tostring(result))) end
		for _, err in ipairs(errors) do
			table.insert(all_errors, err)
		end
		if not ok then
			return ok, nil, all_errors
		end
	end
	---@diagnostic disable-next-line: redefined-local
	local ok, result, errors = rpp:generate(declarations)
	if not ok then table.insert(all_errors, ParserErrors.UNIDENTIFIED(result, tostring(result))) end
	for _, err in ipairs(errors) do
		table.insert(all_errors, err)
	end
	if not ok then
		return ok, nil, all_errors
	end
	return true, result, all_errors
end

---@return boolean, LPegGrammar
function Grammar.compile(built_grammar)
	local ast_defs = AST.new()
	local ok, regrammar = pcall(ReLabel.compile, built_grammar, ast_defs)
	if not ok then
		return false, ParserErrors.GRAMMAR_SYNTAX(regrammar, tostring(regrammar))
	end
	return ok, regrammar, ast_defs
end


return Grammar
