-- Keeps an up-to-date list of alternate names for applications

local spotlight = require("hs.spotlight")
local module = {}

local nameMap = {}

local modifyNameMap = function(info, add)
    for _, item in ipairs(info) do
        local applicationName = item.kMDItemFSName
        for __, alt in ipairs(item.kMDItemAlternateNames or {}) do
            nameMap[alt:match("^(.*)%.app$") or alt] = add and applicationName or nil
        end
    end
end

local updateNameMap = function(obj, msg, info)
    if info then
        -- all three can occur in either message, so check them all!
        if info.kMDQueryUpdateAddedItems   then modifyNameMap(info.kMDQueryUpdateAddedItems,   true)  end
        if info.kMDQueryUpdateChangedItems then modifyNameMap(info.kMDQueryUpdateChangedItems, true)  end
        if info.kMDQueryUpdateRemovedItems then modifyNameMap(info.kMDQueryUpdateRemovedItems, false) end
    else
        -- shouldn't happen for didUpdate or inProgress
        print("~~~ userInfo from SpotLight was empty for " .. msg)
    end
end

module.watcher = spotlight.new():queryString([[ kMDItemContentType = "com.apple.application-bundle" ]])
                                :callbackMessages("didUpdate", "inProgress")
                                :setCallback(updateNameMap)
                                :start()
module.nameMap = nameMap

module.realNameFor = function(value, exact)
    if type(value) ~= "string" then
        error('hint must be a string', 2)
    end
    if not exact then
        local results = {}
        for k, v in pairs(nameMap) do
            if k:lower():find(value:lower()) then
                -- I can foresee someday wanting to know how often a match was found, so make it a
                -- number rather than a boolean so I can cut & paste this
                results[v] = (results[v] or 0) + 1
            end
        end
        local returnedResults = {}
        for k,v in pairs(results) do
            table.insert(returnedResults, k:match("^(.*)%.app$") or k)
        end
        return table.unpack(returnedResults)
    else
        local realName = nameMap[value]
        -- hs.application functions/methods do not like the .app at the end of application
        -- bundles, so remove it.
        return realName and realName:match("^(.*)%.app$") or realName
    end
end

return module
