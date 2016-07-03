local module = {}


local metatable = {
    __self  = setmetatable({}, { __mode = "k" }),
    __trace = setmetatable({}, { __mode = "k" }),
}

metatable.__index = function(self, key)
    if metatable.__trace[self] then print("~~ index for ", tostring(key)) end
    return metatable.__self[self][key]
end

metatable.__newindex = function(self, key, value)
    if metatable.__trace[self] then print("~~ newindex for ", tostring(key), tostring(value)) end
    metatable.__self[self][key] = value
end

metatable.__len = function(self)
    if metatable.__trace[self] then print("~~ len") end
    return #metatable.__self[self]
end

metatable.__pairs = function(self)
    if metatable.__trace[self] then print("~~ pairs") end
    return function(_, k)
            if metatable.__trace[self] then print("~~ pairs.iterator for ", tostring(k)) end
            return next(_, k)
        end, metatable.__self[self], nil
end

module.new = function()
    local newTable = {}
    metatable.__self[newTable]  = {}
    metatable.__trace[newTable] = false
    return setmetatable(newTable, metatable)
end

module.trace = function(obj, value)
    if type(value) == "boolean" then
        metatable.__trace[obj] = value
    end
    return metatable.__trace[obj]
end

return module