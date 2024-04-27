local modpath = ...
local modfolderpath = package.searchpath(modpath, package.path):gsub("[\\/][^\\/]*$", "")
local GRAMMAR_PATH = modfolderpath .. "/grammar.relabel"


local relabel = require "drelabel"
local lpeg = require "lpeglabel"


local function read_file(path)
	local f = assert(io.open(path, "r"))
	local data = f:read("*a")
	f:close()
	return data
end

---@generic T : table
---@param t T
---@return T
local function deepcopy(t)
	local new = {}
	for i, v in pairs(t) do
		if type(v) == "table" then
			new = deepcopy(v)
		else
			new[i] = v
		end
	end
	return new
end


local RePreProcess = {}
RePreProcess.__index = RePreProcess

local defs_tmp_rpp
local errors = {}
local grammar, defs
defs = {
	esc_t = "\t",
	nl = lpeg.P'\r\n' + lpeg.S'\r\n',
	dbg = function(...)
		print("dbg:", ...)
	end,

	UNPARSED_INPUT = function(pos, str, name)
		table.insert(errors, {
			type = "UNPARSED_INPUT",
			pos = pos,
			msg = ("Unparsed input in '" .. tostring(name) .. "'\n" .. str:gsub("\n", "\\n"):gsub("\r", "\\r")),
		})
	end,
	MISSING_ENDBLOCK = function(pos)
		table.insert(errors, {
			type = "MISSING_ENDBLOCK",
			pos = pos,
			msg = "Missing #endblock",
		})
	end,
	MISSING_ENDIF = function(pos)
		table.insert(errors, {
			type = "MISSING_ENDIF",
			pos = pos,
			msg = "Missing #endif",
		})
	end,

	chunk = function(...)
		return {
			type = "chunk",
			...
		}
	end,

	["if"] = function(name, condition, chunk, fail)
		return {
			type = "if",
			name = name,
			condition = condition,
			chunk = chunk,
			fail = fail,
		}
	end,
	["elseif"] = function(name, condition, chunk, fail)
		return {
			type = "elseif",
			name = name,
			condition = condition,
			chunk = chunk,
			fail = fail,
		}
	end,
	["else"] = function(chunk)
		return {
			type = "else",
			chunk = chunk,
		}
	end,
	block = function(name, chunk)
		return {
			type = "block",
			name = name,
			chunk = chunk,
		}
	end,
	include = function(pos, name)
		assert(defs_tmp_rpp ~= nil)
		if defs_tmp_rpp.read_file then
			local ext = name:match("%.[^.]+$")
			if defs_tmp_rpp.read_exts[ext] then
				local src = defs_tmp_rpp.read_file(name)
				if src then
					local result, err, errPos = grammar:match(src)
					if result == nil then
						table.insert(errors, {
							type = "MISSING_FILE",
							pos = pos,
							msg = "Internal error: Failed to parse grammar at " .. tostring(errPos) .. " : " .. err,
						})
					else
						return result
					end
				else
					table.insert(errors, {
						type = "MISSING_FILE",
						pos = pos,
						msg = ("File not found \"%s\""):format(name),
					})
				end
			end
		end
		return {
			type = "include",
			name = name,
		}
	end,
	define = function(name, value)
		return {
			type = "define",
			name = name,
			value = value,
		}
	end,
	unknown_directive = function(name, args)
		return {
			type = "unknown_directive",
			name = name,
			args = args,
		}
	end,

	string = function(node)
		return node.value
	end,

	comment = function(comment)
		return {
			type = "comment",
			comment = comment,
		}
	end,

	source = function(source)
		if type(source) == "number" then
			source = ""
		end
		return {
			type = "source",
			source = source,
		}
	end,
}
RePreProcess.defs = defs

local Emitter = {}
Emitter.__index = Emitter
RePreProcess.Emitter = Emitter

---@param declarations table?
function Emitter.new(declarations)
	return setmetatable({
		declarations = declarations or {},
		parts_index = 1,
		parts = {},
		blocks = {},
		errors = {},
	}, Emitter)
end

--- Once ran, Emitter should be disposed
function Emitter:generate()
	local i = 1
	while #self.parts >= i do
		---@type string|table<string,any>
		local part = self.parts[i]
		if type(part) == "table" and part.type == "include" then
			self.parts_index = i
			self.parts[i] = nil
			local block = self.blocks[part.name]
			if block ~= nil then
				self:visit(block.chunk)
				-- If the block is empty, it may have never set the part to something.
				if self.parts[i] == nil then
					self.parts[i] = ""
				end
			else
				self.parts[i] = ""
				table.insert(self.errors,  {
					msg="Missing block '" .. part.name .. "'",
					type="MISSING_BLOCK",
					name=part.name,
				})
			end
		end
		i = i + 1
	end
	return table.concat(self.parts)
end

---@param part string|table
function Emitter:addPart(part)
	if self.parts[self.parts_index] == nil then
		self.parts[self.parts_index] = part
	else
		table.insert(self.parts, self.parts_index, part)
	end
	self.parts_index = self.parts_index + 1
end

function Emitter:visit(node)
	local f = self[node.type]
	if f == nil then
		table.insert(self.errors, {
			msg="Error: Missing visit func for '" .. tostring(node.type) .. "' (" .. tostring(node) .. ")",
			type="MISSING_VISIT_FUNC",
			name=tostring(node.type),
		})
	else
		f(self, node)
	end
end

function Emitter:chunk(chunk)
	assert(chunk.type == "chunk")
	for _, node in ipairs(chunk) do
		self:visit(node)
	end
end
function Emitter:comment(comment)
	assert(comment.type == "comment")
end
function Emitter:source(source)
	assert(source.type == "source")
	self:addPart(source.source .. "\n")
end
function Emitter:block(block)
	assert(block.type == "block")
	local existingBlock = self.blocks[block.name]
	if existingBlock ~= nil then
		for i, node in pairs(block.chunk) do
			if type(node) == "table" and node.type == "include" then
				if node.name == block.name then
					block.chunk[i] = existingBlock.chunk
				end
			end
		end
	end
	self.blocks[block.name] = block
end
function Emitter:include(include)
	assert(include.type == "include")
	self:addPart(include)
end
function Emitter:define(define)
	assert(define.type == "define")
	self.declarations[define.name] = define.value == "true"
end
Emitter["if"] = function(self, ast)
	assert(ast.type == "if" or ast.type == "elseif")
	if ast.condition == "block" and self.blocks[ast.name] then
		self:visit(ast.chunk)
	elseif (ast.condition == "true" and self.declarations[ast.name]) or (ast.condition == "false" and not self.declarations[ast.name]) then
		self:visit(ast.chunk)
	elseif ast.fail ~= nil then
		self:visit(ast.fail)
	end
end
Emitter["elseif"] = Emitter["if"]

local grammar_src = read_file(GRAMMAR_PATH)
grammar = relabel.compile(grammar_src, defs)
RePreProcess.grammar = grammar

---@param read_file (fun(file:string):string?)?
---@param read_exts table<string,true>?
function RePreProcess.new(read_file, read_exts)
	return setmetatable({
		chunks = {},
		read_file = read_file,
		read_exts = read_exts or {[".relabel"]=true},
	}, RePreProcess)
end

---@param src string
---@return boolean ok, table|string result, table errors
function RePreProcess:process(src)
	errors = {}
	defs_tmp_rpp = self
	local result, err, errPos = grammar:match(src)
	defs_tmp_rpp = nil
	if result == nil then
		return false, "Internal error: Failed to parse grammar at " .. tostring(errPos) .. " : " .. err, errors
	end
	if result.type ~= "chunk" then
		return false, "Internal error: AST root node is not a 'chunk'", errors
	end
	table.insert(self.chunks, result)
	return true, result, errors
end

---@param declarations table<string,boolean>?
---@return boolean, string, table[], table<string,boolean>
function RePreProcess:generate(declarations)
	local declarations_copy = declarations and deepcopy(declarations) or {}
	local emitter = Emitter.new(declarations_copy)
	for _, chunk in ipairs(self.chunks) do
		emitter:visit(chunk)
	end
	return true, emitter:generate(), emitter.errors, declarations_copy
end


return RePreProcess
