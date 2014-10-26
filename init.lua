require = require("utils.require")
require.update_require_paths("In Home", {
    os.getenv("HOME").."/.hammerspoon/?.lua;"..
    os.getenv("HOME").."/.hammerspoon/?/init.lua",
    os.getenv("HOME").."/.hammerspoon/?.so"}, false)
require.update_require_paths("Luarocks", "luarocks path", true)

for i,v in pairs(require.require_dir("hs", true)) do hs[i] = v end
if hs.screen then hs.screen.watcher = require("hs.screen.watcher") end

inspect = require("inspect")
hs.ipc.cli_install("/opt/amagill")

hs._ = { _ = package.loaded, exec = require("hs.extras").exec }
hs._._actions, hs._._keys = {}, {}
for i,v in pairs(require.require_dir("utils._keys", true)) do
    hs._._keys[i] = v or true
end
for i,v in pairs(require.require_dir("utils._actions", true)) do
    hs._._actions[i] = v or true
end

print("Running: "..hs.extras._paths().bundlePath)

-- _G["debug.docs.module"] = "sort"
doc = hs.doc.from_json_file(hs.docstrings_json_file)
_doc = hs.doc.from_package_loaded(true)

