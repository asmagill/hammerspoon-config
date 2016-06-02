local menubar = require"hs.menubar"
local image   = require"hs.image"

local maxMenus = 3

local brokenMenu = menubar.new():setIcon(image.imageFromPath(hs.configdir .. "/_localAssets/psychotic.png"):setSize({w=22,h=22}))

local menus = {}

for i = 1, maxMenus, 1 do
    local nextMenu = (i == maxMenus) and 1 or (i + 1)
    table.insert(menus, {
        { title = "Menu #" .. tostring(i), disabled = true },
        { title = "-" },
        {
            title = "Switch to " .. tostring(nextMenu),
            fn = function(...)
                brokenMenu:setMenu(menus[nextMenu])
            end,
        },
    })
end

brokenMenu:setMenu(menus[1])

return {
    brokenMenu = brokenMenu,
    menus = menus
}