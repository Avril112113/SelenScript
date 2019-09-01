local targetURL = "http://localhost/opencomputers/eepromNetRun.lua"

local component = require("component")
local internet = require("internet")
local shell = require("shell")
local text = require("text")
local eeprom = component.eeprom

if not component.isAvailable("internet") then
  io.stderr:write("This program requires an internet card to run.")
  return
end

local eepromDataToSet = ""

local url = text.trim(targetURL)
local result, response = pcall(internet.request, url)
if result then
	local result, reason = pcall(function()
		for chunk in response do
			eepromDataToSet = eepromDataToSet..chunk
		end
	end)
	if not result then
		io.stderr:write("HTTP request failed: " .. reason .. "\n")
	end
else
	io.stderr:write("HTTP request failed: " .. response .. "\n")
end

eeprom.set(eepromDataToSet)
