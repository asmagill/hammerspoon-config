--
-- Simple web site watcher
--
-- Checks a site for updates by checking the Last-Modified header or a hash of the content body or both
--
-- Will likely cause a lot of false positives for dynamically generated pages
--
-- TODO: Consider options for checking if a certain percentage of the content has changed.. how?
--       Modifier startup timer stagger so calculates new start time based on last updated field? I restart HS *a lot* during development
--       Add reachability check so doesn't error when internet not present -- delay or just skip check (easier)?
--       Initial check in add to set watched fields so doesn't fire immediate notifications? or is that a decent initial spot check?

local module = {}

local USERDATA_TAG = "_asm.siteWatcher"

local settings = require("hs.settings")
local http     = require("hs.http")
local timer    = require("hs.timer")
local notify   = require("hs.notify")
local urlevent = require("hs.urlevent")
local hash     = require("hs.hash")
local fnutils  = require("hs.fnutils")
local inspect  = require("hs.inspect")

local _xtras
if package.searchpath("hs._asm.extras", package.path) then
  _xtras = require("hs._asm.extras")
end

local siteData         = settings.get(USERDATA_TAG .. ".siteData") or {}
local defaultCheckTime = settings.get(USERDATA_TAG .. ".defaultCheckTime") or 3600 * 8
local timers       = {}
local requests     = {}
local queryResults = {}

local checkSite = function(site)
    requests[site.url] = http.asyncGet(site.url, {}, function(status, body, header)
      queryResults[site.url] = { status, body, header }
        if status ~= 200 then
            notify.new(function() urlevent.openURL(site.url) end, {
                title           = site.url,
                subTitle        = "Response code: " .. tostring(status),
                informativeText = "Error checking site content",
            }):send()
        else
            local siteHash = hash.SHA512(body)
            local modified = header["Last-Modified"]
            local requiresUpdate = false
            if site.siteHash then
                if siteHash ~= site.siteHash then
                    notify.new(function() urlevent.openURL(site.url) end, {
                        title           = site.url,
                        subTitle        = header.Date,
                        informativeText = "Content hash value changed: " .. siteHash,
                    }):send()
                    site.siteHash = siteHash
                    requiresUpdate = true
                end
            end
            if site.modifiedTime then
                if modified ~= site.modifiedTime then
                    notify.new(function() urlevent.openURL(site.url) end, {
                        title           = site.url,
                        subTitle        = header.Date,
                        informativeText = "Last modified time changed: " .. modified,
                    }):send()
                    site.modifiedTime = modified
                    requiresUpdate = true
                end
            end
            if requiresUpdate then
                settings.set(USERDATA_TAG .. ".siteData", siteData)
            end
        end
        requests[site.url] = nil
        site.lastChecked = os.time()
    end)
end

-- stagger them a bit in case they're all using the same refresh interval
for k,v in pairs(siteData) do
    timers[k] = timer.doAfter(math.random(10) * 60, function()
        checkSite(v)
        timers[k] = timer.doEvery(v.checkInterval or defaultCheckTime, function() checkSite(v) end)
    end)
end

module._siteData     = siteData
module._timers       = timers
module._requests     = requests
module._queryResults = queryResults

module.add = function(site, watchModifiedTime, watchHash, checkInterval)
    if site == nil then
        print("Usage: add(site, watchModifiedTime, watchHash)")
        print("    site              - the URL to check")
        print("    watchModifiedTime - check the Last-Modified header (can be nil)")
        print("    watchHash         - check SHA512 hash value (can be nil)")
        print("    checkInterval     - defaults to " .. tostring(defaultCheckTime) .. " seconds")
        print("")
        print("If the site is already being watched, updates what is being checked")
        return
    end
    if siteData[site] then
        timers[site]:stop()
        timers[site] = nil
    else
        siteData[site] = { url = site }
    end
    siteData[site].modifiedTime  = watchModifiedTime and (siteData[site].modifiedTime or true) or nil
    siteData[site].siteHash      = watchHash         and (siteData[site].siteHash     or true) or nil
    siteData[site].checkInterval = checkInterval
    checkSite(siteData[site])
    timers[site] = timer.doEvery(site.checkInterval or defaultCheckTime, function() checkSite(siteData[site]) end)
    settings.set(USERDATA_TAG .. ".siteData", siteData)
end

module.list = function()
    for k,v in fnutils.sortByKeys(siteData) do
        print(k)
        print("    Last checked: " .. (v.lastChecked and os.date("%c", v.lastChecked) or "<pending>"))
        print("    HASH:         " .. (v.siteHash and tostring(v.siteHash) or "<not checking>"))
        print("    LastModified: " .. (v.modifiedTime and tostring(v.modifiedTime) or "<not checking>"))
        print("    Interval:     " .. tostring(v.checkInterval or defaultCheckTime) .. " seconds")
        print("    Timer:        " .. (timers[k] and ("next check in " .. tostring(math.floor(timers[k]:nextTrigger())) .. " secods") or "inactive -- this is an error"))
        print("    Request:      " .. (requests[k] and "in progress" or "idle"))
    end
end

module.remove = function(site)
    if siteData[site] then
        timers[site]:stop()
        timers[site] = nil
        settings.set(USERDATA_TAG .. ".siteData", siteData)
    else
        error("site not being watched", 2)
    end
end

module._sample = function(site, delay)
    print("Sampling; this may take a minute...")
    timer.doAfter(1, function()
        delay = delay or 5000000
        local s1, b1, h1 = http.get(site)
        timer.usleep(delay)
        local s2, b2, h2 = http.get(site)
        print("For site " .. site .. " sampled twice in " .. tostring(delay / 1000000) .. " seconds:")
        if s1 ~= 200 or s2 ~= 200 then
            print("", "Non OK response code for at least one sample:", s1, s2)
        end
        -- make sure no unexpected nil errors
        b1 = b1 or ""
        b2 = b2 or ""
        if #b1 == 0 then print("", "Sample 1 body size == 0") end
        if #b2 == 0 then print("", "Sample 2 body size == 0") end
        h1 = h1 or {}
        h2 = h2 or {}
        if h1["Last-Modified"] and h2["Last-Modified"] then
            if h1["Last-Modified"] == h2["Last-Modified"] then
                print("", "Last Modified Header consistent: " .. h1["Last-Modified"])
            else
                print("", "Last Modified Header inconsistent: " .. h1["Last-Modified"], h2["Last-Modified"])
            end
        elseif h1["Last-Modified"] or h2["Last-Modified"] then
            print("", "Last Modified Header inconsistent: " .. tostring(h1["Last-Modified"]), h2["Last-Modified"])
        else
            print("", "Last Modified Header not present")
        end
        if hash.SHA512(b1) == hash.SHA512(b2) then
            print("", "Hash consistent")
        else
            print("", "Hash inconsistent")
        end
        -- not in core, see https://github.com/asmagill/hammerspoon_asm/tree/master/extras
        if _xtras and _xtras.meyersShortestEdit then
            local diff = _xtras.meyersShortestEdit(b1, b2)
            print("", "MeyersShortestEdit Diff: " .. tostring(diff) .. " differences for " .. tostring(math.max(#b1, #b2)) .. " bytes --> " .. tostring(100 * diff / math.max(#b1, #b2)) .. "%")
        end
    end)
end

return setmetatable(module, { __gc = function() settings.set(USERDATA_TAG .. ".siteData", siteData) end })
