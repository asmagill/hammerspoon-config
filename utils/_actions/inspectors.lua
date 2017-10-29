local module = {}
local timer = require("hs.timer")

inspect = require("hs.inspect")

timestamp = function(date)
    date = date or timer.secondsSinceEpoch()
    return os.date("%F %T" .. string.format("%-5s", ((tostring(date):match("(%.%d+)$")) or "")), math.floor(date))
end

local inspectWrapper = function(what, how, actual)
    how = how or {}
    for k, v in pairs(how) do actual[k] = v end
    return inspect(what, actual)
end
inspectm = function(what, how) return inspectWrapper(what, how, { metatables = 1 }) end
inspect1 = function(what, how) return inspectWrapper(what, how, { depth = 1 }) end
inspect2 = function(what, how) return inspectWrapper(what, how, { depth = 2 }) end
inspecta = function(what, how) return inspectWrapper(what, how, {
    process = function(i,p) if p[#p] ~= "n" then return i end end
}) end

-- finspect = function(...)
--     local args = table.pack(...)
--     if args.n == 1 and type(args[1]) == "table" then
--         args = args[1]
--     else
--         args.n = nil -- supress the count from table.pack
--     end
--     return (inspect(args):gsub("%s+", " "))
-- end

finspect = function(...)
    local args = table.pack(...)
    if args.n == 1 and type(args[1]) == "table" then
        args = args[1]
    else
        args.n = nil -- supress the count from table.pack
    end

    -- causes issues with recursive calls to __tostring in inspect
    local mt = getmetatable(args)
    if mt then setmetatable(args, nil) end
    local answer = inspect(args, { newline = " ", indent = "" })
    if mt then setmetatable(args, mt) end
    return answer
end

minspect = function(stuff)
    return (inspect(stuff, { process = function(item, path)
        if path[#path] == inspect.KEY then return item end
        if path[#path] == inspect.METATABLE then return nil end
        if #path > 0 and type(item) == "table" then
            return finspect(item)
        else
            return item
        end
    end
    }):gsub("[\"']{", "{"):gsub("}[\"']", "}"))
end

finspect2 = function(what, ...)
    local fn, opt = inspect, {}
    for i,v in ipairs(table.pack(...)) do
        -- "inspect" is a table with a __call metamethod, so...
        local vType = (getmetatable(v) or {}).__call and "function" or type(v)
        if vType == "function" then fn = v end
        if vType == "table"    then opt = v end
    end
    return (fn(what, opt):gsub("%s+", " "))
end

module.help = function(...)
    local output = [[

This module creates some shortcuts for inspecting Lua data:

    inspect   - equivalent to `hs.inspect`

    inspectm  - include options { metatables = 1} by default
    inspect1  - include options { depth = 1 } by default
    inspect2  - include options { depth = 2 } by default
    inspecta  - includes process function in options table to remove `n` key from tables;
                this allows tables which contain non-numeric keys only because of
                table.pack to be treated as the arrays they really are.

    finspect(...) - inspects the arguments, first combining them into a table if more
                    then one or if the one provided is not already a table. Flattens
                    the output by replacing run-on spaces, tabs, and newlines into a
                    single space.

    finspect2(what, [fn], [opt]) - inspects `what` with the function `fn` (default is
                                   "inspect") with the specfied options (default {}) and
                                   "flattens" the output by replacing run-on spaces, tabs,
                                   and newlines into a single space.

    timestamp([number]) - returns the current or specified time as a string in the format
                          of 'YYYY-MM-DD hh:mm:ss.nnnn'

    Note that a second argument to any of the `inspect*` shortcuts is appended to the
    default table described; i.e. if you specify the same key in your options table,
    your value will override the default.

]]
    return output
end

module = setmetatable(module, {
    __tostring = function(self) return self.help() end,
    __call     = function(self, ...) return self.help(...) end,
})

return module
