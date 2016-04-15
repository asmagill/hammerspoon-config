-- Based on Szymon Kaliski's code found at https://github.com/szymonkaliski/Dotfiles/blob/ae42c100a56c26bc65f6e3ca2ad36e30b558ba10/Dotfiles/hammerspoon/utils/spaces/dots.lua


local spaces  = require("hs.spaces")
local screen  = require("hs.screen")
local _spaces = require("hs._asm.undocumented.spaces")
local fnutils = require("hs.fnutils")
local drawing = require("hs.drawing")

local cache = {
  watchers = {},
  dots     = {}
}

local module = {}

module.size          = 8
module.distance      = 16
module.cache         = cache
module.color         = { white = 0.7, alpha = 0.45 }
module.selectedColor = { white = 0.7, alpha = 0.95 }
module.activeColor   = { green = 0.5, alpha = 0.75 }

module.draw = function()
  local activeSpace = _spaces.activeSpace()

  for k, v in pairs(cache.dots) do
      cache.dots[k].stillHere = false
  end
  -- FIXME: what if I remove screen, the dots are still being drawn?
  fnutils.each(screen.allScreens(), function(screen)
    local screenFrame  = screen:fullFrame()
    local screenUUID   = screen:spacesUUID()
    local screenSpaces = _spaces.layout()[screenUUID]

    if screenSpaces then -- when screens don't have separate spaces, it won't appear in the layout
      if not cache.dots[screenUUID] then cache.dots[screenUUID] = {} end
      cache.dots[screenUUID].stillHere = true

      for i = 1, math.max(#screenSpaces, #cache.dots[screenUUID]) do
        local dot

        if not cache.dots[screenUUID][i] then
          dot = drawing.circle({ x = 0, y = 0, w = module.size, h = module.size })

          dot
            :setStroke(false)
  --           :setBehaviorByLabels({ 'canJoinAllSpaces', 'stationary' })
            :setBehaviorByLabels({ 'canJoinAllSpaces' })
  --           :setLevel(drawing.windowLevels.desktopIcon)
            :setLevel(drawing.windowLevels.popUpMenu)
        else
          dot = cache.dots[screenUUID][i]
        end

        local x     = screenFrame.x + screenFrame.w / 2 - (#screenSpaces / 2) * module.distance + i * module.distance - module.size * 3 / 2
        local y     = screenFrame.y + screenFrame.h - (module.distance/2)
  --       local y     = module.distance
  --       local y     = screenFrame.h - module.distance

        local dotColor = module.color
        if screenSpaces[i] == activeSpace then
            dotColor = module.activeColor
        else
            for i2, v2 in ipairs(_spaces.query(_spaces.masks.currentSpaces)) do
                if screenSpaces[i] == v2 then
                    dotColor = module.selectedColor
                    break
                end
            end
        end

        dot
          :setTopLeft({ x = x, y = y })
          :setFillColor(dotColor)

        if i <= #screenSpaces then
          dot:show()
        else
          dot:hide()
        end

        cache.dots[screenUUID][i] = dot
      end
    end
  end)
  for k, v in pairs(cache.dots) do
      if not cache.dots[k].stillHere then
          for i, v2 in ipairs(cache.dots[k]) do
              v2:delete()
          end
          cache.dots[k] = nil
      end
  end
end

module.start = function()
  -- we need to redraw dots on screen and space events
  cache.watchers.spaces = spaces.watcher.new(module.draw):start()
  cache.watchers.screen = screen.watcher.newWithActiveScreen(module.draw):start()
  module.draw()
end

module.stop = function()
  fnutils.each(cache.watchers, function(watcher) watcher:stop() end)

  cache.dots = {}
end

module.start()

return module