local module = {}

local switcher = require"hs.window.switcher"
local filter   = require"hs.window.filter"
local hotkey   = require"hs.hotkey"
local mods     = require"hs._asm.extras".mods

-- include minimized/hidden windows, current Space only
module.switcher = switcher.new(filter.new():setCurrentSpace(true):setDefaultFilter(), {
    selectedThumbnailSize = 384,
    thumbnailSize         = 96,
    showTitles            = false,
    textSize              = 12,

    textColor             = { 1.0, 1.0, 1.0, 0.75 },
    backgroundColor       = { 0.3, 0.3, 0.3, 0.75 },
    highlightColor        = { 0.8, 0.5, 0.0, 0.80 },
    titleBackgroundColor  = { 0.0, 0.0, 0.0, 0.75 },
})

-- bind to hotkeys; WARNING: at least one modifier key is required!
hotkey.bind(mods.cAsc, 'tab', function() module.switcher:next() end)
hotkey.bind(mods.cASc, 'tab', function() module.switcher:previous() end)

return module