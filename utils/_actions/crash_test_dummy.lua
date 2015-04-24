hs.crash.crashLogToNSLog = true ;

if hs.settings.get("_asm.crashIfNotMain") then
    local function crashifnotmain(reason)
        if not hs.crash.isMainThread() then
            print("crashifnotmain called with reason", reason) -- may want to remove this, very verbose otherwise
            print("not in main thread, crashing")
            hs.crash.crash()
        end
    end
    debug.sethook(crashifnotmain, 'c')
    return true
else
    return false
end

