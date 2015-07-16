local module = {
--[=[
    _NAME        = 'autoQuitter.lua',
    _VERSION     = 'the 1st digit of Pi/0',
    _URL         = 'https://github.com/asmagill/hammerspoon-config',
    _LICENSE     = [[ See README.md ]]
    _DESCRIPTION = [[

        Auto quit applications with no windows

    ]],
--]=]
}

local timer       = require("hs.timer")
local application = require("hs.application")
local window      = require("hs.window")
local fnutils     = require("hs.fnutils")

local __tostring_for_tables = function(self)
    local result = ""
    local width = 0
    for i,v in fnutils.sortByKeys(self) do
        if type(i) == "string" and width < i:len() then width = i:len() end
    end
    for i,v in fnutils.sortByKeys(self) do
        if type(i) == "string" then
            result = result..string.format("%-"..tostring(width).."s %s\n", i, tostring(v))
        end
    end
    return result
end

local __tostring_for_arrays = function(self)
    local result = ""
    local width = 0
    for i,v in fnutils.sortByKeyValues(self) do result = result..tostring(v).."\n" end
    return result
end

-- private variables and methods -----------------------------------------

-- permissiveMode -- a flag indicating whether we only exit apps which
--    are listed in blacklist, or if we're aggressive and close any not
--    in whitelist
local permissiveMode = true

-- Applications which are allowed to have 0 windows open
local whiteList   = setmetatable({}, { __tostring = __tostring_for_arrays })

-- Applications which are not allowed to have 0 windows open, even if
-- we're in permissive mode
local blackList   = setmetatable({}, { __tostring = __tostring_for_arrays })

local beenWarned = {}

local autoQuitWatcher = timer.new(60, function()
    fnutils.map(application.runningApplications(),
        function(app)
            if app:title() == nil then
                print("+++ "..os.date("%Y/%m/%d %H:%M:%S").." autoQuitter nil app title?")
            else
                if #app:allWindows() == 0 then
                    if app:title() ~= "Hammerspoon" then
                        if not fnutils.contains(whiteList, app:title()) and app:kind() > 0 then
                            if permissiveMode and not fnutils.contains(blackList, app:title()) then
                                if not beenWarned[app:title()] then
                                    beenWarned[app:title()] = os.time()
                                    print("+++ "..os.date("%Y/%m/%d %H:%M:%S").." autoQuitter detected "..app:title().." in permissive mode.")
                                end
                            else
                                print("+++ "..os.date("%Y/%m/%d %H:%M:%S").." autoQuitter quitting "..app:title())
                                app:kill()
                            end
                        end
                    end
                end

                for i,v in pairs(beenWarned) do
                    if (os.time() - v) > 3600 then beenWarned[i] = nil end
                end
            end
        end)
end)

-- Public interface ------------------------------------------------------

module.listCandidates = function(onlyUnknowns)
    onlyUnknowns = onlyUnknowns or false
    local results = {}
    fnutils.map(application.runningApplications(),
        function(app)
            if #app:allWindows() == 0 then
                if not fnutils.contains(whiteList, app:title()) and app:kind() > 0 then
                    if not (onlyUnknowns and fnutils.contains(blackList, app:title())) then
                        results[app:title()] = app:bundleID() or "-- no bundle identifier --"
                    end
                end
            end
        end)

    return setmetatable(results, { __tostring = __tostring_for_tables })
end

module.whiteList = function(app)
    if not app then
        return whiteList
    end

    if app:match("%.") then
        if application.applicationsForBundleID(app) then
            app = application.applicationsForBundleID(app)[1]:title()
        end
    end

    if fnutils.contains(whiteList, app) then
        table.remove(whiteList, fnutils.indexOf(whitelist, app))
    else
        table.insert(whiteList, app)
    end

    return fnutils.contains(whiteList, app)
end

module.blackList = function(app)
    if not app then
        return blackList
    end

    if app:match("%.") then
        if application.applicationsForBundleID(app) then
            app = application.applicationsForBundleID(app)[1]:title()
        end
    end

    if fnutils.contains(blackList, app) then
        table.remove(blackList, fnutils.indexOf(blackList, app))
    else
        table.insert(blackList, app)
    end

    return fnutils.contains(blackList, app)
end

module.aggressive = function(state)
    if type(state) == "boolean" then
        permissiveMode = not state
    end

    return not permissiveMode
end

module.permissive = function(state)
    if type(state) == "boolean" then
        permissiveMode = state
    end

    return permissiveMode
end

module.enable = function()
    return autoQuitWatcher:start()
end

module.disable = function()
    return autoQuitWatcher:stop()
end

-- Return Module Object --------------------------------------------------

return module
