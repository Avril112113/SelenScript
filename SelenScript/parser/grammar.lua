local RePreProcess = require "repreprocess"
local ReLabel = require "drelabel"

local ParserErrors = require "SelenScript.parser.errors"
local Utils = require "SelenScript.utils"
local AST = require "SelenScript.parser.ast"

local GRAMMAR_DIRECTORY = Utils.modPathToPath(Utils.modPathParent(Utils.modPathParent(...)) .. ".grammar")


-- Builds up a relabel grammer from seperated parts
local Grammar = {
	default_entry = "chunk",
	---@type string[]
	files = {
		"LuaBase.relabel",
		"Lua.relabel",
		"SelenScriptBase.relabel",
		"SelenScript.relabel",
	},
	---@type table<string, string>
	_loaded_files={},
}


--- Build the relabel grammar from the seperated files using RePreProcess
---@param declarations table<string,boolean>?
---@param entry_point string? # Override the entry point
---@return boolean, string?, Error[] # TODO: make all errors ErrorBase, they are not currently
function Grammar.build(declarations, entry_point)
	declarations = declarations or {}
	entry_point = entry_point or Grammar.default_entry

	local rpp = RePreProcess.new()
	local all_errors = {}
	-- TODO: convert errors from rpp:process() to our error objects
	local ok, result, errors = rpp:process("entry <- " .. entry_point)
	if not ok then table.insert(errors, ParserErrors.UNIDENTIFIED(result, tostring(result))) end
	for _, err in ipairs(errors) do
		table.insert(all_errors, err)
	end
	if not ok then
		return ok, nil, all_errors
	end
	for _, file in pairs(Grammar.files) do
		local data = Grammar._loaded_files[file]
		if not data then
			data = Utils.readFile(GRAMMAR_DIRECTORY .. "/" .. file)
			Grammar._loaded_files[file] = data
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

---@return true, LPegGrammar, AST
---@overload fun(built_grammar): false, Error
function Grammar.compile(built_grammar)
	local ast_defs = AST.new()
	local ok, regrammar = pcall(ReLabel.compile, built_grammar, ast_defs)
	if not ok then
		return false, ParserErrors.GRAMMAR_SYNTAX(regrammar, tostring(regrammar))
	end
	return ok, regrammar, ast_defs
end


return Grammar
