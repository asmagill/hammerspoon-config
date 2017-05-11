local pathwatcher = require"hs.pathwatcher"
local inspect     = require"hs.inspect"

local module = {}

module.watcher = pathwatcher.new(hs.configdir, function(changedFiles, changedFlags)
    local luaFileFound = false
    for i = 1, #changedFiles, 1 do
        if changedFiles[i]:match("%.lua$") then
            hs.printf("\t%s — %s", (changedFiles[i]:gsub("^" .. hs.configdir, "…")), (inspect(changedFlags[i]):gsub(" = true", ""):gsub("%s+", " ")))
            luaFileFound = true
        end
    end
    if luaFileFound then
        print("\tyou might want to reload!")
    end
end):start ()

return module
