local crash = require("hs.crash")
local settings = require("hs.settings")

crash.crashLogToNSLog = true ;

if settings.get("_asm.crashIfNotMain") then
    local function crashifnotmain(reason)
        if not crash.isMainThread() then
            print("crashifnotmain called with reason", reason) -- may want to remove this, very verbose otherwise
            print("not in main thread, crashing")
            crash.crash()
        end
    end
    debug.sethook(crashifnotmain, 'c')
    return true
else
    return false
end

