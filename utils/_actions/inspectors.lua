local module = {}

inspect = require("hs.inspect")

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

module.help = function(...)
    local output = [[

This module creates some shortcuts for inspecting Lua data:

    inspect  - equivalent to `hs.inspect`

    inspectm - include options { metatables = 1} by default
    inspect1 - include options { depth = 1 } by default
    inspect2 - include options { depth = 2 } by default
    inspecta - includes process function in options table to remove `n` key from tables;
               this allows tables which contain non-numeric keys only because of
               table.pack to be treated as the arrays they really are.

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
