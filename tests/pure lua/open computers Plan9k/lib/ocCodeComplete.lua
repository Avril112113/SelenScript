local io = require("io")
local component = require("component")
local gpu = component.gpu


ocCodeComplete = {}


ocCodeComplete.luaKeywords = {
    -- True required so they dont get GC
    ["and"] = true,
    ["break"] = true,
    ["do"] = true,
    ["else"] = true,
    ["elseif"] = true,
    ["end"] = true,
    ["false"] = true,
    ["for"] = true,
    ["function"] = true,
    ["if"] = true,
    ["in"] = true,
    ["local"] = true,
    ["nil"] = true,
    ["not"] = true,
    ["or"] = true,
    ["repeat"] = true,
    ["return"] = true,
    ["then"] = true,
    ["true"] = true,
    ["until"] = true,
    ["while"] = true,
    ["require"] = true,
}


local function shallowcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in pairs(orig) do
            copy[orig_key] = orig_value
        end
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end


local tEmpty = {}
ocCodeComplete.complete = function(sSearchText, tSearchTable, linePrefix, addLuaKeywordsToComplete)
    addLuaKeywordsToComplete = addLuaKeywordsToComplete or true
    linePrefix = linePrefix or ""

    if addLuaKeywordsToComplete then
        for i,v in pairs(ocCodeComplete.luaKeywords) do
            tSearchTable[i] = v
        end
    end

    if ocCodeComplete.luaKeywords[sSearchText] and not addLuaKeywordsToComplete then return tEmpty end
    local nStart = 1
    local nDot = string.find(sSearchText, ".", nStart, true)
    local tTable = tSearchTable or _ENV
    while nDot do
        local sPart = string.sub(sSearchText, nStart, nDot - 1)
        local value = tTable[ sPart ]
        if type(value) == "table" then
            tTable = value
            nStart = nDot + 1
            nDot = string.find(sSearchText, ".", nStart, true)
        else
            return tEmpty
        end
    end
    local nColon = string.find(sSearchText, ":", nStart, true)
    if nColon then
        local sPart = string.sub(sSearchText, nStart, nColon - 1)
        local value = tTable[ sPart ]
        if type(value) == "table" then
            tTable = value
            nStart = nColon + 1
        else
            return tEmpty
        end
    end

    local sPart = string.sub(sSearchText, nStart)
    local nPartLength = string.len(sPart)

    local tResults = {}
    local tSeen = {}
    while tTable do
        for k,v in pairs(tTable) do
            if not tSeen[k] and type(k) == "string" then
                if string.find(k, sPart, 1, true) == 1 then
                    if not (ocCodeComplete.luaKeywords[k] and not addLuaKeywordsToComplete) and string.match(k, "^[%a_][%a%d_]*$") then
                        local sResult = string.sub(k, nPartLength + 1)
                        sResult = linePrefix .. sResult
                        if nColon then
                            if type(v) == "function" then
                                table.insert(tResults, sResult .. "(")
                            elseif type(v) == "table" then
                                local tMetatable = getmetatable(v)
                                if tMetatable and (type(tMetatable.__call) == "function" or  type(tMetatable.__call) == "table") then
                                    table.insert(tResults, sResult .. "(")
                                end
                            end
                        else
                            if type(v) == "function" then
                                sResult = sResult .. "("
                            elseif type(v) == "table" and next(v) ~= nil then
                                sResult = sResult .. "."
                            end
                            table.insert(tResults, sResult)
                        end
                    end
                end
            end
            tSeen[k] = true
        end
        local tMetatable = getmetatable(tTable)
        if tMetatable and type(tMetatable.__index) == "table" then
            tTable = tMetatable.__index
        else
            tTable = nil
        end
    end

    table.sort(tResults)
    return tResults
end

ocCodeComplete.completeLine = function(sLine, tSearchTable, addLuaKeywordsToComplete, returnWholeLine)
    local nStartPos = string.find(sLine, "[a-zA-Z0-9_%.:]+$")
    if nStartPos then
        sLine = string.sub(sLine, nStartPos)
    end
    if #sLine > 0 then
        return ocCodeComplete.complete(sLine, tSearchTable, addLuaKeywordsToComplete, returnWholeLine)
    end
end

ocCodeComplete.betterHintRead = function(history, dobreak, hint)
    history = history or {}
    local x, y = 1, 1

    local refreshHint = false
    local basePart = ""

    local function getLine()
        if not history[y] then
            history[y] = ""
        end
        return history[y]
    end

    local function setLine(text)
        y = 1
        history[y] = text
    end

    local function insert(str)
        local pre = unicode.sub(getLine(), 1, x - 1)
        local after = unicode.sub(getLine(), x)
        setLine(pre .. str .. after)
        x = x + unicode.len(str)
        io.write("\x1b[K"..str..after.."\x1b["..unicode.len(after).."D")
    end

    local function doVisualCompletion()
        local line = getLine()

        local completionList = hint(line, x) or {}

        if completionList ~= nil and #completionList > 0 then
            local completion = completionList[1]
            local oldColorArgA, oldColorArgB = gpu.getBackground()
            os.sleep(0) -- Setting/Getting Colors are strange, i think they need a moment to process in the os loop
            gpu.setBackground(0x4C4C4C)
            os.sleep(0)
            io.write(completion .. string.rep("\x1b[D", #completion))
            os.sleep(0)
            gpu.setBackground(oldColorArgA, oldColorArgB)
            os.sleep(0)
        end
    end

    while true do
        local char = io.read(1)
        if not char then
            --WTF?
        elseif char == "\n" then
            io.write("\n")
            local line = getLine()
            if y == 1 and line ~= "" and line ~= history[2] then
                table.insert(history, 1, "")
            elseif y > 1 and line ~= "" and line ~= history[2] then
                history[1] = line
                table.insert(history, 1, "")
            else
                history[1] = ""
            end
            return line
        elseif char == "\t" and hint then
            local line = getLine()
            local completionList = hint(line, x) or {}

            if completionList ~= nil and #completionList > 0 then
                insert(completionList[1])
            end
        elseif char == "\b" and x > 1 then
            local pre = unicode.sub(getLine(), 1, x - 2)
            local after = unicode.sub(getLine(), x)
            setLine(pre .. after)
            x = x - 1
            io.write("\x1b[D\x1b[K" .. after .. "\x1b[" .. unicode.len(after) .. "D")
        elseif char == "\x1b" then
            local mode = io.read(1)
            if mode == "[" then
                local act = io.read(1)
                if act == "C" then
                    if unicode.len(getLine()) >= x then
                        io.write("\x1b[C")
                        x = x + 1
                    end
                elseif act == "D" then
                    if x > 1 then
                        io.write("\x1b[D")
                        x = x - 1
                    end
                elseif act == "A" then
                    if y < #history then
                        y = y + 1
                        local line = getLine()
                        io.write("\x1b[" .. (x - 1)  .. "D\x1b[K" .. line)
                        x = unicode.len(line) + 1
                    end
                elseif act == "B" then
                    if y > 1 then
                        y = y - 1
                        local line = getLine()
                        io.write("\x1b[" .. (x - 1) .. "D\x1b[K" .. line)
                        x = unicode.len(line) + 1
                    end
                elseif act == "3" and io.read(1) == "~" then
                    local pre = unicode.sub(getLine(), 1, x - 1)
                    local after = unicode.sub(getLine(), x + 1)
                    setLine(pre .. after)
                    io.write("\x1b[K" .. after .. "\x1b[" .. unicode.len(after) .. "D")
                end
            elseif mode == "O" then
                local act = io.read(1)
                if act == "H" then
                    io.write("\x1b["..(x - 1).."D")
                    x = 1
                elseif act == "F" then
                    local line = getLine()
                    io.write("\x1b[" .. (x - 1)  .. "D\x1b[" .. (unicode.len(line)) .. "C")
                    x = unicode.len(line) + 1
                end
            end
        elseif char:match("[%g%s]") then
            insert(char)
        end

        doVisualCompletion()
    end
end

return ocCodeComplete
