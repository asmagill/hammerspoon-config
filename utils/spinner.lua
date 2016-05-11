local module = {}

local screen  = require"hs.screen"
local drawing = require"hs.drawing"
local timer   = require"hs.timer"
local fnutils = require"hs.fnutils"

local spinnerMetaTable -- forward declaration

local doAction = function(self)
    local _internals = spinnerMetaTable._internals[self]
    local _variables = spinnerMetaTable._variables[self]

    local radians = math.pi * _internals.angle / 180.0
    local sin = math.sin(radians)
    local cos = math.cos(radians)

    local d = drawing.line({
                              x = _internals.center.x + _internals.startHypot * cos,
                              y = _internals.center.y + _internals.startHypot * sin,
                          }, {
                              x = _internals.center.x + _internals.endHypot * cos,
                              y = _internals.center.y + _internals.endHypot * sin,
                          })
                          :setStrokeColor(_variables.color)
                          :setStrokeWidth(2)
                          :show()

    _internals.angle = _internals.angle + _variables.increment
    table.insert(_internals.drawings, 1, d)
    while(#_internals.drawings > _variables.persist) do
        local d2 = table.remove(_internals.drawings)
        d2:delete()
    end
end

local recalcInternals = function(self)
    local _internals = spinnerMetaTable._internals[self]
    local _variables = spinnerMetaTable._variables[self]

    _internals.lineStart = { x = _variables.size / 2, y = 0 }
    _internals.lineEnd   = { x = _variables.size,     y = 0 }

    _internals.startHypot = math.sqrt(_internals.lineStart.x ^ 2 + _internals.lineStart.y ^ 2)
    _internals.endHypot   = math.sqrt(_internals.lineEnd.x ^ 2   + _internals.lineEnd.y ^ 2)

    _internals.center = {
        x = _variables.topLeft.x + _variables.size / 2,
        y = _variables.topLeft.y + _variables.size / 2
    }

    if _internals.drawings and _internals.reset then
        fnutils.map(_internals.drawings, function(d) d:delete() end)
        _internals.drawings = {}
    end

    if not _internals.angle then _internals.angle = 0 end
    if not _internals.drawings then _internals.drawings = {} end
end

spinnerMetaTable = {
    _variables = setmetatable({}, { __mode = "k" }),
    _internals = setmetatable({}, { __mode = "k" }),
    _methods = {
        start = function(self)
            local _internals = spinnerMetaTable._internals[self]
            local _variables = spinnerMetaTable._variables[self]
            if not _internals.timer then
                _internals.timer = timer.doEvery(_variables.delay, function() doAction(self) end)
            end
            return self
        end,
        stop = function(self)
            local _internals = spinnerMetaTable._internals[self]
            if _internals.timer then
                _internals.timer:stop()
                _internals.timer = nil
                fnutils.map(_internals.drawings, function(d) d:delete() end)
                _internals.drawings = {}
            end
            return self
        end,
        __gc = function(self)
            self:stop()
        end,
    },

    __index = function(self, index)
        local _variables = spinnerMetaTable._variables[self]
        return spinnerMetaTable._methods[index] or _variables[index]
    end,
    __newindex = function(self, index, value)
        local _variables = spinnerMetaTable._variables[self]
        local _internals = spinnerMetaTable._internals[self]
        if _variables[index] then
            _internals.reset = (index == "topLeft" or index == "size")
            _variables[index] = value
            recalcInternals(self)
        end
    end,
    __pairs = function(self)
        local _variables = spinnerMetaTable._variables[self]
        return function(_, k)
            local v
            k, v = next(_variables, k)
            return k, v
        end, self, nil

    end,
    __tostring = function(self)
        local _internals = spinnerMetaTable._internals[self]
        local _variables = spinnerMetaTable._variables[self]
        return string.format("spinner at (%d, %d), %s", _variables.topLeft.x, _variables.topLeft.y, (_internals.timer and "running" or "stopped"))
    end,
}

module.new = function()
    local spinner = {}
    local screenFrame = screen.mainScreen():fullFrame()
    local defaultSize = 50

    spinnerMetaTable._variables[spinner] = {
        topLeft   = {
            x = screenFrame.x + (screenFrame.w - defaultSize) / 2,
            y = screenFrame.y + (screenFrame.h - defaultSize) / 2,
        },
        size      = defaultSize,
        delay     = 0.01,
        persist   = 20,
        increment = 10,
        color     = { red = .5, blue = .5, green = .5, alpha = .75 },
    }
    spinnerMetaTable._internals[spinner] = {}

    spinner = setmetatable(spinner, spinnerMetaTable)
    recalcInternals(spinner)
    return spinner
end

return module
