local relabel = require "relabel"
local selenScript = require "selenScript"


local files = {}
local function addFiles(glob)
	local handle = io.popen('python listTests.py "' .. glob .. '"')
	local filesStr = handle:read("*a")
	handle:close()
	local _files = loadstring("return " .. filesStr, "@listTests.py (RESULT)")()
	for i, v in ipairs(_files) do
		table.insert(files, v)
	end
end

addFiles("selenScript/**/*.lua")


local project = selenScript.project.new {
	src_dir="selenScript/",
	out_dir="selenScript_trans/",
	provided_deps_require="tests/test/__sls_provided_deps"
}
for _, path in ipairs(files) do
	print("--- " .. path .. " ---")
	path = path:gsub("^" .. project.src_dir, "")
	local file = selenScript.file.new {
		path=path,
		include_provided_deps=false,

		project=project
	}
	print("-- Src:    " .. file:get_src_path() .. " --")
	print("-- Output: " .. file:get_output_path() .. " --")
	print("-- Diagnostics --")
	local has_error = false
	for _, diag in pairs(file.diagnostics) do
		local errType = diag.type or "nil"
		local sl, sc = relabel.calcline(file.code, diag.start)
		local str = diag.serverity:upper() .. ":" .. errType .. " at " .. tostring(sl) .. ":" .. tostring(sc) .. " " ..  diag.msg
		if diag.fix ~= nil then
			str = str .. "\nfix: '" .. tostring(diag.fix):gsub("\n", "\\n"):gsub("\r", "\\r"):gsub("\t", "\\t") ..  "'"
		end
		print(str)
		if diag.ast ~= nil then
			selenScript.helpers.printAST(diag.ast)
		end
		if diag.serverity:lower() == "error" and errType ~= "vm_error" and errType ~= "undefined_variable" then
			has_error = true
		end
	end
	if has_error then
		print("-= BREAK, has diagnostic with error serverity.")
		break
	end
end
