local __file_path__ = debug.getinfo(1).source:match("@(.*)$"):gsub("\\", "/"):gsub("/bin/selenscript.lua$", "")

local verstr = _VERSION:sub(5)

package.path = ("{}/?.lua;{}/?/init.lua;{}/libs/?.lua;{}/libs/?/init.lua;{}/libs/?/?.lua;"):gsub("{}", __file_path__) .. package.path
package.cpath = ("{}/libs/" .. verstr .. "/?.dll;{}/libs/?.dll;"):gsub("{}", __file_path__) .. package.cpath


local ss = require "selenScript"


local commands = {}
commands.help = {
	name="help",
	desc="Get information on a command.",
	usage="help [command name]",
	args={
		{type="string", str="help"},
		{
			type="optional",
			{type="string"}
		}
	},
	run=function(args)
		local commandName = args[2] and args[2].str or nil
		if commandName ~= nil then
			for _, cmd in pairs(commands) do
				if cmd.name == commandName then
					print("- " .. cmd.name .. " -")
					print("Usage: " .. cmd.usage)
					print(cmd.desc)
					return
				end
			end
			print("Failed to find that command, check the spellings.")
		else
			print("List of commands")
			for _, cmd in pairs(commands) do
				if cmd.helpHidden ~= true then
					print(cmd.name .. " - " .. cmd.usage)
				end
			end
		end
	end
}
commands.transpile = {
	name="transpile",
	desc="Transpile a specific file.",
	usage="transpiler|trans <input file> [output file]",
	args={
		{
			type="or",
			{type="string", str="transpile"},
			{type="string", str="trans"}
		},
		{type="string"},
		{
			type="optional",
			{type="string"}
		}
	},
	run=function(args)
		local inputPath = args[2].str
		local outputPath = args[3] and args[3].str or inputPath:gsub("%.sl$", "") .. ".lua"

		local program = ss.program.new({
			defaultLocals=false,
			indent="\t",
			targetVersion="jit"
		})
		local file = ss.file.new(inputPath)
		program:addFile(file)
		file.outputPath = outputPath
		local ok, transformer, transpiler, transformedAst, luaCode = file:transpile()
		
	end
}

----------------------------------------------------------------------------

local function validateCmdField(cmdIndex, cmd, fieldName, fieldType)
	local cmdName = cmd.name or cmdIndex
	assert(type(cmd[fieldName]) == fieldType, "Command '" .. cmdName .. "', field '" .. fieldName .. "', expected type '" .. fieldType .. "' got '" .. type(cmd[fieldName]) .. "'")
end
for i, cmd in pairs(commands) do
	validateCmdField(i, cmd, "name", "string")
	validateCmdField(i, cmd, "desc", "string")
	validateCmdField(i, cmd, "usage", "string")
	validateCmdField(i, cmd, "args", "table")
	assert(#cmd.args > 0, "Command '" .. cmd.name .. "', field 'args', table has no content, this will cause it to always pass command checks.")
	validateCmdField(i, cmd, "run", "function")
end

----------------------------------------------------------------------------

local function cmdArgsMatch(cmdArgs, args, depth)
	depth = depth or 1
	local argType = cmdArgs.type or "and"
	if argType == "and" then
		local argsMatched = 0
		for _, andCmdArg in ipairs(cmdArgs) do
			assert(type(andCmdArg) == "table", "Command args type 'and' got non table in sequence.")
			local cMatch, cDepth = cmdArgsMatch(andCmdArg, args, depth + argsMatched)
			argsMatched = argsMatched + (cDepth - depth)
			if not cMatch then
				return false, depth + argsMatched
			end
		end
		return true, depth + argsMatched
	elseif argType == "or" then
		for _, orCmdArg in ipairs(cmdArgs) do
			assert(type(orCmdArg) == "table", "Command args type 'or' got non table in sequence.")
			local cMatch, cDepth = cmdArgsMatch(orCmdArg, args, depth)
			if cMatch then
				return true, cDepth
			end
		end
	elseif argType == "optional" then
		local argsMatched = 0
		for _, andCmdArg in ipairs(cmdArgs) do
			assert(type(andCmdArg) == "table", "Command args type 'optional' got non table in sequence.")
			local cMatch, cDepth = cmdArgsMatch(andCmdArg, args, depth + argsMatched)
			argsMatched = argsMatched + (cDepth - depth)
		end
		return true, depth + argsMatched
	else
		local arg = args[depth]
		if arg == nil then
			return false, depth
		end

		for i, v in pairs(cmdArgs) do
			if arg[i] ~= v then
				return false, depth
			end
		end
		return true, depth + 1
	end
	return false, depth
end
local function findCmd(args)
	local closestMatch
	local closestMatchAmount = -1
	local foundCmd
	for _, cmd in pairs(commands) do
		local isMatch, matchAmount = cmdArgsMatch(cmd.args, args)
		if isMatch then
			foundCmd = cmd
			break
		elseif closestMatchAmount < matchAmount then
			closestMatch = cmd
			closestMatchAmount = matchAmount
		end
	end
	return foundCmd, closestMatchAmount > 1 and closestMatch or nil
end


local args = {}
for i, v in ipairs({...}) do
	if tonumber(v) ~= nil then
		table.insert(args, {
			type="number",
			str=tonumber(v)
		})
	else
		table.insert(args, {
			type="string",
			str=v
		})
	end
end

local cmd, closestCmd = findCmd(args)
if cmd == nil then
	if closestCmd ~= nil then
		print("Invalid usage, " .. closestCmd.name .. " correct usage: " .. closestCmd.usage)
	else
		print("Invalid usage.")
		commands.help.run({})
	end
else
	cmd.run(args)
end
