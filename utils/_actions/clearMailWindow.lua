local appwatch  = require("hs.application").watcher

local mailWatcher
mailWatcher = appwatch.new(function(name,event,hsapp)
        if name then
            if name == "Mail" and event == appwatch.deactivated then
                local mailWindows = hsapp:allWindows()
                if #mailWindows == 1 and mailWindows[1]:title() == "Unread (0 messages)" then
                    mailWindows[1]:close()
                end
            end
        end
        mailWatcher:start() -- we die every so often for some reason...
    end
):start()

return mailWatcher
