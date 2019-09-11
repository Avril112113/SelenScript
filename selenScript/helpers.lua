-- contains helpers for testing and debugging

--- Converts a value to a more readable string repersentation based on its type
---@param v any
local function strValueFromType(v)
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

--- Checks if 2 tables are the same
---@param a table
---@param b table
local function tblEqual(a, b)
	for i, v in pairs(a) do
		if type(v) == "table" and type(b[i]) == "table" then
			if tblEqual(v, b[i]) == false then
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
local function tblPrint(a, b, path)
	path = path or "<INPUT>"
	for i, v in pairs(a) do
		if type(v) == "table" and type(b[i]) == "table" then
			tblPrint(v, b[i], path.."."..strValueFromType(i))
		elseif b[i] ~= v then
			print(path.."."..strValueFromType(i).." should be " .. strValueFromType(v) .. " but is " .. strValueFromType(b[i]))
		end
	end
end

local function isEmptyTable(tbl)
	for i, v in ipairs(tbl) do return false end
	return true
end

--- Prints the given AST to stdout
---@param ast table @ Is a Node of the AST
---@param indent string
---@param depth number
---@param fieldName string|nil
local function printAST(ast, indent, depth, fieldName)
	indent = indent or "    "
	depth = depth or 0
	print(string.rep(indent, depth) .. (function()
		if fieldName ~= nil then
			return strValueFromType(fieldName) .. " = "
		end
		return ""
	end)() .. ast.type)
	for i, v in pairs(ast) do
		if type(v) == "table" and type(v.type) == "string" then
			printAST(v, indent, depth+1, i)
		elseif type(v) == "table" then
			local hasPrintedStart = false
			for i1, v1 in ipairs(v) do
				if type(v1) == "table" and type(v1.type) == "string" then
					if not hasPrintedStart then
						print(string.rep(indent, depth+1) .. strValueFromType(i) .. " = " .. "[")
					end
					printAST(v1, indent, depth+2)
					hasPrintedStart = true
				end
			end
			if hasPrintedStart then
				print(string.rep(indent, depth+1) .. "]")
			elseif isEmptyTable(v) then
				print(string.rep(indent, depth+1) .. strValueFromType(i) .. " = " .. strValueFromType(v) .. "(Empty Table)")
			else
				print(string.rep(indent, depth+1) .. strValueFromType(i) .. " = " .. strValueFromType(v))
			end
		elseif i ~= "type" then
			print(string.rep(indent, depth+1) .. strValueFromType(i) .. " = " .. strValueFromType(v))
		end
	end
end

local function _serializeValue(s)
	return string.format("%q", s)
end
local function serializeTable(tbl, indent, depth)
	indent =  "    "
	depth = depth or 0
	local out = "{\n"
	local lastI = 0
	for i, v in ipairs(tbl) do
		out = out .. string.rep(indent, depth+1)
		if type(v) == "table" then
			out = out .. serializeTable(v, indent, depth+1) .. ",\n"
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
				out = out .. serializeTable(v, indent, depth+1) .. ",\n"
			else
				out = out .. _serializeValue(v) .. ",\n"
			end
		end
	end
	return out:gsub(",\n$", "\n") .. string.rep(indent, depth) .. "}"
end

local function reconstructMath(ast)
	if ast.lhs ~= nil and ast.rhs ~= nil then
		return "(" .. reconstructMath(ast.lhs) .. ast.operator .. reconstructMath(ast.rhs) ..")"
	elseif ast.rhs ~= nil then
		return "(" .. ast.operator .. reconstructMath(ast.rhs) ..")"
	elseif ast.lhs ~= nil then
		return "(" .. reconstructMath(ast.lhs) .. ast.operator ..")"
	elseif ast.value ~= nil then
		return ast.value
	elseif ast.type == "index" then
		local n = ast.name
		if ast.index ~= nil then n = n .. reconstructMath(ast.index) end
		return n
	else
		error("failed to handle ast for reconstruct math " .. (ast and ast.type or ""))
	end
end

local function default_value(value, default)
	if value ~= nil then
		return value
	else
		return default
	end
end

return {
	strValueFromType=strValueFromType,
	printAST=printAST,
	tblEqual=tblEqual,
	tblPrint=tblPrint,
	serializeTable=serializeTable,
	reconstructMath=reconstructMath,
	default_value=default_value
}
