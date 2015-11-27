local task    = require("hs.task")
local fnutils = require("hs.fnutils")
local inspect = require("hs.inspect")

local credentialFiles = {
    iCloud = "/Users/amagill/.imaputilsrc-icloud",
    Gmail  = "/Users/amagill/.imaputilsrc-gmail",
}

local imaputilsPath  = "/Users/amagill/bin/imaputils.pl"

local module = {}

module.tasks, module.boxes, module.newCount, module.lastCheck = {}, {}, {}, {}
for k,v in pairs(credentialFiles) do
    module.tasks[k], module.boxes[k], module.newCount[k], module.lastCheck[k] =
        {}, {}, 0, 0
end

module.getBoxes = function(account)
    table.insert(module.tasks[account], task.new(imaputilsPath,
        function(c, o, e)
            if c == 0 or c == 1 then
                local t = fnutils.split(o, "%s*[\r\n]%s*")
                table.remove(t, 1)
                table.remove(t, #t)
                module.getCounts(account, table.concat(t,",")
                                          :gsub("^'",""):gsub("','",","):gsub("'$",""))
            else
                error("Error getting mailbox list for "..account..": "..inspect({ c, o, e }))
            end
        end,
        {
            "--config", credentialFiles[account], "--mailboxes"
        }
    ):start())
end

module.getCounts = function(account, listAsString)
    table.insert(module.tasks[account], task.new(imaputilsPath,
        function(c, o, e)
            if c == 0 then
                local results, total = {}, 0
                for count,name in o:gmatch("(%d+) messages found in '([^\r\n]+)'") do
                    results[name] = tonumber(count) or 0
                end
                module.cleanup(account, results)
            else
                error("Error getting new mail counts for "..account..": "..inspect({ c, o, e }))
            end
        end,
        {
            "--config", credentialFiles[account], "--count",
                                                  "--box", listAsString,
                                                  "--unseen",
                                                  "--sentsince", "0"
        }
    ):start())
end

module.cleanup = function(account, results)
    local numBoxes, newCount = 0, 0
    for k,v in pairs(results) do
        numBoxes, newCount = numBoxes + 1, newCount + v
    end
    module.boxes[account], module.newCount[account] = results, newCount
    for i,v in ipairs(module.tasks[account]) do
        if v:isRunning() then v:terminate() end -- should never happen, but lets be safe
    end
    module.tasks[account], module.lastCheck[account] = {}, os.time()

-- now whatever notifies the geeklet to display the results

    print(account..": "..newCount.." messages in "..numBoxes.." folders")
end

module.checkForNewMail = function()
    for k,v in pairs(credentialFiles) do
        if #module.tasks[k] == 0 then
            module.getBoxes(k)
        else
            print("still waiting on "..k.." from last check")
        end
    end
end

module.checkForNewMail()

return setmetatable(module, {
    __gc = function(_)
        for k,v in pairs(module.tasks) do
            for i,e in ipairs(module.tasks[k]) do
                if e:isRunning() then e:terminate() end
            end
        end
    end
})
