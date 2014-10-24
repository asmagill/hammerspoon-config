require = require("utils.require")
require.update_require_paths("In Home", {
    os.getenv("HOME").."/.hammerspoon/?.lua;"..
    os.getenv("HOME").."/.hammerspoon/?/init.lua",
    os.getenv("HOME").."/.hammerspoon/?.so"}, false)
require.update_require_paths("Luarocks", "luarocks path", true)

for i,v in pairs(require.require_dir("hs", true)) do hs[i] = v end
inspect = require("inspect")
require.require_dir("utils._keys", true)

_asm = {
    _ = package.loaded,
}

print("Running: "..hs.extras._paths().bundlePath)

-- _G["debug.docs.module"] = "sort"
doc = hs.doc.from_json_file(hs.docstrings_json_file)
_doc = hs.doc.from_package_loaded(true)

