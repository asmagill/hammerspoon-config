local application = require "hs.application"
application.launchOrFocusByBundleID("com.ZeroBrane.ZeroBraneStudio")

local ZBS = "/Applications/_ASM_/Developer/ZeroBraneStudio.app/Contents/ZeroBraneStudio"
package.path = package.path .. ";" .. ZBS .. "/lualibs/?/?.lua;" .. ZBS .. "/lualibs/?.lua"
package.cpath = package.cpath .. ";" .. ZBS .. "/bin/?.dylib;" .. ZBS .. "/bin/clibs53/?.dylib"
hs.mobdebug       = require "mobdebug"

local timer       = require "hs.timer"

local waitCount = 0
timer.waitUntil(function()
    local proceed = false
    for i, v in ipairs(application.runningApplications()) do
        proceed = v:bundleID() == "com.ZeroBrane.ZeroBraneStudio"
        if proceed then break end
    end
    waitCount = waitCount + 1
    if waitCount > 10 then
        print("~~ application launch timeout")
        proceed = true
    end
    return proceed
end, function(t)
    hs.mobdebug.start()
end)

return hs.mobdebug
