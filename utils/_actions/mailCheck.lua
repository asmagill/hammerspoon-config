local task    = require("hs.task")
local fnutils = require("hs.fnutils")
local inspect = require("hs.inspect")
local stext   = require("hs.styledtext")
local timer   = require("hs.timer")

local credentialFiles = {
    iCloud = "/Users/amagill/.imaputilsrc-icloud",
    Gmail  = "/Users/amagill/.imaputilsrc-gmail",
}

local imaputilsPath  = "/Users/amagill/bin/imaputils.pl"
local lastStringUpdate = -1

local module = {}

local envVarsToAdd =  {
    PERL5LIB            = [[/opt/amagill/perl/lib/perl5]],
    PERL_MB_OPT         = [[--install_base "/opt/amagill/perl]],
    PERL_LOCAL_LIB_ROOT = [[/opt/amagill/perl]],
    PERL_MM_OPT         = [[INSTALL_BASE=/opt/amagill/perl]],
}

local updateEnvironment = function(task, vars)
    local envVars = task:environment()
    for k,v in pairs(vars) do envVars[k] = v end
    return task:setEnvironment(envVars)
end

module.tasks, module.boxes, module.lastCheck = {}, {}, {}
for k,v in pairs(credentialFiles) do
    module.tasks[k], module.boxes[k], module.lastCheck[k] = {}, {}, 0
end
local getCounts
local getBoxes = function(account)
    local theTask = table.insert(module.tasks[account], updateEnvironment(task.new(imaputilsPath,
        function(c, o, e)
            if c == 0 or c == 1 then
                local t = fnutils.split(o, "%s*[\r\n]%s*")
                table.remove(t, 1)
                table.remove(t, #t)
                getCounts(account, table.concat(t,",")
                                          :gsub("^'",""):gsub("','",","):gsub("'$",""))
            else
                error("Error getting mailbox list for "..account..": "..inspect({ c, o, e }))
            end
        end,
        {
            "--config", credentialFiles[account], "--mailboxes"
        }
    ), envVarsToAdd):start())
end

local cleanup
getCounts = function(account, listAsString)
    table.insert(module.tasks[account], updateEnvironment(task.new(imaputilsPath,
        function(c, o, e)
            if c == 0 then
                local results, total = {}, 0
                for count,name in o:gmatch("(%d+) messages found in '([^\r\n]+)'") do
                    results[name] = tonumber(count) or 0
                end
                cleanup(account, results)
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
    ), envVarsToAdd):start())
end

cleanup = function(account, results)
    module.boxes[account] = results
    for i,v in ipairs(module.tasks[account]) do
        if v:isRunning() then v:terminate() end -- should never happen, but lets be safe
    end
    module.tasks[account], module.lastCheck[account] = {}, os.time()
end

module.checkForNewMail = function()
    for k,v in pairs(credentialFiles) do
        if #module.tasks[k] == 0 then
            getBoxes(k)
        else
            print("still waiting on "..k.." from last check")
        end
    end
end

module.textStyle = {
                      font =  { name = "Menlo", size = 12 },
                      color = { alpha = 1.0 },
                      paragraphStyle = { lineBreak = "clip" },
}
module.textStyleHaveMail = {
                      font = stext.convertFont(module.textStyle.font, stext.fontTraits.italicFont),
                      color =  { list = "x11", name = "mediumspringgreen" },
}

module.outputLine = function()
    local newString = false
    for k,v in pairs(module.lastCheck) do
        if v > lastStringUpdate then newString = true end
    end
    if newString then
        module.styledOutput = stext.new("")
        for k,v in fnutils.sortByKeys(module.boxes, function(a,b) return a > b end) do
            local boxCount, totalCount = 0, 0
            for a,b in pairs(v) do
                if a ~= "Deleted Messages" then
                    boxCount = boxCount + 1
                    totalCount = totalCount + b
                end
            end
            module.styledOutput = module.styledOutput..stext.new(k..": ",
                                  (totalCount > 0) and module.textStyleHaveMail or module.textStyle)
            module.styledOutput = module.styledOutput..stext.new(totalCount.." message(s) in "
                                  ..boxCount.." folder(s)\n", module.textStyle)
        end

        lastStringUpdate = os.time()
    end
    return module.styledOutput
end

module.checkForNewMail()

module.timer = timer.new(180, function()
    module.checkForNewMail()
end):start()

return setmetatable(module, {
    __gc = function(_)
        for k,v in pairs(module.tasks) do
            for i,e in ipairs(v) do
                if e:isRunning() then e:terminate() end
            end
            if _.timer:running() then _.timer:stop() end
        end
    end
})
