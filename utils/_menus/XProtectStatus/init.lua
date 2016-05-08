--
-- A combination of code from
--   * http://www.brunerd.com/blog/2013/03/05/xprotect-plugin-checker/
--   * http://www.brunerd.com/blog/2011/06/16/myxprotectstatus/
--  and
--   * http://www.cnet.com/how-to/how-to-monitor-xprotect-updates-in-os-x/
--
-- Brunerd's stuff is fine as it is, but doesn't play nicely with Apple's Dark mode,
-- and since Hammerspoon can do notifications, it seems cleaner to add it to this
-- than the CNet monitor code.
--
-- Plus I like seeing how many things Hammerspoon can do for me :-)

local fnutils       = require"hs.fnutils"
local notify        = require"hs.notify".show
local timer         = require"hs.timer"
local settings      = require"hs.settings"

local decodeJSON    = require"hs.json".decode
local menubar       = require"hs.menubar".new
local attributes    = require"hs.fs".attributes
local styledText    = require"hs.styledText".new
local imageFromPath = require"hs.image".imageFromPath
local hashFunction  = require"hs.hash".SHA256

local module = {}
local assetsDir = debug.getinfo(1).source:match("^@(.*/)[%w%d_]*.lua$")
local menuIconSize = { h = 16, w = 16 }

-- they're actually symlinks with CoreTypes.bundle changed to XProtect.bundle... noted
-- in case the symlinks go away in the future
local XProtectListFile = "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/XProtect.plist"
local XProtectMetaFile = "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/XProtect.meta.plist"

local XProtectListFileHashKey = "_asm.xprotect.plist.hash"
local XProtectMetaFileHashKey = "_asm.xprotect.meta.plist.hash"
local XPwatcherAutoStartKey   = "_asm.xprotect.watcher.autostart"
local XPFullMenuAutoStartKey  = "_asm.xprotect.menu.autostart"

local lastChecked = "-- never --"
local fullMenuRows

-- local fullMenuIcon = "ASCII:....................\n"..
--                            "...6.........4..1...\n"..
--                            "....................\n"..
--                            "....................\n"..
--                            "..9.................\n"..
--                            "....................\n"..
--                            "....................\n"..
--                            "....................\n"..
--                            "....................\n"..
--                            "....................\n"..
--                            "....................\n"..
--                            "....................\n"..
--                            "....................\n"..
--                            "....................\n"..
--                            "....................\n"..
--                            "....................\n"..
--                            "....................\n"..
--                            "...3................\n"..
--                            "...2...........87...\n"..
--                            "...................."

local fullMenuIcon = "ASCII:.......... ..........\n"..
                           ".6....4..1 G.........\n"..
                           ".......... .B..C.....\n"..
                           ".......... J.........\n"..
                           "9......... ..........\n"..
                           ".......... ..........\n"..
                           ".......... ........OH\n"..
                           ".......... ........IN\n"..
                           ".......... ..........\n"..
                           ".......... ..........\n"..
                           ".......... L.........\n"..
                           ".......... ..........\n"..
                           ".......... M.........\n"..
                           ".......... ..........\n"..
                           ".......... ..........\n"..
                           ".......... ..........\n"..
                           ".......... ..........\n"..
                           ".3........ E.........\n"..
                           ".2......87 D.........\n"..
                           ".......... .........."

local currentHashFor = function(filePath)
    local file, err = io.open(filePath, "r")
    if not file then error("unable to open " .. filePath .. " to generate hash", 2) end
    local data = file:read("a")
    file:close()
    return hashFunction(data)
end

local hashHasChanged = function()
    local hashChanged = false
    local XProtectListFileHash = settings.get(XProtectListFileHashKey)
    local XProtectMetaFileHash = settings.get(XProtectMetaFileHashKey)
    local currentXProtectListFileHash = currentHashFor(XProtectListFile)
    local currentXProtectMetaFileHash = currentHashFor(XProtectMetaFile)
    hashChanged = (currentXProtectListFileHash ~= XProtectListFileHash) or (currentXProtectMetaFileHash ~= XProtectMetaFileHash)
    if hashChanged then
        settings.set(XProtectListFileHashKey, currentXProtectListFileHash)
        settings.set(XProtectMetaFileHashKey, currentXProtectMetaFileHash)
    end
    fullMenuRows = nil
    lastChecked = os.date()
    return hashChanged
end

local getProtectedFromList = function(...)
    -- this file contains binary data which prevents us from using json to decode it and xml support is still very experimental... if hs._asm.xml or similar makes it into core, I may switch to using it, but this is fast enough for our purposes and follows the same script that myXProtectStatus uses
    local XProtect, status, exitType, rc = hs.execute([=[
        XProtected=$(
            for (( item=0; ; item++ )); do

              candidate=$(/usr/libexec/PlistBuddy -c "print $item:Description" ]=] .. XProtectListFile .. [=[ 2>/dev/null);

              if [ -z "$candidate" ] || [[ "$candidate" == *Does\ Not\ Exist ]]; then
                #keep from running on in case of error
                #old plistBuddy returns strings to stdout, newer versions do not
                break
              fi

              echo $candidate
            done)

        echo "$XProtected" | sort | uniq
    ]=])
    if not status then
        error("Error fetching list from XProtect.plist: " .. tostring(output) .. " " .. exitType .. " with rc " .. tostring(rc), 2)
    end

    local results = fnutils.split(XProtect, "[\r\n]")
    while (results[#results] == "") do table.remove(results) end
    return results
end

local getXProtectMetaData = function (...)
    local XProtectMetaData, status, exitType, rc = hs.execute("/usr/bin/plutil -convert json -o - " .. XProtectMetaFile)
    if not status then
        error("Error fetching metadata from XProtect.meta.plist: " .. tostring(output) .. " " .. exitType .. " with rc " .. tostring(rc), 2)
    end

    return decodeJSON(XProtectMetaData)
end

local generateMyXProtectStatusOutput = function(...)
    local coreList = getProtectedFromList()
    local metaData = getXProtectMetaData()
    local version  = metaData.Version
    local lastdate = os.date("%c", attributes(XProtectMetaFile).change)

    return "Updated: " .. lastdate .. "\n" ..
           "Version: " .. version .. "\n" ..
           "\n" ..
           "Protecting Against:\n" ..
           table.concat(coreList, "\n")
end

local versionCompare = function(XProtectVersion, myVersion)
    local pluginStatus = "NOT INSTALLED"
    local XProtectVersionAsTable = fnutils.split(XProtectVersion, "%.")
    local myVersionAsTable       = fnutils.split(myVersion, "%.")
    local numParts = math.max(#XProtectVersionAsTable, #myVersionAsTable)
    local count = 0
    while (count < numParts) do
        count = count + 1
        local XProtectChunk = tonumber(XProtectVersionAsTable[count] or 0)
        local myVersionChunk = tonumber(myVersionAsTable[count] or 0)
        if myVersionChunk < XProtectChunk then
            pluginStatus = "BLOCKED"
            count = numParts
        elseif myVersionChunk > XProtectChunk then
            pluginStatus = "OK"
            count = numParts
        elseif  myVersionChunk == XProtectChunk then
            pluginStatus = "OK"
        end
    end
    return pluginStatus
end

local generateXProtectPluginCheckerOutput = function(...)
    local metaData = getXProtectMetaData()
    local version  = metaData.Version
    local lastdate = os.date("%c", attributes(XProtectMetaFile).change)

    local finalOutput = "Updated: " .. lastdate .. "\n" ..
                        "Version: " .. version .. "\n"

    for plugin, v in fnutils.sortByKeys(metaData.PlugInBlacklist["10"]) do
        local pluginBundlePath, status, exitType, rc = hs.execute([[/usr/bin/mdfind "kMDItemCFBundleIdentifier == ']] .. plugin .. [['"]])
        if not status then
            error("Error querying metadata for " .. plugin .. ": " .. tostring(output) .. " " .. exitType .. " with rc " .. tostring(rc), 2)
        end

        local pluginStatus = "NOT INSTALLED"
        local XProtectVersion = v.MinimumPlugInBundleVersion
        local myVersion
        local updateAvailable
        if pluginBundlePath:match("Internet Plug%-Ins") then
            pluginBundlePath = pluginBundlePath:match("^(.-)\r?\n$")
            local XProtectVersion = v.MinimumPlugInBundleVersion
            local myV, status, exitType, rc = hs.execute([[defaults read "]] .. pluginBundlePath .. [[/Contents/Info" CFBundleVersion 2>/dev/null]])
            if not status then
                error("Error getting version for " .. plugin .. " from " .. pluginBundlePath .. "/Contents/Info: " .. tostring(output) .. " " .. exitType .. " with rc " .. tostring(rc), 2)
            end
            myVersion = myV:match("^(.-)\r?\n$")

            pluginStatus = versionCompare(XProtectVersion, myVersion)
            if pluginStatus == "BLOCKED" then
                updateAvailable = (v.PlugInUpdateAvailable and "Update Available" or "No Update Available") .. "\n"
            end
        end
        finalOutput = finalOutput ..
            "\n" ..
            plugin .. " [" .. pluginStatus .. "]\n" ..
            (updateAvailable or "") ..
            "XProtect: " .. XProtectVersion .. "\n" ..
            (myVersion and ("   Local: " .. myVersion .. "\n") or "")
    end

    local java6dir = (attributes("/System/Library/Java/JavaVirtualMachines/1.6.0.jdk") and "/System/Library/Java/JavaVirtualMachines/1.6.0.jdk") or (attributes("/Library/Java/JavaVirtualMachines/1.6.0.jdk") and "/Library/Java/JavaVirtualMachines/1.6.0.jdk")

    if java6dir then
        local XProtectVersion = metaData.JavaWebComponentVersionMinimum
        local myV, status, exitType, rc = hs.execute([[/usr/libexec/PlistBuddy -c "print JavaVM:JVMVersion" "]] .. java6dir .. [[/Contents/Info.plist" 2>/dev/null]])
        if not status then
            error("Error getting version for Java SE 6 from " .. java6dir .. "/Contents/Info: " .. tostring(output) .. " " .. exitType .. " with rc " .. tostring(rc), 2)
        end
        local myVersion = myV:match("^(.-)\r?\n$")
        XProtectVersion = XProtectVersion:match("^([^%-]*)"):gsub("_", ".") -- $(echo $XProtectVersion | cut -d\- -f1 | sed 's/_/./')
        myVersion = myVersion:match("^([^%-]*)"):gsub("_", ".") -- $(echo $myVersion | cut -d\- -f1 | sed 's/_/./')


        local pluginStatus = versionCompare(XProtectVersion, myVersion)

        finalOutput = finalOutput ..
            "\n" ..
            "Java SE 6 [" .. pluginStatus .. "]\n" ..
            "XProtect: " .. XProtectVersion .. "\n" ..
            (myVersion and ("   Local: " .. myVersion .. "\n") or "")
    end

    return finalOutput
end

local generateGateKeeperCodeSignatures = function()
    local metaData = getXProtectMetaData()
    local version  = metaData.Version
    local lastdate = os.date("%c", attributes(XProtectMetaFile).change)

    return "Updated: " .. lastdate .. "\n" ..
           "Version: " .. version .. "\n" ..
           "\n" ..
           table.concat(metaData.GKChecks.CodeSignatureIDs, "\n")
end

local generateExtensionBlacklist = function()
    local metaData = getXProtectMetaData()
    local version  = metaData.Version
    local lastdate = os.date("%c", attributes(XProtectMetaFile).change)

    local finalOutput = "Updated: " .. lastdate .. "\n" ..
                        "Version: " .. version .. "\n"

    for i, v in ipairs(metaData.ExtensionBlacklist.Extensions) do
        finalOutput = finalOutput ..
            "\n" ..
            "Identifier:   " .. v.CFBundleIdentifier .. "\n" ..
            "Developer ID: " .. v["Developer Identifier"] .. "\n"
    end

    return finalOutput
end

local generateBlockTextMenuItem = function(sourceText)
    return  {
              {
                  title = styledText(sourceText, { font = { name ="Menlo", size = 10 },
                  }), disabled = true,
              }
            }
end

local generateFullMenu = function()
    local metaData = getXProtectMetaData()
    local version  = metaData.Version
    local lastdate = os.date("%c", attributes(XProtectMetaFile).change)
    local header   = "Updated: " .. lastdate .. "\n" ..
                     "Version: " .. version .. "\n" ..
                     "Checked: " .. lastChecked

    local headerRows = generateBlockTextMenuItem(header)

    return {
        headerRows[1],
        { title = "-", disabled = true },
        {
            title = "Plugin Blacklist",
            menu = generateBlockTextMenuItem(generateXProtectPluginCheckerOutput():match("^[^\n]+\n[^\n]+\n\n(.-)\n?$"))
        },
        {
            title = "Extension Blacklist",
            menu = generateBlockTextMenuItem(generateExtensionBlacklist():match("^[^\n]+\n[^\n]+\n\n(.-)\n?$"))
        },
        {
            title = "Malware Signatures",
            menu = generateBlockTextMenuItem(generateMyXProtectStatusOutput():match("^[^\n]+\n[^\n]+\n\n(.-)\n?$"))
        },
        {
            title = "Gatekeeper Code Signature IDs",
            menu = generateBlockTextMenuItem(generateGateKeeperCodeSignatures():match("^[^\n]+\n[^\n]+\n\n(.-)\n?$"))
        },
        { title = "-", disabled = true },
        {
            title = "Notify on update",
            checked = module.changeWatcher and true or false,
            fn = function(mods)
                fullMenuRows = nil
                if module.changeWatcher then
                    module.stopWatchingForUpdates ()
                    settings.set(XPwatcherAutoStartKey, false)
                else
                    module.watchForUpdates()
                    settings.set(XPwatcherAutoStartKey, true)
                end
            end
        },
        {
            title = "Remove XProtect Status Menu",
            fn = function(mods)
                module.fullMenu = module.fullMenu:delete()
            end
        }
    }
end

module.createFullMenu = function()
    if not module.fullMenu then
        module.fullMenu = menubar():setIcon(fullMenuIcon)
            :setMenu(function(mods)
                if not fullMenuRows then
                    fullMenuRows = generateFullMenu()
                end
                return fullMenuRows
            end)
    end
    return module.fullMenu
end

module.createMyXProtectStatusMenu = function()
    if not module.statusMenu then
        module.statusMenu = menubar():setIcon(imageFromPath(assetsDir .. "myXProtectStatus.png"):setSize(menuIconSize))
                                  :setMenu(function(mods)
                                      local menuRows = generateBlockTextMenuItem(generateMyXProtectStatusOutput())
                                      table.insert(menuRows, { title = "-", disabled = true })
                                      table.insert(menuRows, {
                                          title = "Remove myXProtect Status Menu",
                                          fn = function(mods)
                                              module.statusMenu = module.statusMenu:delete()
                                          end,
                                      })
                                      return menuRows
                                  end)
    end
    return module.statusMenu
end

module.createXProtectPluginCheckerMenu = function()
    if not module.pluginMenu then
        module.pluginMenu = menubar():setIcon(imageFromPath(assetsDir .. "XProtectPluginChecker.png"):setSize(menuIconSize))
                              :setMenu(function(mods)
                                  local menuRows = generateBlockTextMenuItem(generateXProtectPluginCheckerOutput())
                                  table.insert(menuRows, { title = "-", disabled = true })
                                  table.insert(menuRows, {
                                      title = "Remove XProtectPluginChecker Menu",
                                      fn = function(mods)
                                          module.pluginMenu = module.pluginMenu:delete()
                                      end,
                                  })
                                  return menuRows
                              end)
    end
    return module.pluginMenu
end

module.onHashUpdate = function()
    local metaData = getXProtectMetaData()
    local version  = metaData.Version
    local lastdate = os.date("%c", attributes(XProtectMetaFile).change)
    notify("XProtext Updated", "Updated: " .. lastdate , "Version: " .. version)
end

local watchForUpdates, stopWatchingForUpdates
watchForUpdates = function()
    if not module.changeWatcher then
        if hashHasChanged() then module.onHashUpdate() end
        module.changeWatcher = timer.new(3600, function()
            if hashHasChanged() then
                module.onHashUpdate()
            end
        end, true):start()
        module.watchForUpdates = nil
        module.stopWatchingForUpdates = stopWatchingForUpdates
    end
end

stopWatchingForUpdates = function()
    if module.changeWatcher then
        module.changeWatcher:stop()
        module.changeWatcher = nil
        module.watchForUpdates = watchForUpdates
        module.stopWatchingForUpdates = nil
    end
end

module.watchForUpdates = watchForUpdates

if settings.get(XPwatcherAutoStartKey) then module.watchForUpdates() end
if settings.get(XPFullMenuAutoStartKey) then
    module.createFullMenu()
else
    module.statusMenu = module.createMyXProtectStatusMenu()
    module.pluginMenu = module.createXProtectPluginCheckerMenu()
end

return module