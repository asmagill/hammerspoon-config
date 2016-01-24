local s = require("hs._asm.service")
local p = require("hs.pasteboard")

local runstring = function(s)
    local fn, err = load("return " .. s)
    if not fn then fn, err = load(s) end
    if not fn then return tostring(err) end

    local str = ""
    local results = pack(xpcall(fn,debug.traceback))
    for i = 2,results.n do
      if i > 2 then str = str .. "\t" end
      str = str .. tostring(results[i])
    end
    return str
end

serviceRunString = s.new("HSRunStringService"):setCallback(function(pboardName)
    local goodType = false
    for i,v in ipairs(p.contentTypes(pboardName)) do
        if v == "public.utf8-plain-text" then
            goodType = true
            break
        end
    end
    if not goodType then
        return "pasteboard does not contain text"
    end
    print(pboardName, c)
    local c = hs.pasteboard.getContents(pboardName)
    local r = runstring(c)
    if r == nil then
        return "runstring returned nil"
    end
    if r == "testError" then
        return "testError Hooray!"
    end
    p.clearContents(pboardName)
    p.setContents(r, pboardName)
    return true
end)


-- 1+10
