-- see https://github.com/Hammerspoon/hammerspoon/issues/1505

-- save file somewhere then type `m = dofile("path/file.lua")` to load it
-- For this example, since we're trying out varying modifiers, the recognized key sequences will be printed in the console
-- start the modal state by typing `m.start()`
-- *only* the recognized key sequences will be allowed through -- this means you can't even quit hammerspoon with Cmd-Q
-- without tapping escape first.

--- this generates the function to create the custom eventtap to suppress unwanted keys and pass through the ones we want

        local eventtap = require("hs.eventtap")
        local hotkey   = require("hs.hotkey")
        local keycodes = require("hs.keycodes")

        local suppressKeysOtherThenOurs = function(modal)
            local passThroughKeys = {}

        -- this is annoying because the event's raw flag bitmasks differ from the bitmasks used by hotkey, so
        -- we have to convert here for the lookup

            for i,v in ipairs(modal.keys) do
                -- parse for flags, get keycode for each
                local kc, mods = tostring(v._hk):match("keycode: (%d+), mods: (0x[^ ]+)")
                local hkFlags = tonumber(mods)
                local hkOriginal = hkFlags
                local flags = 0
                if (hkFlags &  256) ==  256 then hkFlags, flags = hkFlags -  256, flags | eventtap.event.rawFlagMasks.command   end
                if (hkFlags &  512) ==  512 then hkFlags, flags = hkFlags -  512, flags | eventtap.event.rawFlagMasks.shift     end
                if (hkFlags & 2048) == 2048 then hkFlags, flags = hkFlags - 2048, flags | eventtap.event.rawFlagMasks.alternate end
                if (hkFlags & 4096) == 4096 then hkFlags, flags = hkFlags - 4096, flags | eventtap.event.rawFlagMasks.control   end
                if hkFlags ~= 0 then print("unexpected flag pattern detected for " .. tostring(v._hk)) end
                passThroughKeys[tonumber(kc)] = flags
            end

            return eventtap.new({
                eventtap.event.types.keyDown,
                eventtap.event.types.keyUp,
            }, function(event)
                -- check only the flags we care about and filter the rest
                local flags = event:getRawEventData().CGEventData.flags  & (
                                                          eventtap.event.rawFlagMasks.command   |
                                                          eventtap.event.rawFlagMasks.control   |
                                                          eventtap.event.rawFlagMasks.alternate |
                                                          eventtap.event.rawFlagMasks.shift
                                                      )
                if passThroughKeys[event:getKeyCode()] == flags then
--                     hs.printf("passing:     %3d 0x%08x", event:getKeyCode(), flags)
                    return false -- pass it through so hotkey can catch it
                else
--                     hs.printf("suppressing: %3d 0x%08x", event:getKeyCode(), flags)
                    return true -- delete it if we got this far -- it's a key that we want suppressed
                end
            end)
        end


-- define the modal hotkey here

    local alert = require("hs.alert")

    local triggerKey = hotkey.modal.new()

    triggerKey.entered = function(self) -- or function triggerKey:entered(); I prefer the other syntax because it makes the self explicit
        triggerKey._eventtap = suppressKeysOtherThenOurs(self):start()
        alert("Entering modal only key mode, tap escape to exit")
    end

    triggerKey.exited = function(self)
        triggerKey._eventtap:stop()
        triggerKey._eventtap = nil
        alert("Exiting modal only key mode")
    end

    -- quick and dirty loop to create some keys we want to watch:
    for i = 0, 9, 1 do
        local mods = {}
        -- mix it up a bit so we can test multiple flag combinations
        if i % 2 == 0 then table.insert(mods, "cmd") end
        if i % 3 == 0 then table.insert(mods, "alt") end
        if i % 5 == 0 then table.insert(mods, "shift") end
        if i % 7 == 0 then table.insert(mods, "ctrl") end
        local modsString = "{ " .. table.concat(mods, ", ") .. " }"
        hs.printf("Binding: %s-%d", modsString, i)
        triggerKey:bind(mods, tostring(i), function()
            alert("Down: " .. modsString .. "-" .. tostring(i))
        end,
        function()
            alert("Up: " .. modsString .. "-" .. tostring(i))
        end)
    end

-- make sure there is a way out!
    triggerKey:bind({}, "escape", function() triggerKey:exit() end)

-- some framework to start/stop the modal key programatically
    local module = {}

    module.start = function()
        if not triggerKey._eventtap then
            triggerKey:enter()
        end
    end

    module.stop = function()
        if triggerKey._eventtap then
            triggerKey:exit()
        end
    end

return module

