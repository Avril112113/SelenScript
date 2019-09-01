--TODO: fix erros when folders inside folders, this is due to trying to make a already existent folder

local url = "http://localhost/opencomputers/projects" --url to get files/folders from (make sure listDir.php is in this directory!)
local saveDir = "/root/projects" --save directory for on the OC computer, WARING: this folder will be removed and created each update

local targs = {...}
if not (#targs > 0 and targs[1] == "-nt") then
	os.spawn("/bin/updateNetDir.lua", "-nt")
	return
end

local filesystem = require("filesystem")
local internet = require("internet")
local webData
local data = ""
local files = {}
local folders = {}

local function parseURL(url)
	newUrl = url:gsub("//", "/"):gsub(" ", "%%20"):gsub("http:/", "http://"):gsub("https:/", "https://")
	return newUrl
end

webData = internet.request(parseURL(url.."/listDir.php"))

for chunk in webData do
	data = data..chunk
end

data = data:gsub("<p>", ""):gsub("</p>", ""):gsub("<br>", "\n"):gsub("</br>", "\n")

for v in string.gmatch(data, "([^\n]*)\n?") do
	local prefix = v:sub(0, 3)
	if prefix == "fi:" then
		table.insert(files, v:sub(4, v:len()))
	elseif prefix == "fo:" then
		table.insert(folders, v:sub(4, v:len()))
	end
end

filesystem.remove(saveDir)

for i, v in pairs(folders) do
	local succ, err = filesystem.makeDirectory(saveDir..v)
	if succ == nil then
		--print("Got error while making directory: " .. saveDir..v .. " Err: " .. err .. " Ignoring error and continuing")
	end
end

for i, v in pairs(files) do
	local webData = internet.request(parseURL(url..v))
	local data = ""

	for chunk in webData do
		data = data..chunk
	end

	local f = filesystem.open(saveDir..v, "w")
	f:write(data)
	f:close()
end










