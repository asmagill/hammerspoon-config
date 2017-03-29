--
-- Sample use of capturing Hammerspoon's stdout
--
-- (1) Save this code as "dumpStdout.lua" in ~/.hammerspoon/
-- (2) In the Hammerspoon console, type the following: dump = require("dumpStdout")
-- (3) In a terminal window, tyoe "tail -f ~/.hammerspoon/dump.txt"
--
-- Now, anything which is sent to Hammerspoon's stdout will be replicated with a timestamp
-- in the text file.  Currently this means anything which is printed to the Hammerspoon
-- console with the `print` command... this includes log messages handled with `hs.logger`
-- and at least some error messages, but I don't think all... a deeper investigation of
-- the Hammerspoon source is required to determine why the difference when I get the time.
--
-- You may need to wait a few seconds after printing something in the console (you can
-- speed this up a little with `io.output():flush()`) -- it's not quite immediate.  Not
-- sure why yet.
--
-- Note that some third party code doesn't seem to generate output via the print command
-- (the LuaRocks code itself is a good example).  Instead, they use something along the
-- lines of `io.output():write(...)` or something similar... this watcher will catch that
-- while the Hammerspoon console won't.
--
-- Note that because Hammerspoon *does* invoke the builtin `print` command as part of its
-- routines to replicate output to the console, I cannot stress enough that you should
-- **NEVER** use the `print` command in your callback... this will cause a death spiral
-- and you'll have to type `killall Hammerspoon` into a terminal window.

local module = {}
local consolepipe = require("hs._asm.consolepipe")
local timer       = require("hs.timer")

local err

local timestamp = function(date)
    date = date or timer.secondsSinceEpoch()
    return os.date("%F %T" .. string.format("%-5s", ((tostring(date):match("(%.%d+)$")) or "")), math.floor(date))
end

module.file, err = io.open("dump.txt", "w+")
if not module.file or err then error(err) end

module.replicator = consolepipe.new("stdout"):setCallback(function(stuff)
    if io.type(module.file) == "file" then
        local file, err = module.file:write(timestamp() .. ": " .. stuff)
        if not file or err then
            module.file:close()
            module.replicator:stop()
            error(err) -- do not throw until replicator is stopped
        end
    else
        module.replicator:stop()
        error("file handle not valid") -- do not throw until replicator is stopped
    end
end):start()

module.stop = function()
    module.replicator:stop()
    if io.type(module.file) == "file" then module.file:close() end
end

return module
