-- Based on Szymon Kaliski's code found at https://github.com/szymonkaliski/Dotfiles/blob/ae42c100a56c26bc65f6e3ca2ad36e30b558ba10/Dotfiles/hammerspoon/utils/spaces/dots.lua


local spaces = require('hs._asm.undocumented.spaces')

local cache = {
  watchers = {},
  dots     = {}
}

local module = {}

module.size                   = 8
module.distance               = 16
module.selectedAlpha          = 0.65
module.alpha                  = 0.25
module.cache                  = cache
module.color                  = { white = .75}

module.draw = function()
  local activeSpace = spaces.activeSpace()

  -- FIXME: what if I remove screen, the dots are still being drawn?
  hs.fnutils.each(hs.screen.allScreens(), function(screen)
    local screenFrame  = screen:fullFrame()
    local screenUUID   = screen:spacesUUID()
    local screenSpaces = spaces.layout()[screenUUID]

    if not cache.dots[screenUUID] then cache.dots[screenUUID] = {} end

    for i = 1, math.max(#screenSpaces, #cache.dots[screenUUID]) do
      local dot

      if not cache.dots[screenUUID][i] then
        dot = hs.drawing.circle({ x = 0, y = 0, w = module.size, h = module.size })

        dot
          :setStroke(false)
          :setBehaviorByLabels({ 'canJoinAllSpaces', 'stationary' })
--           :setLevel(hs.drawing.windowLevels.desktopIcon)
          :setLevel(hs.drawing.windowLevels.popUpMenu)
      else
        dot = cache.dots[screenUUID][i]
      end

      local x     = screenFrame.w / 2 - (#screenSpaces / 2) * module.distance + i * module.distance - module.size * 3 / 2
      local y     = screenFrame.h - module.distance
      local alpha = screenSpaces[i] == activeSpace and module.selectedAlpha or module.alpha

      module.color.alpha = alpha
      dot
        :setTopLeft({ x = x, y = y })
        :setFillColor(module.color)

      if i <= #screenSpaces then
        dot:show()
      else
        dot:hide()
      end

      cache.dots[screenUUID][i] = dot
    end
  end)
end

module.start = function()
  -- we need to redraw dots on screen and space events
  cache.watchers.spaces = hs.spaces.watcher.new(module.draw):start()
  cache.watchers.screen = hs.screen.watcher.new(module.draw):start()

  module.draw()
end

module.stop = function()
  hs.fnutils.each(cache.watchers, function(watcher) watcher:stop() end)

  cache.dots = {}
end

module.start()

return module