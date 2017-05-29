local spotlight   = require"hs.spotlight"
local chooser     = require"hs.chooser"
local image       = require"hs.image"
local hotkey      = require"hs.hotkey"
local application = require"hs.application"
local mouse       = require"hs.mouse"
local menubar     = require"hs.menubar"
local inspect     = require"hs.inspect"
local pasteboard  = require"hs.pasteboard"
local styledText  = require"hs.styledText".new

local module = {}

--local function lookat(item)
--    local result = ""
--    for k,v in pairs(item) do result = result .. tostring(k) .. " = " .. tostring(v) .. "\n" end
--    return result
--end

module.apps = spotlight.new():queryString([[ kMDItemContentType = "com.apple.application-bundle" ]])
                             :callbackMessages("didUpdate", "didFinish")
                             :setCallback(function(obj, msg, info)
                                if module.chooser then
                                    module.chooser:refreshChoicesCallback()
                                end
                             end):start()

module.chooser = chooser.new(function(choice) if choice then application.launchOrFocus(choice.path) end end)
module.chooser:fgColor{ list = "x11", name = "lightskyblue" }
              :subTextColor{ list = "x11", name = "darkseagreen" }
              :width(60)
              :searchSubText(true)
              :choices(function()
                  local results = {}
                  for i = 1, #module.apps, 1 do
                      if module.apps[i] then
                          local bid  = module.apps[i].kMDItemCFBundleIdentifier or "< not available >"
                          local path = module.apps[i].kMDItemPath
--                          if not path then
--                              print("~~ null path for " .. finspect(module.apps[i]) .. " " .. (lookat(module.apps[i]):gsub("%s+", " ")))
--                          else
                          if path then
                              table.insert(results, {
                                  text       = module.apps[i].kMDItemDisplayName,
                                  subText    = path .. " (" .. bid .. ")",
                                  image      = bid and image.imageFromAppBundle(bid) or image.imageFromName(image.systemImageNames.StopProgressFreestandingTemplate),
                                  index      = i,
                                  path       = path,
                              })
                          end
                      end
                  end
                  table.sort(results, function(a, b) return tostring(a.text) < tostring(b.text) end)
                  return results
              end):rightClickCallback(function(row)
                  if row == 0 then print("no row") ; return end
                  local rowDetails = module.chooser:selectedRowContents(row)
                  if not next(rowDetails) then print("not in apps") ; return end -- empty table means right click not on an actual item
                  local menuItems = {}
                  for i, v in ipairs(module.apps[rowDetails.index]:attributes()) do
                      local title = v:match("^_?kMDItem(.*)$") or v:match("^NSMetadata.-Item(.*)$") or v
                      local value = inspect(module.apps[rowDetails.index][v]):gsub("%s+", " ")
                      table.insert(menuItems, {
                          title = styledText(title, { font = { name ="Menlo", size = 10 } }),
                          menu  = { {
                              title = styledText(value, { font = { name ="Menlo", size = 10 } }),
                              fn = function() pasteboard.setContents(value) end
                          } },
                      })
                  end
                  table.insert(menuItems, {
                      title = styledText("ItemPath", { font = { name ="Menlo", size = 10 } }),
                      menu  = { {
                          title = styledText(rowDetails.path, { font = { name ="Menlo", size = 10 } }),
                          fn = function() pasteboard.setContents(rowDetails.path) end
                      } },
                  })
                  table.sort(menuItems, function(a, b) return a.title < b.title end)
                  local menu = menubar.new(false):setMenu(menuItems):popupMenu(mouse.getAbsolutePosition())
              end)
--              :bgDark(true)

module.hotkey = hotkey.bind({"cmd", "ctrl", "alt"}, "return", function()
    if module.chooser:isVisible() then
        module.chooser:hide()
    else
        module.chooser:show()
    end
end)

return module
