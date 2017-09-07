local touchdevice = require("hs._asm.undocumented.touchdevice")
local canvas      = require("hs.canvas")
local eventtap    = require("hs.eventtap")
local mouse       = require("hs.mouse")
local events      = eventtap.event.types

local module = {}

-- eventtap can prevent mouseDown/Up but it can't prevent mouseMove

