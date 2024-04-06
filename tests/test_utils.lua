require "logging"


local lfs = require "lfs"

local Parser = require "SelenScript.parser.parser"
local AST = require "SelenScript.parser.ast"
local Emitter = require "SelenScript.emitter.emitter"
local Transformer = require "SelenScript.transformer.transformer"


local TestUtils = {}


---@param path string
---@return string
function TestUtils.ReadFile(path)
	local f = assert(io.open(path, "r"))
	local data = f:read("*a")
	f:close()
	return data
end

---@param base_path string
---@param f fun(full_path:string, local_path:string)
---@param base_local_path string?
function TestUtils.RunForEachLuaFile(base_path, f, base_local_path)
	for path in lfs.dir(base_path) do
		local full_path = base_path .. "/" .. path
		local local_path = (base_local_path and base_local_path .. "/" or "") .. path
		local attribs = lfs.attributes(full_path)
		if path:sub(1, 1) ~= "." and attribs ~= nil then
			if attribs.mode == "file" and full_path:sub(-4, -1) == ".lua" then
				f(full_path, local_path)
			elseif attribs.mode == "directory" then
				TestUtils.RunForEachLuaFile(full_path, f, local_path)
			end
		end
	end
end

---@param TEST TestEnv
---@return Parser
function TestUtils.CreateParser(TEST)
	local parser, errors = Parser.new()
	if #errors > 0 then
		print_error("-- Grammar Errors: " .. #errors .. " --")
		for _, v in ipairs(errors) do
			print_error((v.id or "NO_ID") .. ": " .. v.msg)
		end
	end
	TEST.assert("parser ~= nil", parser ~= nil)  ---@cast parser -?
	TEST.assert("#errors <= 0", #errors <= 0)
	return parser
end

---@param ast ASTNodeSource
---@param errors Error[]
---@param comments ASTNode[]
function TestUtils.PrintParseResult(ast, errors, comments)
	print("-- Parsed AST: --")
	print(AST.tostring_ast(ast))
	if #errors > 0 then
		print("-- Parse Errors: " .. #errors .. " --")
		for _, v in ipairs(errors) do
			print(v.id .. ": " .. v.msg)
		end
	end
	if #comments > 0 then
		print("-- Comments: " .. #comments .. " --")
		for _, v in ipairs(comments) do
			print(AST.tostring_ast(v))
		end
	end
end


return TestUtils
