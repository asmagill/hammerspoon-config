local menubar = require"hs.menubar"
local image   = require"hs.image"

local maxMenus = 5

local brokenMenu = menubar.new():setIcon(
    image.imageFromPath(hs.configdir .. "/_localAssets/psychotic.png"):setSize({w=22,h=22})
)

local menus = {}

local switchToMenu = function(menuNumber)
    brokenMenu:setMenu(menus[menuNumber])
    brokenMenu:setTitle(menuNumber)
end

for i = 1, maxMenus, 1 do
    local nextMenu = (i == maxMenus) and 1 or (i + 1)
    table.insert(menus, {
        { title = "Menu #" .. tostring(i), disabled = true },
        { title = "-" },
        {
            title = "Switch to " .. tostring(nextMenu),
            fn = function(...) switchToMenu(nextMenu) end,
        },
        { title = "-" },
        {
            title = "Jump to...",
            menu = {
                {
                    title = "first",
                    fn = function(...) switchToMenu(1) end,
                },
                {
                    title = "last",
                    fn = function(...) switchToMenu(maxMenus) end,
                },
            },
        },
    })
end

switchToMenu(1)

return {
    brokenMenu = brokenMenu,
    menus = menus
}