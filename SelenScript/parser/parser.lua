local re = require "drelabel"
local AVCalcLine = require "avcalcline"

local Utils = require "SelenScript.utils"
local Grammar = require "SelenScript.parser.grammar"
local ParserErrors = require "SelenScript.parser.errors"


--- Unique custom ASTNode type that encompasses the ast of a source, it's start and end are inherited from it's block node.
---@class ASTNodeSource : ASTNode
---@field type "source"
---@field block ASTNode # TODO: Node types
---@field source string # The plain text source
---@field file string? # Defines the origin of the source, special value `[stdin]`, path be relitive to src root and use `/`
---@field _avcalcline AVCalcLine?
---@field calcline fun(self,pos:integer):integer,integer
local ASTNodeSource


---@class Parser
---@field ast_defs AST
---@field grammar_src string
---@field grammar LPegGrammar
local Parser = {}
Parser.__index = Parser


---@param opts {selenscript:boolean}?
---@return Parser?, Error[]
function Parser.new(opts)
	local garmmar_declarations = {}
	garmmar_declarations.Grammar_SelenScript = not opts or not not opts.selenscript
	local ok, built_grammar, grammar_build_errors = Grammar.build(garmmar_declarations)
	if not ok then
		return nil, grammar_build_errors
	end
	if next(grammar_build_errors) ~= nil then
		return nil, grammar_build_errors
	end
	local ok, grammar, ast_defs = Grammar.compile(built_grammar)
	if not ok then
		---@cast grammar -LPegGrammar
		return nil, {grammar}
	end
	---@cast grammar -Error

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
---@param file string?
function Parser:parse(source, file)
	self.ast_defs:init(source)
	---@type ASTNode, any?, integer?
	local ast, err, pos = self.grammar:match(source)
	if type(ast) == "table" then
		Parser.cleanup_nodes(ast)
	end
	if err ~= nil then
		table.insert(self.ast_defs.errors, ParserErrors.SYNTAX_UNIDENTIFIED({pos=pos,err=err,ast=ast}, re.calcline(source, pos), err))
	end
	---@type ASTNodeSource
	local ast_source = {
		type = "source",
		start = ast.start,
		finish = ast.finish,
		source = source,
		block = ast,
		file = file,
		calcline = function(self, pos)
			if self._avcalcline == nil then
				self._avcalcline = AVCalcLine.new(self.source)
			end
			return self._avcalcline:calcline(pos)
		end
	}
	return ast_source, self.ast_defs.errors, self.ast_defs.comments
end


return Parser
