local f = io.open("/usr/share/dict/words", "r")
local a = f:read("a")
f:close()
local module = {}

local fnutils = require("hs.fnutils")
module.words = fnutils.split(a, "[\r\n]")
module.random = function(count)
    count = tonumber(count) or 1
    local someWords = {}
    for i = 1, count, 1 do
        table.insert(someWords, module.words[math.random(1,#module.words)])
    end
    return table.concat(someWords, " ")
end

return module