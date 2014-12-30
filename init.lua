require = require("utils.require")
require.update_require_paths("In Home", {
    os.getenv("HOME").."/.hammerspoon/?.lua;"..
    os.getenv("HOME").."/.hammerspoon/?/init.lua",
    os.getenv("HOME").."/.hammerspoon/?.so"}, false)
require.update_require_paths("Luarocks", "luarocks path", true)

local extras = require("hs._asm.extras")

inspect = hs.inspect
inspect1 = function(what) return inspect(what, {depth=1}) end

hs.ipc.cliInstall("/opt/amagill")

if hs.fnutils and extras then
    hs.fnutils.every = extras.fnutils_every
    hs.fnutils.some  = extras.fnutils_some
end

-- What can I say? I like the original Hydra's console documentation style,
-- rather than help("...")
-- _G["debug.docs.module"] = "sort"
doc = hs.doc.fromJSONFile(hs.docstrings_json_file)

-- For my convenience while testing and screwing around...
-- If something grows into usefulness, I'll modularize it.
_asm = {
    _ = package.loaded,
    exec = extras.exec,
    _keys = require.require_path("utils._keys", false),
    _actions = require.require_path("utils._actions", false),
    _restart = function()
        os.execute("(sleep 2 ; open -a "..extras._paths.bundlePath..") &")
        hs._exit()
    end,
    _doc = "use _asm._doc_load() to load docs corrosponding to package.loaded.",
    _doc_load = function() _asm._doc = hs.doc.fromPackageLoaded() end,
}

print("Running: "..extras._paths.bundlePath)

