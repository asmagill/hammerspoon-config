local module = {}

local seen_GCs = {}

local __gc_replacement = function(modName, originalFN)
    seen_GCs[modName] = originalFN
    return function(...)
--         print("~~ " .. os.date("%Y-%m-%d %H:%M:%S") .. " : invoking " .. tostring(modName) .. ".__gc")
        print("~~ " .. timestamp() .. " : invoking " .. tostring(modName) .. ".__gc")
        originalFN(...)
    end
end

module.patch = function(k)
    local mt = hs.getObjectMetatable(k)
    if mt and mt.__name and not mt.__gc then
    -- does nothing because the object had no __gc, but we need something for this to work
        mt.__gc = function(self) end
    end
    if mt and type(mt.__gc) == "function" then
        if type(seen_GCs[k]) == "function" then
            print("~~ " .. tostring(k) .. " already patched")
        else
            seen_GCs[k] = mt.__gc
            print("~~ patching " .. tostring(k))
            mt.__gc = __gc_replacement(k, mt.__gc)
            return true
        end
    else
        print("~~ " .. tostring(k) .. " does not have a registered metatable with a __gc function")
    end
    return false
end

-- note this can make garbage collection *VERY* slow if you haven't previously ignored a lot of things.
-- better to call `patch` on the specific ones you want to watch
module.patchAll = function()
    for k, v in pairs(debug.getregistry()) do
        if type(v) == "table" then
            if type(v.__gc) == "function" and not seen_GCs[k] then
                module.patch(k)
            elseif type(seen_GCs[k]) == "boolean" then
                print("~~ skipping " .. tostring(k))
            end
        end
    end
end

module.revert = function(k)
    if type(seen_GCs[k]) == "function" then
        local mt = hs.getObjectMetatable(k)
        if mt then
            mt.__gc = seen_GCs[k]
            seen_GCs[k] = true
            print("~~ reverting " .. tostring(k))
            return true
        else
            print("~~ " .. tostring(k) .. " does not have a metatable")
        end
    else
        print("~~ " .. tostring(k) .. " is not patched")
    end
    return false
end

module.ignore = function(...)
    local args = table.pack(...)
    if type(args[1]) == "table" and args.n == 1 then
        args = args[1]
    end
    for i, v in ipairs(args) do
        if type(seen_GCs[v]) == "function" then
            module.revert(v)
        end
        print("~~ ignoring " .. tostring(v))
        seen_GCs[v] = true
    end
end

module.__originals = seen_GCs

return module
