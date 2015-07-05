-- This example is for an Application launching menu  Most of the necessary
-- settings for this menu are already the defaults, but it serves as a simple
-- example none-the-less.

local FLM = require("hs._asm.filelistmenu")

-- create the application menu and give it a default label
local appMenu = FLM.new("Apps") ;

-- The defaults for filelistmenu will create an Application based menu starting from
-- the /Applications directory.  The commands listed here are included so you can more
-- easily see what is actually being setup, but they aren't really necessary for
-- this default behavior, so they are commented out.

-- Show an icon, if one is provided
--appMenu:showForMenu("icon")

-- The match criteria here is a string which matches any name which ends in .app.  The
-- parenthesis are included to indicate the portion of the name to use as the menu items
-- label... without the parenthesis, the full name matched would be used.
--appMenu:menuCriteria("^([^/]+)%.app$")

-- This function indicates what action should occur when a menu item is selected
--appMenu:actionFunction(function(x) hs.application.launchOrFocus(x) end)

-- This function indicates what action should occur when a subfolder itself is selected
--appMenu:folderFunction(function(x) os.execute([[open -a Finder "]]..x..[["]]) end)

-- Specify the root directory to start from.
--appMenu:rootDirectory("/Applications")

-- The maximum folder depth that we will search for files or folders which match the
-- criteria.  This prevents potential loops, which would ultimately crash HS.
appMenu:subFolderDepth(12)

-- If false, then warning messages will not be printed to the HS console.
appMenu:showWarnings(true)

-- Define an icon using ASCIIArt.  See hs.drawing and
-- http://cocoamine.net/blog/2015/03/20/replacing-photoshop-with-nsstring/
appMenu:menuIcon("ASCII:....................\n"..
                       "............1..4....\n"..
                       "....................\n"..
                       "....................\n"..
                       "....................\n"..
                       "....................\n"..
                       "....................\n"..
                       "....................\n"..
                       "....................\n"..
                       "....................\n"..
                       "....................\n"..
                       "...B...............A\n"..
                       "8...............9...\n"..
                       "....................\n"..
                       "....................\n"..
                       "....................\n"..
                       "...2...........5....\n"..
                       "....................\n"..
                       "...3..........6.....\n"..
                       "....................")

-- Sort folder items before file items in the menu
appMenu:subFolders("before")

-- activate the menu
appMenu:activate()

-- This allows you to include this file like 'menu = require(...)' and capture the
-- menu object in case you want to manipulate it elsewhere.

return appMenu