
-- requires hs._asm.canvas and hs._asm.kodi
-- still very experimental
-- may be added to kodi module or provided as example, not sure yet...

local module = {}
local USERDATA_TAG = "kodiRemote"

local kodi     = require("hs._asm.kodi")
local canvas   = require("hs._asm.canvas")
local logger   = require("hs.logger")
local settings = require("hs.settings")
local stext    = require("hs.styledtext")
local menu     = require("hs.menubar")
local eventtap = require("hs.eventtap")
local mouse    = require("hs.mouse")
local geometry = require("hs.geometry")

local events   = eventtap.event.types

local remoteTopLeft = settings.get(USERDATA_TAG .. ".topLeft") or { x = 100, y = 100 }
local autosave      = settings.get(USERDATA_TAG .. ".autosave") or false
local startVisible  = settings.get(USERDATA_TAG .. ".startVisible") or false

local log  = logger.new(USERDATA_TAG, settings.get(USERDATA_TAG .. ".logLevel") or "warning")

local remoteFrame = { x = remoteTopLeft.x, y = remoteTopLeft.y, h = 200, w = 150 }
local dialFrame   = { x = 25, y = 10, h = 100, w = 100 }

local remote = canvas.new(remoteFrame):level(canvas.windowLevels.popUpMenu)

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

local doCommandForPlayers = function(id, params)
    params = params or {}
    local oldplayerid = params.playerid
    if module.KODI and module.KODI:isRunning() then
        local players = module.KODI:submit("Player.GetActivePlayers")
        if players then
            for i, v in ipairs(players) do
                params.playerid = v.playerid
                module.KODI(id, params)
            end
        end
    end
    params.playerid = oldplayerid
end

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

}

local labelDownFN = {
    ["Input.ExecuteAction"] = function(c, m, id, x, y)
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

        menu.new(false):setMenu(menuList):popupMenu({ x = bounds.x, y = bounds.y + bounds.h })
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
            return false
        end):start()
    end,
}

local labelUpFN = {
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
}

remote[#remote + 1] = { id = "remoteBackground",
    type = "rectangle",
    action = "fill",
    roundedRectRadii = { xRadius = 10, yRadius = 10 },
    fillColor = { white = 0.4, alpha = 0.25 },
    trackMouseEnterExit = true,
}

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
        y = dialFrame.h + 40,
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
        y = dialFrame.h + 40,
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
        y = dialFrame.h + 40,
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
        y = dialFrame.h + 40,
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

local standardActions = {}
for i = 2, #remote, 1 do
    standardActions[i] = remote[i].action
    remote[i].action = "skip"
end

remote:mouseCallback(function(c, m, id, x, y)
    local idx = findIndex(id)
    if not idx then
        log.wf("unable to match %s to an element index for callback", tostring(id))
        return
    end
    if m == "mouseEnter" then
        remote[idx].fillColor.alpha = 0.75
        if id == "remoteBackground" then
            for i = 2, #remote, 1 do
                remote[i].action = standardActions[i]
            end
        end
    elseif m == "mouseExit" then
        if id == "remoteBackground" then
            if not geometry.inside({ x = x, y = y }, remote[idx].frame_raw) then
                for i = 2, #remote, 1 do
                    remote[i].action = "skip"
                end
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
        remote[idx].fillColor.alpha = 0.7
        if labelUpFN[id] then
            labelUpFN[id](c, m, id, x, y)
        elseif module.KODI and module.KODI:isRunning() and not labelDownFN[id] then
            module.KODI(id)
        end
    else
        log.wf("unrecognized message %s", m)
    end
end)

module.log = log
module.remote = remote

module.KODI = kodi.KODI

module.show = function()
    for i = 2, #remote, 1 do
        remote[i].action = standardActions[i]
    end
    remote:show()
end

module.hide = function()
    remote:hide()
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

if startVisible then remote:show() end
return module
