-- contains helpers for testing, debugging or use in other areas of selenscript
local helpers = {}


function helpers.deepCopy(tbl)
	local new = {}
	for i, v in pairs(tbl) do
		if type(v) == "table" and i ~= "parent" then
			v = helpers.deepCopy(v)
		end
		new[i] = v
	end
	return new
end


--- Converts a value to a more readable string repersentation based on its type
---@param v any
function helpers.strValue(v)
	if type(v) == "string" then
		v = v:gsub("\r", "\\r"):gsub("\n", "\\n"):gsub("\t", "\\t")
		local _, singlePos = string.find(v, "'")
		if singlePos == nil or singlePos <= 0 then
			return "'" .. v .. "'"
		end
		return "\"" .. v .. "\""
	end
	return tostring(v)
end

--- Checks if 2 tables are the same recursively
---@param a table
---@param b table
function helpers.tblEqual(a, b)
	for i, v in pairs(a) do
		if type(v) == "table" and type(b[i]) == "table" then
			if helpers.tblEqual(v, b[i]) == false then
				return false
			end
		elseif b[i] ~= v then
			return false
		end
	end
	return true
end

--- Prints the difference's between 2 tables
---@param a table
---@param b table
function helpers.tblPrint(a, b, path)
	path = path or "<INPUT>"
	for i, v in pairs(a) do
		if type(v) == "table" and type(b[i]) == "table" then
			helpers.tblPrint(v, b[i], path.."."..helpers.strValue(i))
		elseif b[i] ~= v then
			print(path.."."..helpers.strValue(i).." should be " .. helpers.strValue(v) .. " but is " .. helpers.strValue(b[i]))
		end
	end
end

--- Checks if the given table is empty (ipairs)
---@param tbl table
function helpers.isEmptyTable(tbl)
	for i, v in ipairs(tbl) do return false end
	return true
end

---@param symbols table
---@param indent string
---@param depth number
function helpers.printSymbols(symbols, indent, depth)
	local prefix = ""
	if indent ~= nil and depth ~= nil then
		prefix = string.rep(indent, depth)
	end
	for _, symbol in pairs(symbols) do
		print(prefix .. tostring(symbol.name) .. " Declarations: " .. tostring(#symbol.declarations) .. " References: " .. tostring(#symbol.references) .. " Value: ")
		helpers.printAST(symbol.value, indent, depth+1, nil, symbol.value.type == "table")
	end
end

--- Prints the given AST to stdout
---@param ast table @ Is a Node of the AST
---@param indent string
---@param depth number
---@param fieldName string|nil
function helpers.printAST(ast, indent, depth, fieldName, symbolValue)
	indent = indent or "    "
	depth = depth or 0
	local str = string.rep(indent, depth)
	if fieldName ~= nil then
		str = str .. helpers.strValue(fieldName) .. " = "
	end
	str = str .. ast.type
	if ast.start ~= nil then
		str = str .. " (" .. tostring(ast.start)
		if ast.finish ~= nil then
			str = str .. ":" .. tostring(ast.finish)
		end
		str = str .. ")"
	end
	print(str)
	for i, v in pairs(ast) do
		if type(v) == "table" and type(v.type) == "string" and i ~= "parent" then
			if symbolValue == true then
				if ast.type == "table" and v.type == "field_list" then
					-- Do nothing
				else
					helpers.printAST(v, indent, depth+1, i, symbolValue)
				end
			else
				helpers.printAST(v, indent, depth+1, i)
			end
		elseif i == "locals" or i == "symbols" then
			print(string.rep(indent, depth+1) .. helpers.strValue(i) .. " ->")
			helpers.printSymbols(v, indent, depth+2)
		elseif type(v) == "table" and i ~= "parent" then
			local hasPrintedStart = false
			for i1, v1 in ipairs(v) do
				if type(v1) == "table" and type(v1.type) == "string" then
					if not hasPrintedStart then
						print(string.rep(indent, depth+1) .. helpers.strValue(i) .. " = " .. "[")
					end
					helpers.printAST(v1, indent, depth+2)
					hasPrintedStart = true
				end
			end
			if hasPrintedStart then
				print(string.rep(indent, depth+1) .. "]")
			elseif helpers.isEmptyTable(v) then
				print(string.rep(indent, depth+1) .. helpers.strValue(i) .. " = " .. helpers.strValue(v) .. "(Empty Table)")
			else
				print(string.rep(indent, depth+1) .. helpers.strValue(i) .. " = " .. helpers.strValue(v))
			end
		elseif i ~= "type" and i ~= "parent" and i ~= "filepath" and i ~= "start" and i ~= "finish" then
			print(string.rep(indent, depth+1) .. helpers.strValue(i) .. " = " .. helpers.strValue(v))
		end
	end
end

local function _serializeValue(s)
	return string.format("%q", s)
end
function helpers.serializeTable(tbl, indent, depth)
	indent =  "    "
	depth = depth or 0
	local out = "{\n"
	local lastI = 0
	for i, v in ipairs(tbl) do
		out = out .. string.rep(indent, depth+1)
		if type(v) == "table" then
			out = out .. helpers.serializeTable(v, indent, depth+1) .. ",\n"
		else
			out = out .. _serializeValue(v) .. ",\n"
		end
		lastI = i
	end
	for i, v in pairs(tbl) do
		if type(i) == "number" and i > lastI or type(i) ~= "number" then
			out = out .. string.rep(indent, depth+1)
			if type(i) == "string" then
				out = out .. i .. " = "
			else
				out = out .. "[" .. _serializeValue(i) .. "]" .. " = "
			end
			if type(v) == "table" then
				out = out .. helpers.serializeTable(v, indent, depth+1) .. ",\n"
			else
				out = out .. _serializeValue(v) .. ",\n"
			end
		end
	end
	return out:gsub(",\n$", "\n") .. string.rep(indent, depth) .. "}"
end

function helpers.reconstructMath(ast)
	if ast.lhs ~= nil and ast.rhs ~= nil then
		return "(" .. helpers.reconstructMath(ast.lhs) .. ast.operator .. helpers.reconstructMath(ast.rhs) ..")"
	elseif ast.rhs ~= nil then
		return "(" .. ast.operator .. helpers.reconstructMath(ast.rhs) ..")"
	elseif ast.lhs ~= nil then
		return "(" .. helpers.reconstructMath(ast.lhs) .. ast.operator ..")"
	elseif ast.value ~= nil then
		return ast.value
	elseif ast.type == "index" then
		local n = ast.name
		if ast.index ~= nil then n = n .. helpers.reconstructMath(ast.index) end
		return n
	else
		error("failed to handle ast for reconstruct math " .. (ast and ast.type or ""))
	end
end

function helpers.default_value(value, default)
	if value ~= nil then
		return value
	else
		return default
	end
end

function helpers.cleanupPath(path)
	return path:gsub("\\", "/"):gsub("//", "/"):gsub("/$", "")
end


return helpers
