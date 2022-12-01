local re = require "drelabel"

local Utils = require "SelenScript.utils"
local Grammar = require "SelenScript.parser.grammar"
local ParserErrors = require "SelenScript.parser.errors"


---@class Parser
---@field ast_defs AST
---@field grammar_src string
---@field grammar LPegGrammar
local Parser = {}
Parser.__index = Parser


---@return Parser?, Error[]
function Parser.new()
	local ok, built_grammar, grammar_build_errors = Grammar.build()
	if not ok then
		return nil, grammar_build_errors
	end
	if next(grammar_build_errors) ~= nil then
		return nil, grammar_build_errors
	end
	local ok, grammar, ast_defs = Grammar.compile(built_grammar)
	if not ok then
		---@cast grammar Error
		return nil, {grammar}
	end
	---@cast grammar LPegGrammar

	local self = setmetatable({
		grammar_src=built_grammar,
		grammar=grammar,
		ast_defs=ast_defs,
	}, Parser)
	return self, {}
end

--- Removes all keys beginning with `_` from the node and child nodes, these are used for in-grammar use and should not be in the resulting AST
---@param node ASTNode
function Parser.cleanup_nodes(node)
	for i, v in pairs(node) do
		if type(i) == "string" and i:sub(1, 1) == "_" then
			node[i] = nil
		end
		if type(v) == "table" and v.type ~= nil then
			Parser.cleanup_nodes(v)
		end
	end
end

---@param source string
function Parser:parse(source)
	self.ast_defs:init(source)
	---@type ASTNode, any?, integer?
	local ast, err, pos = self.grammar:match(source)
	if type(ast) == "table" then
		Parser.cleanup_nodes(ast)
	end
	if err ~= nil then
		table.insert(self.ast_defs.errors, ParserErrors.SYNTAX_UNIDENTIFIED({pos=pos,err=err,ast=ast}, re.calcline(source, pos), err))
	end
	return ast, self.ast_defs.errors, self.ast_defs.comments
end


return Parser
