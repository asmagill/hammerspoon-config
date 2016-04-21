-- variation on https://github.com/heptal/dotfiles/blob/master/roles/hammerspoon/files/volumes.lua

-- manage removable volumes

local module = {}
local application = require"hs.application"
local fnutils     = require"hs.fnutils"
local fs          = require"hs.fs"
local image       = require"hs.image"
local menubar     = require"hs.menubar"

local keys = function(t)
  local keys={}
  for k, v in pairs(t) do
    table.insert(keys, k)
  end
  table.sort(keys)
  return keys
end

local humanSize = function(bytes)
  local units = {'bytes', 'kb', 'MB', 'GB', 'TB', 'PB'}
  local power = math.floor(math.log(bytes)/math.log(1000))
  return string.format("%.3f "..units[power + 1], bytes/(1000^power))
end

local volMenuMaker = function(eventType, info)
  local entries = {{title = "Disk Utility", fn = function() application.launchOrFocus("Disk Utility") end}, {title = "-"}}
--   local removableVolumes = fnutils.filter(fs.volume.allVolumes(), function(v) return v.NSURLVolumeIsRemovableKey end)
--   if #keys(removableVolumes) > 0 then module.menu:returnToMenuBar() else module.menu:removeFromMenuBar() return end

--   fnutils.each(keys(removableVolumes), function(path)
--       local name = path:match("^/Volumes/(.*)")
--       local size = humanSize(removableVolumes[path].NSURLVolumeTotalCapacityKey)
--       table.insert(entries, {title = fmt("%s (%s)", name, size), fn = function() hs.execute(fmt("open %q",path)) end})
--       table.insert(entries, {title = "⏏ Eject", indent = 1, fn = function() fs.volume.eject(path) end})
--     end)

-- I want all volumes, not just removable ones

  local volumes = fs.volume.allVolumes()
  fnutils.each(keys(volumes), function(path)
      local size = humanSize(volumes[path].NSURLVolumeTotalCapacityKey)
      table.insert(entries, { title = string.format("%s (%s)", volumes[path].NSURLVolumeNameKey, size), fn = function() hs.execute(string.format("open %q",path)) end })

      -- but only allow eject for the removable ones
      table.insert(entries, { title = "⏏ Eject", indent = 1, fn = function() fs.volume.eject(path) end, disabled = not volumes[path].NSURLVolumeIsRemovableKey })
    end)

  return entries
end

local diskIcon = image.imageFromPath("/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/SidebarRemovableDisk.icns")
module.menu = menubar.new():setMenu(volMenuMaker):setIcon(diskIcon:setSize({w=16,h=16}))

-- not necessary since we're passing a function to setMenu and not a table
-- module.watcher = fs.volume.new(volMenuMaker):start()
-- volMenuMaker()

return module