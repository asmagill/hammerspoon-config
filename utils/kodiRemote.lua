
-- requires hs._asm.canvas and hs._asm.kodi
-- still very experimental
-- may be added to kodi module or provided as example, not sure yet...

local module = {}
local USERDATA_TAG = "kodiRemote"

local kodi       = require("hs._asm.kodi")
local canvas     = require("hs.canvas")
local logger     = require("hs.logger")
local settings   = require("hs.settings")
local stext      = require("hs.styledtext")
local menu       = require("hs.menubar")
local eventtap   = require("hs.eventtap")
local mouse      = require("hs.mouse")
local geometry   = require("hs.geometry")
local timer      = require("hs.timer")
local hotkey     = require("hs.hotkey")
local caffeinate = require("hs.caffeinate")

local events     = eventtap.event.types

local btnRepeatDelay    = settings.get(USERDATA_TAG .. ".btnRepeatDelay") or 0.5
local btnRepeatInterval = settings.get(USERDATA_TAG .. ".btnRepeatInterval") or 0.1
local tooltipDelay      = settings.get(USERDATA_TAG .. ".tooltipDelay") or 3
local showTooltips      = settings.get(USERDATA_TAG .. ".showTooltips") or false
local remoteTopLeft     = settings.get(USERDATA_TAG .. ".topLeft") or { x = 100, y = 100 }
local autosave          = settings.get(USERDATA_TAG .. ".autosave") or false
local startVisible      = settings.get(USERDATA_TAG .. ".startVisible") or false
local autodim           = settings.get(USERDATA_TAG .. ".autodim") or false
local keyEquivalents    = settings.get(USERDATA_TAG .. ".keyEquivalents") or false

local log  = logger.new(USERDATA_TAG, settings.get(USERDATA_TAG .. ".logLevel") or "warning")

local remoteFrame = { x = remoteTopLeft.x, y = remoteTopLeft.y, h = 200, w = 150 }
local dialFrame   = { x = 25, y = 10, h = 100, w = 100 }

-- forward declarations
local updateMutedStatus
local updateLinkStatus
local attachedKODI
local tooltipTimer
local keysEnabled = false
local isVisible   = false

local remote = canvas.new(remoteFrame):level(canvas.windowLevels.popUpMenu)
                                      :behaviorAsLabels({"canJoinAllSpaces"})

local findIndex = function(id)
    local idx
    for i, v in ipairs(remote) do
        if v.id == id then
            idx = i
            break
        end
    end
    return idx
end

local volumeIndicatorMuted = {
    [true]  = stext.new(utf8.char(0x1f507), {
                  font = { name = "Menlo", size = 18 },
                  paragraphStyle = { alignment = "center" },
              }),
    [false] = stext.new(utf8.char(0x1f508), {
                  font = { name = "Menlo", size = 18 },
                  paragraphStyle = { alignment = "center" },
              })
}

local labelChars = {
    ["Input.Left"] = stext.new(utf8.char(0x25c0), {
                            font = { name = "Menlo", size = 14 },
                            paragraphStyle = { alignment = "center" },
                            color = { white = 1 },
                        }),
    ["Input.Right"] = stext.new(utf8.char(0x25b6), {
                            font = { name = "Menlo", size = 14 },
                            paragraphStyle = { alignment = "center" },
                            color = { white = 1 },
                        }),
    ["Input.Up"] = stext.new(utf8.char(0x25b2), {
                            font = { name = "Menlo", size = 14 },
                            paragraphStyle = { alignment = "center" },
                            color = { white = 1 },
                        }),
    ["Input.Down"] = stext.new(utf8.char(0x25bc), {
                            font = { name = "Menlo", size = 14 },
                            paragraphStyle = { alignment = "center" },
                            color = { white = 1 },
                        }),
    ["Input.Select"] = stext.new(utf8.char(0x23ce), {
                            font = { name = "Menlo", size = 24 },
                            paragraphStyle = { alignment = "center" },
                            color = { white = 1 },
                        }),
    ["Input.ExecuteAction"] = stext.new(utf8.char(0x2630), {
                           font = { name = "Menlo", size = 14 },
                            paragraphStyle = { alignment = "center" },
                           color = { white = 1 },
                       }),
    ["Input.Back"] = stext.new(utf8.char(0x1f519), {
                            font = { name = "Menlo", size = 18 },
                            paragraphStyle = { alignment = "center" },
                        }),
    ["Input.Home"] = stext.new(utf8.char(0x1f3da), {
                            font = { name = "Menlo", size = 18 },
                            paragraphStyle = { alignment = "center" },
                        }),
    ["CloseWindow"] = stext.new(utf8.char(0x2612), {
                            font = { name = "Menlo", size = 14 },
                            paragraphStyle = { alignment = "center" },
                        }),
    ["MoveWindow"] = stext.new(utf8.char(0x29bf), {
                            font = { name = "Menlo", size = 18 },
                            paragraphStyle = { alignment = "center" },
                        }),
    ["Input.Info"] = stext.new(utf8.char(0x2139), {
                            font = { name = "Menlo", size = 14 },
                            paragraphStyle = { alignment = "center" },
                        }),
    ["Input.ShowCodec"] = stext.new(utf8.char(0x1f50e), { -- 0x1f453), {
                            font = { name = "Menlo", size = 12 },
                            paragraphStyle = { alignment = "center" },
                        }),
    ["Input.ShowOSD"] = stext.new(utf8.char(0x1f3ae), {
                            font = { name = "Menlo", size = 12 },
                            paragraphStyle = { alignment = "center" },
                        }),
    ["Player.Stop"] = stext.new(utf8.char(0x23f9), {
                            font = { name = "Menlo", size = 18 },
                            paragraphStyle = { alignment = "center" },
                        }),
    ["Player.PlayPause"] = stext.new(utf8.char(0x23ef), {
                            font = { name = "Menlo", size = 18 },
                            paragraphStyle = { alignment = "center" },
                        }),
    ["Player.SetSpeed.increment"] = stext.new(utf8.char(0x23e9), {
                            font = { name = "Menlo", size = 18 },
                            paragraphStyle = { alignment = "center" },
                        }),
    ["Player.SetSpeed.decrement"] = stext.new(utf8.char(0x23ea), {
                            font = { name = "Menlo", size = 18 },
                            paragraphStyle = { alignment = "center" },
                        }),
    ["Application.SetMute.toggle"] = volumeIndicatorMuted[true],
    ["Application.SetVolume.increment"] = stext.new(utf8.char(0x1f50a), {
                            font = { name = "Menlo", size = 18 },
                            paragraphStyle = { alignment = "center" },
                        }),
    ["Application.SetVolume.decrement"] = stext.new(utf8.char(0x1f509), {
                            font = { name = "Menlo", size = 18 },
                            paragraphStyle = { alignment = "center" },
                        }),
    ["Keyboard"] = stext.new(utf8.char(0x2328), {
                            font = { name = "Menlo", size = 18 },
                            paragraphStyle = { alignment = "center" },
                        }),
}

local labelOffsets = {
    ["Input.Left"] = { x = 0, y = -3 },
    ["Input.Right"] = { x = 0, y = -3 },
    ["Input.Up"] = { x = 0, y = -3 },
    ["Input.Down"] = { x = 0, y = -3 },
    ["Input.Select"] = { x = 0, y = -4 },
    ["Input.ExecuteAction"] = { x = 0, y = -1 },
    ["Input.Back"] = { x = 0, y = -1 },
    ["Input.Home"] = { x = 1, y = -2 },
    ["CloseWindow"] = { x = 0, y = -2 },
    ["MoveWindow"] = { x = 0, y = -2 },
    ["Input.Info"] = { x = 0, y = -2 },
    ["Input.ShowCodec"] = { x = 1, y = 0 },
    ["Input.ShowOSD"] = { x = 1, y = 0 },
    ["Player.Stop"] = { x = .5, y = -.5 },
    ["Player.PlayPause"] = { x = .5, y = -.5 },
    ["Player.SetSpeed.increment"] = { x = .5, y = -.5 },
    ["Player.SetSpeed.decrement"] = { x = .5, y = -.5 },
    ["Application.SetMute.toggle"] = { x = 2, y = 0 },
    ["Volume.SetVolume.increment"] = { x = 2, y = -2 },
    ["Volume.SetVolume.decrement"] = { x = 2, y = -2 },
    ["Keyboard"] = { x = 0, y = 0 },
}

local repeatTimers = {}

local doCommandForPlayers = function(id, params)
    params = params or {}
    local oldplayerid = params.playerid
    if module.KODI and module.KODI:isRunning() then
        local players = module.KODI("Player.GetActivePlayers")
        if players then
            for i, v in ipairs(players) do
                params.playerid = v.playerid
                module.KODI(id, params)
            end
        end
    end
    params.playerid = oldplayerid
end

local movementMouseDown = function(c, m, id, x, y)
    if module.KODI and module.KODI:isRunning() then
        module.KODI(id)
        if not repeatTimers.movement then
            repeatTimers.movement = timer.doAfter(btnRepeatDelay, function()
                module.KODI(id)
--         log.d(id)
                repeatTimers.movement = timer.doEvery(btnRepeatInterval, function()
                    module.KODI(id)
--         log.d(id)
                end)
            end)
        else
            repeatTimers.movement:stop()
            repeatTimers.movement = nil
            log.e("Input movement mouseDown detected while repeat timer active; disabling timer")
        end
    end
end

local movementMouseUp = function(c, m, id, x, y)
    if repeatTimers.movement then
        repeatTimers.movement:stop()
        repeatTimers.movement = nil
    end
end

local labelDownFN = {
    ["Input.Left"]  = movementMouseDown,
    ["Input.Right"] = movementMouseDown,
    ["Input.Up"]    = movementMouseDown,
    ["Input.Down"]  = movementMouseDown,
    ["Application.SetVolume.increment"] = function(c, m, id, x, y)
        if module.KODI and module.KODI:isRunning() then
            module.KODI("Application.SetVolume", { volume = "increment" })
            if not repeatTimers.volume then
                repeatTimers.volume = timer.doAfter(btnRepeatDelay, function()
                    module.KODI("Application.SetVolume", { volume = "increment" })
                    repeatTimers.volume = timer.doEvery(btnRepeatInterval, function()
                        module.KODI("Application.SetVolume", { volume = "increment" })
                    end)
                end)
            else
                repeatTimers.volume:stop()
                repeatTimers.volume = nil
                log.e("Volume mouseDown detected while repeat timer active; disabling timer")
            end
        end
    end,
    ["Application.SetVolume.decrement"] = function(c, m, id, x, y)
        if module.KODI and module.KODI:isRunning() then
            module.KODI("Application.SetVolume", { volume = "decrement" })
            if not repeatTimers.volume then
                repeatTimers.volume = timer.doAfter(btnRepeatDelay, function()
                    module.KODI("Application.SetVolume", { volume = "decrement" })
                    repeatTimers.volume = timer.doEvery(btnRepeatInterval, function()
                        module.KODI("Application.SetVolume", { volume = "decrement" })
                    end)
                end)
            else
                repeatTimers.volume:stop()
                repeatTimers.volume = nil
                log.e("Volume mouseDown detected while repeat timer active; disabling timer")
            end
        end
    end,
    ["Input.ExecuteAction"] = function(c, m, id, x, y)
        if eventtap.checkMouseButtons().right or eventtap.checkKeyboardModifiers().ctrl then
            local idx = findIndex(id)
            if not idx then
                log.wf("unable to match %s to an element index for callback", tostring(id))
                return
            end
            local menuList = {}
            if module.KODI and module.KODI:isRunning() then
                local InputActions = module.KODI:API().types["Input.Action"].enums
                table.sort(InputActions)
                for i, v in ipairs(InputActions) do
                    table.insert(menuList, {
                        title = stext.new(v, {
                            font = {
                                name = "Menlo",
                                size = 10,
                            },
                        }),
                        fn = function() module.KODI(id, { action = v }) end,
                    })
                end
            else
                table.insert(menuList, {
                    title = stext.new("KODI offline",  {
                        font = {
                            name = "Menlo-Italic",
                            size = 10,
                        },
                    }),
                    disabled = true,
                })

            end
            local bounds = remote:elementBounds(idx)
            local topLeft = remote:topLeft()
            bounds.x = topLeft.x + bounds.x
            bounds.y = topLeft.y + bounds.y

            -- allow arrow keys to be used in the pop-up menu
            if keysEnabled then module.modalKeys:exit() end
            menu.new(false):setMenu(menuList):popupMenu({ x = bounds.x, y = bounds.y + bounds.h })
            if keysEnabled then module.modalKeys:enter() end

        end
    end,
    ["MoveWindow"] = function(c, m, id, x, y)
        local idx = findIndex(id)
        if not idx then
            log.wf("unable to match %s to an element index for callback", tostring(id))
            return
        end
        module._mouseMoveTracker = eventtap.new({ events.leftMouseDragged, events.leftMouseUp }, function(e)
            if e:getType() == events.leftMouseUp then
                module._mouseMoveTracker:stop()
                module._mouseMoveTracker = nil
                if autosave then
                    settings.set(USERDATA_TAG .. ".topLeft", remote:topLeft())
                end
            else
                local mousePosition = mouse.getAbsolutePosition()
                remote:topLeft({ x = mousePosition.x - x, y = mousePosition.y - y })
            end
--            return false
        end, false):start()
    end,
}

local labelUpFN = {
    ["Input.Left"]  = movementMouseUp,
    ["Input.Right"] = movementMouseUp,
    ["Input.Up"]    = movementMouseUp,
    ["Input.Down"]  = movementMouseUp,
    ["Application.SetVolume.increment"] = function(c, m, id, x, y)
        if repeatTimers.volume then
            repeatTimers.volume:stop()
            repeatTimers.volume = nil
        end
    end,
    ["Application.SetVolume.decrement"] = function(c, m, id, x, y)
        if repeatTimers.volume then
            repeatTimers.volume:stop()
            repeatTimers.volume = nil
        end
    end,
    ["Application.SetMute.toggle"] = function(c, m, id, x, y)
        if module.KODI and module.KODI:isRunning() then
            module.KODI("Application.SetMute", { mute = "toggle" })
        end
        updateMutedStatus()
    end,
    ["Input.ExecuteAction"] = function(c, m, id, x, y)
        if module.KODI and module.KODI:isRunning() then
            if not (eventtap.checkMouseButtons().right or eventtap.checkKeyboardModifiers().ctrl) then
                module.KODI("Input.ContextMenu")
            end
        end
    end,
    ["CloseWindow"] = function(c, m, id, x, y)
        local idx = findIndex(id)
        if not idx then
            log.wf("unable to match %s to an element index for callback", tostring(id))
            return
        end
        remote[idx].fillColor.alpha = 0.0
        module.hide()
    end,
    ["Player.Stop"] = function(c, m, id, x, y)
        doCommandForPlayers(id)
    end,
    ["Player.PlayPause"] = function(c, m, id, x, y)
        doCommandForPlayers(id)
    end,
    ["Player.SetSpeed.increment"] = function(c, m, id, x, y)
        doCommandForPlayers("Player.SetSpeed", { speed = "increment" })
    end,
    ["Player.SetSpeed.decrement"] = function(c, m, id, x, y)
        doCommandForPlayers("Player.SetSpeed", { speed = "decrement" })
    end,
    ["Keyboard"] = function(c, m, id, x, y)
        module.keyEquivalents(not keyEquivalents)
    end,
}

remote[#remote + 1] = { id = "remoteBackground",
    type = "rectangle",
    action = "fill",
    roundedRectRadii = { xRadius = 10, yRadius = 10 },
    fillColor = { white = 0.4, alpha = 0.25 },
    trackMouseEnterExit = true,
}

remote[#remote + 1] = { id = "LinkStatus",
    type = "oval",
    action = "fill",
    fillColor   = { red = 1 },
    frame = { x = 10, y = 10, h = 10, w = 10 },
}

local linkStatusIndex = #remote

remote[#remote + 1] = { id = "Input.Up",
    type = "segments",
    strokeColor = { white = .25 },
    fillColor   = { white = .25, alpha = 0 },
    strokeWidth = 2,
    coordinates = {
        {
            x = dialFrame.x + 15,
            y = dialFrame.y + 10
        },
        {
            x = dialFrame.x + dialFrame.w - 15,
            y = dialFrame.y + 10,
            c1x = dialFrame.x + dialFrame.w / 2,
            c1y = dialFrame.y - 5,
            c2x = dialFrame.x + dialFrame.w / 2,
            c2y = dialFrame.y - 5
        },
        {
            x = dialFrame.x + dialFrame.w - 30,
            y = dialFrame.y + 25
        },
        {
            x = dialFrame.x + 30,
            y = dialFrame.y + 25,
            c1x = dialFrame.x + dialFrame.w / 2,
            c1y = dialFrame.y + 20,
            c2x = dialFrame.x + dialFrame.w / 2,
            c2y = dialFrame.y + 20
        },
    },
    closed = true,
    trackMouseDown      = true,
    trackMouseEnterExit = true,
    trackMouseUp        = true,
}

remote[#remote + 1] = { id = "Input.Down",
    type = "segments",
    strokeColor = { white = .25 },
    fillColor   = { white = .25, alpha = 0 },
    strokeWidth = 2,
    coordinates = {
        {
            x = dialFrame.x + 15,
            y = dialFrame.y + dialFrame.h - 10
        },
        {
            x = dialFrame.x + dialFrame.w - 15,
            y = dialFrame.y + dialFrame.h - 10,
            c1x = dialFrame.x + dialFrame.w / 2,
            c1y = dialFrame.y + dialFrame.h + 5,
            c2x = dialFrame.x + dialFrame.w / 2,
            c2y = dialFrame.y + dialFrame.h + 5
        },
        {
            x = dialFrame.x + dialFrame.w - 30,
            y = dialFrame.y + dialFrame.h - 25
        },
        {
            x = dialFrame.x + 30,
            y = dialFrame.y + dialFrame.h - 25,
            c1x = dialFrame.x + dialFrame.w / 2,
            c1y = dialFrame.y + dialFrame.h - 20,
            c2x = dialFrame.x + dialFrame.w / 2,
            c2y = dialFrame.y + dialFrame.h - 20
        },
    },
    closed = true,
    trackMouseDown      = true,
    trackMouseEnterExit = true,
    trackMouseUp        = true,
}

remote[#remote + 1] = { id = "Input.Left",
    type = "segments",
    strokeColor = { white = .25 },
    fillColor   = { white = .25, alpha = 0 },
    strokeWidth = 2,
    coordinates = {
        {
            x = dialFrame.x + 10,
            y = dialFrame.y + 15
        },
        {
        x = dialFrame.x + 10,
            y = dialFrame.y + dialFrame.h - 15,
            c1x = dialFrame.x - 5,
            c1y = dialFrame.y + dialFrame.h / 2,
            c2x = dialFrame.x - 5,
            c2y = dialFrame.y + dialFrame.h / 2
        },
        {
            x = dialFrame.x + 25,
            y = dialFrame.y + dialFrame.h - 30
        },
        {
        x = dialFrame.x + 25,
            y = dialFrame.y + 30,
            c1x = dialFrame.x + 20,
            c1y = dialFrame.y + dialFrame.h / 2,
            c2x = dialFrame.x + 20,
            c2y = dialFrame.y + dialFrame.h / 2
        },
    },
    closed = true,
    trackMouseDown      = true,
    trackMouseEnterExit = true,
    trackMouseUp        = true,
}

remote[#remote + 1] = { id = "Input.Right",
    type = "segments",
    strokeColor = { white = .25 },
    fillColor   = { white = .25, alpha = 0 },
    strokeWidth = 2,
    coordinates = {
        {
            x = dialFrame.x + dialFrame.w - 10,
            y = dialFrame.y + 15
        },
        {
        x = dialFrame.x + dialFrame.w - 10,
            y = dialFrame.y + dialFrame.h - 15,
            c1x = dialFrame.x + dialFrame.w + 5,
            c1y = dialFrame.y + dialFrame.h / 2,
            c2x = dialFrame.x + dialFrame.w + 5,
            c2y = dialFrame.y + dialFrame.h / 2
        },
        {
            x = dialFrame.x + dialFrame.w - 25,
            y = dialFrame.y + dialFrame.h - 30
        },
        {
            x = dialFrame.x + dialFrame.w - 25,
            y = dialFrame.y + 30,
            c1x = dialFrame.x + dialFrame.w - 20,
            c1y = dialFrame.y + dialFrame.h / 2,
            c2x = dialFrame.x + dialFrame.w - 20,
            c2y = dialFrame.y + dialFrame.h / 2
        },
    },
    closed = true,
    trackMouseDown      = true,
    trackMouseEnterExit = true,
    trackMouseUp        = true,
}

remote[#remote + 1] = { id = "Input.Select",
    type = "oval",
    strokeColor = { white = .25 },
    fillColor   = { white = .25, alpha = 0 },
    strokeWidth = 2,
    frame = {
        x = dialFrame.x + dialFrame.w / 4,
        y = dialFrame.y + dialFrame.h / 4,
        h = dialFrame.h / 2,
        w = dialFrame.w / 2,
    },
    trackMouseDown      = true,
    trackMouseEnterExit = true,
    trackMouseUp        = true,
}

remote[#remote + 1] = { id = "Input.ExecuteAction",
    type = "rectangle",
    action = "fill",
    strokeColor = { white = .25 },
    fillColor   = { white = .25, alpha = 0 },
    strokeWidth = 2,
    roundedRectRadii = { xRadius = 5, yRadius = 5 },
    frame = {
        x = remoteFrame.w - 20,
        y = remoteFrame.h - 20,
        h = 18,
        w = 18,
    },
    trackMouseDown      = true,
    trackMouseEnterExit = true,
    trackMouseUp        = true,
}

remote[#remote + 1] = { id = "Input.Back",
    type = "rectangle",
    action = "fill",
    strokeColor = { white = .25 },
    fillColor   = { white = .25, alpha = 0 },
    strokeWidth = 2,
    roundedRectRadii = { xRadius = 5, yRadius = 5 },
    frame = {
        x = 10,
        y = dialFrame.y + dialFrame.h,
        h = 20,
        w = 20,
    },
    trackMouseDown      = true,
    trackMouseEnterExit = true,
    trackMouseUp        = true,
}

remote[#remote + 1] = { id = "Input.Home",
    type = "rectangle",
    action = "fill",
    strokeColor = { white = .25 },
    fillColor   = { white = .25, alpha = 0 },
    strokeWidth = 2,
    roundedRectRadii = { xRadius = 5, yRadius = 5 },
    frame = {
        x = remoteFrame.w - (5 + 20), -- offset from side + offset for width
        y = dialFrame.y + dialFrame.h,
        h = 20,
        w = 20,
    },
    trackMouseDown      = true,
    trackMouseEnterExit = true,
    trackMouseUp        = true,
}


remote[#remote + 1] = { id = "Input.Info",
    type = "rectangle",
    action = "fill",
    strokeColor = { white = .25 },
    fillColor   = { white = .25, alpha = 0 },
    strokeWidth = 2,
    roundedRectRadii = { xRadius = 5, yRadius = 5 },
    frame = {
        x = 5,
        y = remoteFrame.h - 20,
        h = 18,
        w = 18,
    },
    trackMouseDown      = true,
    trackMouseEnterExit = true,
    trackMouseUp        = true,
}

remote[#remote + 1] = { id = "Keyboard",
    type = "rectangle",
    action = "fill",
    strokeColor = { white = .25 },
    fillColor   = keyEquivalents and { green = .25, alpha = 0 }
                                  or { white = .25, alpha = 0 },
    strokeWidth = 2,
    roundedRectRadii = { xRadius = 5, yRadius = 5 },
    frame = {
        x = 23,
        y = remoteFrame.h - 20,
        h = 18,
        w = 18,
    },
    trackMouseDown      = true,
    trackMouseEnterExit = true,
    trackMouseUp        = true,
}

remote[#remote + 1] = { id = "Input.ShowOSD",
    type = "rectangle",
    action = "fill",
    strokeColor = { white = .25 },
    fillColor   = { white = .25, alpha = 0 },
    strokeWidth = 2,
    roundedRectRadii = { xRadius = 5, yRadius = 5 },
    frame = {
        x = remoteFrame.w - 60,
        y = remoteFrame.h - 20,
        h = 18,
        w = 18,
    },
    trackMouseDown      = true,
    trackMouseEnterExit = true,
    trackMouseUp        = true,
}

remote[#remote + 1] = { id = "Input.ShowCodec",
    type = "rectangle",
    action = "fill",
    strokeColor = { white = .25 },
    fillColor   = { white = .25, alpha = 0 },
    strokeWidth = 2,
    roundedRectRadii = { xRadius = 5, yRadius = 5 },
    frame = {
        x = remoteFrame.w - 40,
        y = remoteFrame.h - 20,
        h = 18,
        w = 18,
    },
    trackMouseDown      = true,
    trackMouseEnterExit = true,
    trackMouseUp        = true,
}

remote[#remote + 1] = { id = "CloseWindow",
    type = "rectangle",
    action = "fill",
    strokeColor = { white = .25 },
    fillColor   = { white = .25, alpha = 0 },
    strokeWidth = 2,
    roundedRectRadii = { xRadius = 5, yRadius = 5 },
    frame = {
        x = remoteFrame.w - (5 + 16), -- offset from side + offset for width
        y = 5,
        h = 16,
        w = 16,
    },
    trackMouseDown      = true,
    trackMouseEnterExit = true,
    trackMouseUp        = true,
}

remote[#remote + 1] = { id = "MoveWindow",
    type = "rectangle",
    action = "fill",
    strokeColor = { white = .25 },
    fillColor   = { white = .25, alpha = 0 },
    strokeWidth = 2,
    roundedRectRadii = { xRadius = 5, yRadius = 5 },
    frame = {
        x = remoteFrame.w / 2 - 10,
        y = remoteFrame.h - 20,
        h = 18,
        w = 18,
    },
    trackMouseDown      = true,
    trackMouseEnterExit = true,
    trackMouseUp        = true,
}

remote[#remote + 1] = { id = "Player.SetSpeed.decrement",
    type = "rectangle",
    action = "fill",
    strokeColor = { white = .25 },
    fillColor   = { white = .25, alpha = 0 },
    strokeWidth = 2,
    roundedRectRadii = { xRadius = 5, yRadius = 5 },
    frame = {
        x = remoteFrame.w / 2 - 44,
        y = dialFrame.y + dialFrame.h + 30,
        h = 22,
        w = 22,
    },
    trackMouseDown      = true,
    trackMouseEnterExit = true,
    trackMouseUp        = true,
}

remote[#remote + 1] = { id = "Player.PlayPause",
    type = "rectangle",
    action = "fill",
    strokeColor = { white = .25 },
    fillColor   = { white = .25, alpha = 0 },
    strokeWidth = 2,
    roundedRectRadii = { xRadius = 5, yRadius = 5 },
    frame = {
        x = remoteFrame.w / 2 - 22,
        y = dialFrame.y + dialFrame.h + 30,
        h = 22,
        w = 22,
    },
    trackMouseDown      = true,
    trackMouseEnterExit = true,
    trackMouseUp        = true,
}

remote[#remote + 1] = { id = "Player.Stop",
    type = "rectangle",
    action = "fill",
    strokeColor = { white = .25 },
    fillColor   = { white = .25, alpha = 0 },
    strokeWidth = 2,
    roundedRectRadii = { xRadius = 5, yRadius = 5 },
    frame = {
        x = remoteFrame.w / 2 + 2,
        y = dialFrame.y + dialFrame.h + 30,
        h = 22,
        w = 22,
    },
    trackMouseDown      = true,
    trackMouseEnterExit = true,
    trackMouseUp        = true,
}

remote[#remote + 1] = { id = "Player.SetSpeed.increment",
    type = "rectangle",
    action = "fill",
    strokeColor = { white = .25 },
    fillColor   = { white = .25, alpha = 0 },
    strokeWidth = 2,
    roundedRectRadii = { xRadius = 5, yRadius = 5 },
    frame = {
        x = remoteFrame.w / 2 + 24,
        y = dialFrame.y + dialFrame.h + 30,
        h = 22,
        w = 22,
    },
    trackMouseDown      = true,
    trackMouseEnterExit = true,
    trackMouseUp        = true,
}

remote[#remote + 1] = { id = "Application.SetMute.toggle",
    type = "rectangle",
    action = "fill",
    strokeColor = { white = .25 },
    fillColor   = { white = .25, alpha = 0 },
    strokeWidth = 2,
    roundedRectRadii = { xRadius = 5, yRadius = 5 },
    frame = {
        x = remoteFrame.w / 2 - 11,
        y = dialFrame.y + dialFrame.h + 5,
        h = 22,
        w = 22,
    },
    trackMouseDown      = true,
    trackMouseEnterExit = true,
    trackMouseUp        = true,
}

remote[#remote + 1] = { id = "Application.SetVolume.increment",
    type = "rectangle",
    action = "fill",
    strokeColor = { white = .25 },
    fillColor   = { white = .25, alpha = 0 },
    strokeWidth = 2,
    roundedRectRadii = { xRadius = 5, yRadius = 5 },
    frame = {
        x = remoteFrame.w / 2 + 13,
        y = dialFrame.y + dialFrame.h + 5,
        h = 22,
        w = 22,
    },
    trackMouseDown      = true,
    trackMouseEnterExit = true,
    trackMouseUp        = true,
}

remote[#remote + 1] = { id = "Application.SetVolume.decrement",
    type = "rectangle",
    action = "fill",
    strokeColor = { white = .25 },
    fillColor   = { white = .25, alpha = 0 },
    strokeWidth = 2,
    roundedRectRadii = { xRadius = 5, yRadius = 5 },
    frame = {
        x = remoteFrame.w / 2 - 35,
        y = dialFrame.y + dialFrame.h + 5,
        h = 22,
        w = 22,
    },
    trackMouseDown      = true,
    trackMouseEnterExit = true,
    trackMouseUp        = true,
}

for k, v in pairs(labelChars) do
    local idx = findIndex(k)
    if not idx then
        log.df("unable to match %s to an element index for labelChars", k)
    else
        local bounds = remote:elementBounds(idx)
        local size   = remote:minimumTextSize(v)
        local offset = labelOffsets[k] or { x = 0, y = 0 }
        remote[#remote + 1] = {
            id = k .. ".text",
            type = "text",
            text = v,
            frame = {
                x = bounds.x + (bounds.w - size.w) / 2 + offset.x,
                y = bounds.y + (bounds.h - size.h) / 2 + offset.y,
                h = size.h,
                w = size.w,
            },
        }
    end
end

remote[#remote + 1] = { id = "tooltip",
    action = "skip",
    type = "rectangle",
    fillColor = { list = "System", name = "selectedTextBackgroundColor" },
    roundedRectRadii = { xRadius = 5, yRadius = 5 },
}
local tooltipIndex = #remote

remote[#remote + 1] = { id = "tooltipText",
    action        = "skip",
    textFont      = "Menlo-Italic",
    textLineBreak = "charWrap",
    textSize      = 10,
    textColor     = { white = 0 },
    type = "text",
}

-- record initial actions for when remote is being displayed ; used by autodim code
local standardActions = {}
for i = 2, #remote, 1 do
    standardActions[i] = remote[i].action
end

local updateVisibility = function()
    local state = true
    local mousePos = mouse.getAbsolutePosition()
    local onOff = isVisible and geometry.inside(mousePos, remote:frame())

    if autodim then state = onOff end
    for i = 2, #remote, 1 do
        remote[i].action = state and standardActions[i] or "skip"
    end
    remote[tooltipIndex].action     = "skip"
    remote[tooltipIndex + 1].action = "skip"

    local keyIndex = findIndex("Keyboard")
    local keyAlpha = remote[keyIndex].fillColor.alpha
    remote[keyIndex].fillColor = keyEquivalents and { green = .25, alpha = keyAlpha }
                                                 or { white = .25, alpha = keyAlpha }

    if onOff and keyEquivalents and not keysEnabled then
        module.modalKeys:enter()
    elseif not onOff then
        if keysEnabled then module.modalKeys:exit() end
        remote[1].fillColor.alpha = 0.25
        if tooltipTimer then
            tooltipTimer:stop()
            tooltipTimer = nil
        end
    end
end

local volumeIndicatorIndex = findIndex("Application.SetMute.toggle.text")

local updateLinkStatus = function()
    if module.KODI and module.KODI:isRunning() then
        remote[linkStatusIndex].fillColor = { green = 1 }
    else
        remote[linkStatusIndex].fillColor = { red = 1 }
    end
end

updateMutedStatus = function()
    if module.KODI and module.KODI:isRunning() and volumeIndicatorIndex then
        local muted = module.KODI("Application.GetProperties", { properties = { "muted" } })
        if type(muted) == "table" and type(muted.muted) ~= "nil" then
            remote[volumeIndicatorIndex].text = volumeIndicatorMuted[muted.muted]
        else
            remote[volumeIndicatorIndex].text = volumeIndicatorMuted[true]
        end
    else
        remote[volumeIndicatorIndex].text = volumeIndicatorMuted[true]
    end
end

local mouseCallback = function(c, m, id, x, y)
    if tooltipTimer then
        tooltipTimer:stop()
        tooltipTimer = nil
    end

    updateLinkStatus()
    updateMutedStatus()

    local idx = findIndex(id)
    if not idx then
        log.wf("unable to match %s to an element index for callback", tostring(id))
        return
    end

    if m == "mouseEnter" then
        remote[idx].fillColor.alpha = 0.75
        if idx > 1 and showTooltips then
            tooltipTimer = timer.doAfter(tooltipDelay, function()
                local txt = remote[idx].id
                local size = remote:minimumTextSize(tooltipIndex + 1, txt)
                local remoteSize = remote:size()
                local xOffset = math.max(0, x + size.w + 4 - remoteSize.w)
                local baseFrame = { x = x - xOffset, y = y - (size.h + 4), h = size.h + 4, w = size.w + 4 }
                if baseFrame.x < 0 then
                    baseFrame.h = baseFrame.h + size.h
                    baseFrame.w = remoteSize.w
                    baseFrame.x = 0
                end
                if baseFrame.y + baseFrame.h > remoteSize.h then
                    baseFrame.y = baseFrame.y + baseFrame.h - remoteSize.h
                end
                if baseFrame.y < 0 then baseFrame.y = 0 end
                remote[tooltipIndex].frame = baseFrame
                baseFrame.x = baseFrame.x + 2
                baseFrame.y = baseFrame.y + 2
                baseFrame.w = baseFrame.w - 4
                baseFrame.h = baseFrame.h - 4
                remote[tooltipIndex + 1].frame = baseFrame

                remote[tooltipIndex + 1].text   = txt
                remote[tooltipIndex].action     = "fill"
                remote[tooltipIndex + 1].action = "stroke"
                tooltipTimer = nil
            end)
        end
    elseif m == "mouseExit" then
        -- don't reset background alpha if exit is because we entered a button
        if id == "remoteBackground" then
            -- but dim it if we leave the remote entirely
            if not geometry.inside({ x = x, y = y }, remote[idx].frame_raw) then
                remote[idx].fillColor.alpha = 0.25
            end
        else
            remote[idx].fillColor.alpha = 0.0
        end
    elseif m == "mouseDown" then
        remote[idx].fillColor.alpha = 0.95
        if labelDownFN[id] then
            labelDownFN[id](c, m, id, x, y)
        end
    elseif m == "mouseUp" then
        remote[idx].fillColor.alpha = 0.75
        if labelUpFN[id] then
            labelUpFN[id](c, m, id, x, y)
        elseif module.KODI and module.KODI:isRunning() and not labelDownFN[id] then
            module.KODI(id)
        end
    else
        log.wf("unrecognized message %s", m)
    end
    updateVisibility()
end

remote:mouseCallback(mouseCallback)

local mimicCallback = function(id, m)
    local idx = findIndex(id)
    if not idx then
        log.wf("unable to match %s to an element index for callback", tostring(id))
        return
    end
    local frame = remote[idx].frame_raw
    local x, y = frame.x + frame.w / 2, frame.y + frame.h / 2
    mouseCallback(remote, m, id, x, y)
    if m == "mouseUp" then
        mouseCallback(remote, "mouseExit", id, x, y)
    end
end

-- anytime a KODI instance is assigned, run a timer to update the link status and muted
-- displays
module = setmetatable(module, {
    __index = function(_, key)
        if key == "KODI" then
            return attachedKODI
        end
    end,
    __newindex = function(_, key, value)
        if key == "KODI" then
            attachedKODI = value
            remote[linkStatusIndex].fillColor = { red = 1 }
            remote[volumeIndicatorIndex].text = volumeIndicatorMuted[true]
            timer.waitUntil(function()
                return module.KODI and module.KODI:isRunning()
            end, function(...)
                updateLinkStatus()
                updateMutedStatus()
            end, .5)
        else
            rawset(_, key, value)
        end
    end
})

module.log = log
module.remote = remote

module.KODI = kodi.KODI

module.modalKeys = hotkey.modal.new()

module.modalKeys.entered = function(self)
    keysEnabled = true
--     log.d("enabling key equivalents")
end

module.modalKeys:bind({}, "left",   function() mimicCallback("Input.Left", "mouseDown") end,
                                    function() mimicCallback("Input.Left", "mouseUp") end,
                                    function() mimicCallback("Input.Left", "mouseDown") end)
module.modalKeys:bind({}, "right",  function() mimicCallback("Input.Right", "mouseDown") end,
                                    function() mimicCallback("Input.Right", "mouseUp") end,
                                    function() mimicCallback("Input.Right", "mouseDown") end)
module.modalKeys:bind({}, "up",     function() mimicCallback("Input.Up", "mouseDown") end,
                                    function() mimicCallback("Input.Up", "mouseUp") end,
                                    function() mimicCallback("Input.Up", "mouseDown") end)
module.modalKeys:bind({}, "down",   function() mimicCallback("Input.Down", "mouseDown") end,
                                    function() mimicCallback("Input.Down", "mouseUp") end,
                                    function() mimicCallback("Input.Down", "mouseDown") end)
module.modalKeys:bind({}, "escape", function() mimicCallback("Input.Back", "mouseDown") end,
                                    function() mimicCallback("Input.Back", "mouseUp") end)
module.modalKeys:bind({}, "return", function() mimicCallback("Input.Select", "mouseDown") end,
                                    function() mimicCallback("Input.Select", "mouseUp") end)
module.modalKeys:bind({}, "space",  function() mimicCallback("Player.PlayPause", "mouseDown") end,
                                    function() mimicCallback("Player.PlayPause", "mouseUp") end)

module.modalKeys:bind({"cmd"}, "left",
              function() mimicCallback("Player.SetSpeed.decrement", "mouseDown") end,
              function() mimicCallback("Player.SetSpeed.decrement", "mouseUp") end)
module.modalKeys:bind({"cmd"}, "right",
              function() mimicCallback("Player.SetSpeed.increment", "mouseDown") end,
              function() mimicCallback("Player.SetSpeed.increment", "mouseUp") end)

module.modalKeys.exited = function(self)
    keysEnabled = false
--     log.d("disabling key equivalents")
end

module.show = function()
    -- force display when explicitly shown to make it easier to find
    for i = 2, #remote, 1 do
        remote[i].action = standardActions[i]
    end
    remote:show()
    isVisible = true
end

module.hide = function()
--     if keysEnabled then module.modalKeys:exit() end
    if tooltipTimer then
        tooltipTimer:stop()
        tooltipTimer = nil
    end
    remote:hide()
    isVisible = false
end

module.toggle = function()
    if remote:isShowing() then
        module.hide()
    else
        module.show()
    end
end

module.topLeft = function(point)
    if point then
        if type(point) == "table" and type(point.x) == "number" and type(point.y) == "number" then
            remote:topLeft(point)
            settings.set(USERDATA_TAG .. ".topLeft", point)
        else
            error("point must be a table with an x and y key", 2)
        end
    end
    return remote:topLeft()
end

module.autosave = function(state)
    if type(state) == "boolean" then
        autosave = state
        settings.set(USERDATA_TAG .. ".autosave", state)
        if autosave then
            settings.set(USERDATA_TAG .. ".topLeft", remote:topLeft())
        end
    end
    return autosave
end

module.startVisible = function(state)
    if type(state) == "boolean" then
        startVisible = state
        settings.set(USERDATA_TAG .. ".startVisible", state)
    end
    return startVisible
end

module.autodim = function(state)
    if type(state) == "boolean" then
        autodim = state
        settings.set(USERDATA_TAG .. ".autodim", state)
        updateVisibility()
    end
    return autodim
end

module.keyEquivalents = function(state)
    if type(state) == "boolean" then
        keyEquivalents = state
        settings.set(USERDATA_TAG .. ".keyEquivalents", state)
        updateVisibility()
    end
    return keyEquivalents
end

module.showTooltips = function(state)
    if type(state) == "boolean" then
        showTooltips = state
        settings.set(USERDATA_TAG .. ".showTooltips", state)
    end
    return showTooltips
end

module._sleepWatcher = caffeinate.watcher.new(function(state)
    if state == caffeinate.watcher.systemWillSleep then
        if keysEnabled then module.modalKeys:exit() end
    end
end):start()

if startVisible then remote:show() end

return module
