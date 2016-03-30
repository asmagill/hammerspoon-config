--
-- hold down fn, even when on, or command is ignored (minimizes false positives in noisy
-- environments.)
--
local module, placeholder = {}, {}

local speech   = require("hs.speech")
local listener = speech.listener
local fnutils  = require("hs.fnutils")
local log      = require("hs.logger").new("mySpeech","warning")
local settings = require("hs.settings")
local eventtap = require("hs.eventtap")

local commands = {}
local title    = "Hammerspoon"
local listenerCallback = function(listenerObj, text)
    if eventtap.checkKeyboardModifiers().fn then
        if commands[text] then
            commands[text]()
        else
            log.wf("Unrecognized command '%s' received", text)
        end
    else
        log.vf("FN not depressed -- ignoring command '%s'", text)
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
    if (module.listenLabel) then
        local screen = require("hs.screen").primaryScreen():fullFrame()
        module.listenLabel:show():setFrame{
            x = screen.x + 5, y = screen.y + screen.h - 21,
            h = 14, w = 150
        }
    end
    return placeholder
end

module.stop = function()
    module.recognizer:title("Disabled: "..title):stop()
    if (module.listenLabel) then module.listenLabel:hide() end
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
    if (module.listenLabel) then
        module.listenLabel = module.listenLabel:delete()
    end
    settings.set("_asm.listener", false)
end

module.init = function()
    if module.recognizer then
        error("Listener already initialized", 2)
    end
    module.recognizer = listener.new(title):setCallback(listenerCallback)
                                    :foregroundOnly(false)
                                    :blocksOtherRecognizers(false)
    local screen = require("hs.screen").primaryScreen():fullFrame()
    module.listenLabel = require("hs.drawing").text({
                                    x = screen.x + 5, y = screen.y + screen.h - 21,
                                    h = 14, w = 150
                                }, require("hs.styledtext").new("Hold FN while speaking...", {
                                    font = { name = "Menlo-Italic", size = 10 },
                                    color = { list = "Crayons", name = "Sky" },
                                    paragraphStyle = { lineBreak = "clip" }
                                })):setBehaviorByLabels{"canJoinAllSpaces"}
                                :setLevel("popUpMenu")
                                :show()

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
    })
end

placeholder.init = function() return module.init() end

module.add("Open Hammerspoon Console", hs.openConsole)
module.add("Open System Console", function() require("hs.application").launchOrFocus("Console") end)
module.add("Open Editor", function() require("hs.application").launchOrFocus("BBEdit") end)
module.add("Open Browser", function() require("hs.application").launchOrFocus("Safari") end)
module.add("Open SmartGit", function() require("hs.application").launchOrFocus("SmartGit") end)
module.add("Open Mail", function() require("hs.application").launchOrFocus("Mail") end)
module.add("Open Terminal Application", function() require("hs.application").launchOrFocus("Terminal") end)
module.add("Re-Load Hammerspoon", hs.reload)
module.add("Re-Launch Hammerspoon", _asm.relaunch)
-- module.add("Stop Listening", module.stop)
module.add("Go away for a while", module.disableCompletely)

-- list doesn't appear until its started at least once; since we want to minimize false
-- positives, start disabled, but fill list in case Dictation Commands window is open.
if settings.get("_asm.listener") then placeholder.init():start():stop() end

return placeholder
