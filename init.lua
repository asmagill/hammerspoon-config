require = require("utils.require")
require.update_require_paths("In Home", {
    os.getenv("HOME").."/.hammerspoon/?.lua;"..
    os.getenv("HOME").."/.hammerspoon/?/init.lua",
    os.getenv("HOME").."/.hammerspoon/?.so"}, false)
require.update_require_paths("Luarocks", "luarocks path", true)

hs.extras = require("hs.extras")

inspect = hs.inspect
inspect1 = function(what) return inspect(what, {depth=1}) end

hs.ipc.cliInstall("/opt/amagill")

if hs.fnutils and hs.extras then
    hs.fnutils.every = hs.extras.fnutils_every
    hs.fnutils.some  = hs.extras.fnutils_some
end

-- What can I say? I like the original Hydra's console documentation style,
-- rather than help("...")
-- _G["debug.docs.module"] = "sort"
doc = hs.doc.fromJSONFile(hs.docstrings_json_file)

-- For my convenience while testing and screwing around...
-- If something grows into usefulness, I'll modularize it.
_asm = {
    _ = package.loaded,
    exec = hs.extras.exec,
    _keys = require.require_path("utils._keys", false),
    _actions = require.require_path("utils._actions", false),
    _restart = function()
        os.execute("(sleep 2 ; open -a "..hs.extras._paths.bundlePath..") &")
        hs._exit()
    end,
    _doc = "use _asm._doc_load() to load docs corrosponding to package.loaded.",
    _doc_load = function() _asm._doc = hs.doc.fromPackageLoaded() end,
}

print("Running: "..hs.extras._paths.bundlePath)

