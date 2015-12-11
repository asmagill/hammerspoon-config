local module, placeholder = {}, {}

local speech   = require("hs.speech")
local listener = speech.listener
local fnutils  = require("hs.fnutils")
local log      = require("hs.logger").new("mySpeech","warning")
local settings = require("hs.settings")

local commands = {}
local title    = "Hammerspoon Listener"
local listenerCallback = function(listenerObj, text)
    if commands[text] then
        commands[text]()
    else
        log.wf("Unrecognized commend '%s' received", theCommand)
    end
end

local updateCommands = function()
    if module.recognizer then
        local cmdList = {}
        for k,v in fnutils.sortByKeys(commands) do
            table.insert(cmdList, k)
        end
        module.recognizer:commands(cmdList)
    end
end

module.log = log
module.commands = commands

module.add = function(text, func)
    assert(type(text) == "string", "command must be a string")
    assert(type(func) == "function", "action must be a function")

    if commands[text] then
        error("Command '"..text.."' is already registered", 2)
    end
    commands[text] = func

    updateCommands()
    return placeholder
end

module.remove = function(text)
    assert(type(text) == "string", "command must be a string")

    if commands[text] then
        commands[text] = nil
    else
        error("Command '"..text.."' is not registered", 2)
    end

    updateCommands()
    return placeholder
end

module.start = function()
    updateCommands() -- should be current, but just in case
    module.recognizer:title(title):start()
    settings.set("_asm.listener", true)
    return placeholder
end

module.stop = function()
    module.recognizer:title(title.." - disabled"):stop()
    settings.set("_asm.listener", false)
    return placeholder
end

module.isListening = function()
    if module.recognizer then
        return module.recognizer:isListening()
    else
        return nil
    end
end

module.disableCompletely = function()
    if module.recognizer then
        module.recognizer:delete()
    end
    module.recognizer = nil
    setmetatable(placeholder, nil)
end

module.init = function()
    if module.recognizer then
        error("Listener already initialized", 2)
    end
    module.recognizer = listener.new(title):setCallback(listenerCallback)
                                    :foregroundOnly(false)
                                    :blocksOtherRecognizers(false)
    return setmetatable(placeholder,  {
        __index = function(_, k)
            if module[k] then
                if type(module[k]) ~= "function" then return module[k] end
                return function(_, ...) return module[k](...) end
            else
                return nil
            end
        end,
        __tostring = function(_) return module.recognizer:title() end,
        __pairs = function(_) return pairs(module) end,
--         __gc = module.disableCompletely
    })
end

placeholder.init = function() return module.init():start() end

module.add("Open Hammerspoon Console", hs.openConsole)
module.add("Open System Console", function() require("hs.application").launchOrFocus("Console") end)
module.add("Open Terminal Application", function() require("hs.application").launchOrFocus("Terminal") end)
module.add("Hammerspoon Stop Listening", module.stop)
module.add("Go away for a while", module.disableCompletely)

if settings.get("_asm.listener") then placeholder.init() end

return placeholder
