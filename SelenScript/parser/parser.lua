local re = require "drelabel"
local AVCalcLine = require "avcalcline"

local Utils = require "SelenScript.utils"
local Grammar = require "SelenScript.parser.grammar"
local ParserErrors = require "SelenScript.parser.errors"


--- Unique custom ASTNode type that encompasses the ast of a source, it's start and end are inherited from it's block node.
---@class SelenScript.ASTNodes.Source : SelenScript.ASTNodes.Node
---@field type "source"
---@field block SelenScript.ASTNodes.chunk
---@field src string # The plain text source
---@field file string? # Defines the origin of the source, special value `[stdin]`, path be relitive to src root and use `/`
---@field _avcalcline AVCalcLine?
---@field calcline fun(self,pos:integer):integer,integer
local ASTNodeSource


---@class SelenScript.Parser
---@field ast_defs SelenScript.AST
---@field grammar_src string
---@field grammar SelenScript.LPegGrammar
local Parser = {}
Parser.__index = Parser

---@param self SelenScript.ASTNodes.Source
---@param pos integer
---@return integer, integer
function Parser._source_calcline(self, pos)
	if self._avcalcline == nil then
		self._avcalcline = AVCalcLine.new(self.src)
	end
	return self._avcalcline:calcline(pos)
end


---@param opts {selenscript:boolean}?
---@return SelenScript.Parser?, SelenScript.Error[]
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
		---@cast grammar -SelenScript.LPegGrammar
		return nil, {grammar}
	end
	---@cast grammar -SelenScript.Error

	local self = setmetatable({
		grammar_src=built_grammar,
		grammar=grammar,
		ast_defs=ast_defs,
	}, Parser)
	return self, {}
end

--- Removes all keys beginning with `_` from the node and child nodes, these are used for in-grammar use and should not be in the resulting AST
---@param node SelenScript.ASTNodes.Node
---@param source SelenScript.ASTNodes.Source
function Parser.postprocess_nodes(node, source)
	for i, v in pairs(node) do
		if type(i) == "string" and i:sub(1, 1) == "_" then
			node[i] = nil
		end
		if type(v) == "table" and v.type ~= nil then
			Parser.postprocess_nodes(v, source)
		end
	end
	node.source = source
end

---@param source string
---@param file string?
function Parser:parse(source, file)
	self.ast_defs:init(source)
	---@type SelenScript.ASTNodes.chunk, any?, integer?
	local ast, err, pos = self.grammar:match(source)
	---@type SelenScript.ASTNodes.Source
	local ast_source = {
		type = "source",
		start = ast.start,
		finish = ast.finish,
		src = source,
		block = ast,
		file = file,
		calcline = Parser._source_calcline,
		---@diagnostic disable-next-line: assign-type-mismatch
		source = nil
	}
	if type(ast) == "table" then
		Parser.postprocess_nodes(ast, ast_source)
	end
	if err ~= nil then
		table.insert(self.ast_defs.errors, ParserErrors.SYNTAX_UNIDENTIFIED({pos=pos,err=err,ast=ast}, re.calcline(source, pos), err))
	end
	if ast.type ~= "chunk" then
		error(("INVALID GRAMMAR: returned node of type '%s' but expected 'chunk'"):format(ast.type))
	end
	return ast_source, self.ast_defs.errors, self.ast_defs.comments
end


-- AMF3 compatibility

---@diagnostic disable-next-line: inject-field
AVCalcLine.__toAMF3 = function()
	return nil
end

debug.setmetatable(function()end, {
	__toAMF3 = function(f)
		if f == Parser._source_calcline then
			return nil
		else
			error("Can not serialise functions using AMF3")
		end
	end,
})

---@param t table
function Parser.amf3_handler(t)
	if t.type == "source" then
		t.calcline = Parser._source_calcline
	end
	return t
end


return Parser
