local redshift = require("hs.redshift")
local hotkey   = require("hs.hotkey")
local mods     = require("hs._asm.extras").mods
local alert    = require("hs.alert")


redshift.start(2800,'21:00','7:00','4h',false,wfRedshift)

hotkey.bind(mods.Casc, "F11", function()
    alert("Toggle Invert")
    redshift.toggleInvert()
end)

hotkey.bind(mods.CAsc, "F11", function()
    alert("Toggle Redshift")
    redshift.toggle()
end)

return "⌘-F11 and ⌘⌥-F11"
