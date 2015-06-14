local R, M = pcall(require,"hs._asm.hotkey")
if R then
    print("**** Replacing internal hs.hotkey with experimental module.")
    hs.hotkey = M
end

-- Set to True or False indicating if you want a crash report when lua is invoked on  threads other than main (0) -- this should not happen, as lua is only supposed to execute in the main thread (unsupported and scary things can happen otherwise).  There is a performance hit, though, since the debug hook will be invoked for every call to a lua function, so usually this should be enabled only when testing in-development modules.

hs.settings.set("_asm.crashIfNotMain", false)


require = require("utils.require")
require.update_require_paths("In Home", {
    os.getenv("HOME").."/.hammerspoon/?.lua;"..
    os.getenv("HOME").."/.hammerspoon/?/init.lua",
    os.getenv("HOME").."/.hammerspoon/?.so"}, false)
require.update_require_paths("Luarocks", "luarocks path", true)

inspect = hs.inspect
inspect1 = function(what) return inspect(what, {depth=1}) end

hs.ipc.cliInstall("/opt/amagill")

-- What can I say? I like the original Hydra's console documentation style,
-- rather than help("...")
doc = require("utils.docs")


-- For my convenience while testing and screwing around...
-- If something grows into usefulness, I'll modularize it.
_asm = {
    _ = package.loaded,
    extras = require("hs._asm.extras"),
    _keys = require.require_path("utils._keys", false),
    _actions = require.require_path("utils._actions", false),
    _menus = require.require_path("utils._menus", false),
    _doc = "use _asm._doc_load() to load docs corrosponding to package.loaded.",
    _doc_load = function() _asm._doc = hs.doc.fromPackageLoaded() end,
}

hs.hints.style = "vimperator"

print("Running: ".._asm.extras._paths.bundlePath)
print("Accessibility: "..tostring(_asm.extras.accessibility(true)))

