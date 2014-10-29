require = require("utils.require")
require.update_require_paths("In Home", {
    os.getenv("HOME").."/.hammerspoon/?.lua;"..
    os.getenv("HOME").."/.hammerspoon/?/init.lua",
    os.getenv("HOME").."/.hammerspoon/?.so"}, false)
require.update_require_paths("Luarocks", "luarocks path", true)

hs.extras = require("hs.extras")
inspect = require("inspect")
hs.ipc.cli_install("/opt/amagill")

if hs.fnutils and hs.extras then
    hs.fnutils.every = hs.extras.fnutils_every
    hs.fnutils.some  = hs.extras.fnutils_some
end

_asm = { _ = package.loaded, exec = require("hs.extras").exec }
_asm._actions, _asm._keys = {}, {}
for i,v in pairs(require.require_dir("utils._keys", false)) do
    _asm._keys[i] = v or true
end
for i,v in pairs(require.require_dir("utils._actions", false)) do
    _asm._actions[i] = v or true
end

print("Running: "..hs.extras._paths.bundlePath)

-- _G["debug.docs.module"] = "sort"
doc = hs.doc.from_json_file(hs.docstrings_json_file)
_doc = hs.doc.from_package_loaded(true)

