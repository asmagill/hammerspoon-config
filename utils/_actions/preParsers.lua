local module = {}
local ipc      = require("hs.ipc")

-- pre-parser core
local preParser = function(s)
    -- allow !# like bash to redo a command from the history
    local historyNumber = s:match("^!(-?%d+)$")
    if historyNumber then s = "history(" .. historyNumber .. ")" end

    -- allow `history what`
    if s:match("^history%s+[^\"]") then s = s:gsub("^history ", "history \"") .. "\"" end

    if s:match("^help") and not s:match("^help%.") then
        -- allow help(what) without quotes
        local helpParen = s:match("^help%s*%(([^\"]*)%)%s*$")
        if helpParen then
            if helpParen == "" then
                s = "help"
            else
                s = "help." .. helpParen
            end
        end

        -- allow `help what`
        if s:match("^help%s+[^\"]") then s = s:gsub("^help%s+", "help.") end
    end
    return s
end

-- pre-parser for Console
local previousParser = hs._consoleInputPreparser
hs._consoleInputPreparser = function(s)
    if previousParser then s = previousParser(s) end
    -- invoke my common pre-parser
    return preParser(s)
end

-- pre-parser for ipc's command line tool
local ipcRawhandler = ipc.handler
ipc.handler = function(str)
    str = preParser(str)
    return ipcRawhandler(str)
end

module.help = function(...)
    local output = [[

This module preparses input from the Console or from the IPC `hs` command line tool.  The
following conversions are applied:

    !#            - performs the command at the specified number in the console history;
                    negative numbers are offset from the history end
    history what  - automatically wraps `what` in quotes, if it isn't already
    help(what)    - automatically wraps `what` in quotes, if it isn't already
    help what     - replaces the first space with a period to take advantage of help's
                    __tostring methods

]]
    return output
end

module = setmetatable(module, {
    __tostring = function(self) return self.help() end,
    __call     = function(self, ...) return self.help(...) end,
})

return module
