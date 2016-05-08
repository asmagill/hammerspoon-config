local module = {}

local escAppleScriptStr = function(text)
        local s = string.gsub(text, "\\", "\\\\")
        local s = string.gsub(s, '"', "\\\"")
        local s = string.gsub(s, "'", "\\'")
        return s
end

module.NASTimer = {}
module.NASDrives = {
    ['Home'] = {
        "afp://ASM APE._afpovertcp._tcp.local/Cortex"
    },
    ['Work'] = {
        "smb://latitude/wtps",
        "smb://latitude/amagill"
    }
}

module.mountNAS = function(id)
    if module.NASTimer[id] then
        local running = false
        for i = 1, #module.NASTimer[id] do
            if module.NASTimer[id][i] then
                -- utils.log(id .. " NAS are already being mounted")
                return
            end
        end
    end
    module.NASTimer[id] = {}
    for i = 1, #module.NASDrives[id] do
        module.NASTimer[id][i] = hs.timer.doEvery(10, function()
            local fullpath = module.NASDrives[id][i]
            -- utils.log("Attempting to mount " .. fullpath)
--             if not config.cachedNetwork or config.cachedNetwork ~= id then
--                 module.NASTimer[id][i]:stop()
--                 module.NASTimer[id][i] = nil
--                 return
--             end
            local shortvol = fullpath:match('^([^/]+://[^/]+/[^/]+)')
            print(shortvol)
            local _, res = hs.applescript.applescript([[
                tell application "Finder"
                    try
                        mount volume "]] .. escAppleScriptStr(shortvol) .. [["
                    on error
                        return 0
                    end try
                        return 1
                end tell
            ]])
            print(_, res)
            if res == 1 then
--                 os.execute("open " .. fullpath)
                module.NASTimer[id][i]:stop()
                module.NASTimer[id][i] = nil
                return
            end
            _, res = hs.applescript.applescript([[
                tell application "Finder"
                    try
                        if (disk "]] .. escAppleScriptStr(shortvol:match('([^/]+)$')) .. [[" exists) then
                            return 1
                        end
                    end try
                    return 0
                end tell
            ]])
            print(_, res)
            if res == 1 then
--                 os.execute("open " .. fullpath)
                module.NASTimer[id][i]:stop()
                module.NASTimer[id][i] = nil
                return
            end
        end)
    end
end

return module