local module = {
--[=[
    _NAME        = 'applicationMenu.lua',
    _VERSION     = '0.1',
    _URL         = 'https://github.com/asmagill/hammerspoon-config',
    _DESCRIPTION = [[ applicationMenu to replace XMenu and the like ]],
    _TODO        = [[]],
    _LICENSE     = [[ See README.md ]]
--]=]
}

local fileListMenu = require("utils.fileListMenu")

local appMenu = fileListMenu.new("Apps") ;
appMenu:menuIcon("ASCII:....................\n"..
                       "........1..4........\n"..
                       "....................\n"..
                       "....................\n"..
                       "....................\n"..
                       "....................\n"..
                       "....................\n"..
                       "....................\n"..
                       "....................\n"..
                       "....................\n"..
                       "....................\n"..
                       "B..................A\n"..
                       "...8............9...\n"..
                       "....................\n"..
                       "....................\n"..
                       "....................\n"..
                       "..2..............5..\n"..
                       "....................\n"..
                       "....3..........6....\n"..
                       "....................")
appMenu:subFolders("before")                    -- 0,1,2,3 := "ignore","before","mixed","after"
appMenu:changeDetect("notify")                  -- 0,1,2,3 := "ignore","silent","notify","repopulate"
appMenu:showForMenu("icon")                     -- 0,1,2   := "icon","label","both"
appMenu:menuCriteria("([^/]+)\\.app$")
appMenu:actionFunction(function(x) hs.application.launchOrFocus(x) end)
appMenu:rootDirectory("/Applications")
-- make this last so that if saved state exists about subFolders, changeDetect, or showForMenu
-- type can be overwritten and the above act like defaults
appMenu:storageKey("applicationMenu")           -- nil indicates do not store in settings
appMenu:activate()

return appMenu