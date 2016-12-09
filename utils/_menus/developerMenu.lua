-- This example provides a list of folders from a table of multiple roots.

-- In this example, we are only looking for directories, and not files.

local FLM = require("hs._asm.filelistmenu")
local FS  = require("hs.fs")
local eventtap = require("hs.eventtap")

-- Here we define an action function which takes the modifiers pressed when the
-- menu is clicked on so we can choose what action to perform.  This action function
-- is used for both Files and Folders
local actionFunction = function(x)
    local mods = eventtap.checkKeyboardModifiers()
    if mods["cmd"] then
        os.execute([[open -a Finder "]]..x..[["]])
    else
        os.execute([[/usr/local/bin/edit "]]..x..[["]])
    end
end

local devMenu = FLM.new("Developer") ;

-- Here we define the match criteria as a function.  The function receives 3 arguments
-- and returns up to 2.  The arguments passed in are the file name (without path),
-- the path (without the file at the end), and the purpose of this call, which will be
-- "file"      -- indicates we're matching files (i.e. menu end nodes)
-- "directory" -- indicates we're matching folders (i.e. potential submenus)
-- "update"    -- indicates we're matching against the results of hs.pathwatcher for
--                potential updates to the menu.

-- Note that unlike a string criteria, when a function is used, file matches are not
-- automatically exempted from subfolder matches -- this allows more flexibility when
-- it comes to OS X bundle types (like .app)

-- Returns 'boolean, label' where boolean will be true if we should consider this file
-- a match or false if we should skip it.  Label is what will be put in the menu and is
-- optional when the boolean value is false.

devMenu:menuCriteria(function(file, path, purpose)

      -- ignore dot files
      if string.match(file, "^%..*$") then return false end

      -- for our purposes, we just want folders for this menu, so ignore files.
      if purpose == "file" then return false

      elseif purpose == "directory" then

          -- we use hs.fs to determine if this a folder and return true and the filename
          -- (directory name) as the label if it is.
          if FS.attributes(path.."/"..file, "mode") == "directory" and not file:match("%.so%.dSYM$") then return true, file end
          return false -- otherwise, return false

      elseif purpose == "update" then

          -- Again, for updates we only care about folders.

          -- Note that if we had done 'hs.fs.attributes(path.."/"..file).mode' which I
          -- admit looks more lua like, then this would cause an error if the file
          -- disappears quickly (e.g. a lock file) before the pathwatcher process
          -- completes.
          if FS.attributes(path.."/"..file, "mode") == "directory" and not file:match("%.so%.dSYM$") then return true, file end
          return false
      end
    end
)

devMenu:actionFunction(actionFunction)  -- technically not necessary since we're ignoring files
devMenu:folderFunction(actionFunction)

-- This example shows multiple root directories, instead of a string value for the root.
-- In this case, the array includes entries of the form 'label = path' where label will be
-- the top level menu entry in the menu created, and it's submenu will be what matches for
-- the given path.
devMenu:rootDirectory({
                        ["Hammerspoon"] = "/opt/amagill/src/hammerspoon/hammerspoon",
--                        ["Hammerspoon-Testing"] = "/opt/amagill/src/hammerspoon/hammerspoon-testing",
                        ["HS Config"]   = hs.configdir,
                        ["Arduino"]     = os.getenv("HOME").."/Documents/Arduino",
                        ["Modules-WIP"]  = "/opt/amagill/src/hammerspoon/_asm/wip",
                        ["Modules-Core"]  = "/opt/amagill/src/hammerspoon/_asm/core",
                      })

devMenu:subFolderDepth(15)
devMenu:showWarnings(true)

-- In this case, the directories are our entries, so each will seem "empty" as there are no
-- file matches within them... this causes the module to list them anyways.
devMenu:pruneEmptyDirs(false)

devMenu:menuIcon("ASCII:....................\n"..
                       "....................\n"..
                       "....................\n"..
                       "...J..L..N..Q..9....\n"..
                       "....................\n"..
                       "....J..L..N..Q..9...\n"..
                       "...1.............1..\n"..
                       "..7..............5U.\n"..
                       "..X..............WU.\n"..
                       "....................\n"..
                       "....................\n"..
                       "..Y..............ZS.\n"..
                       "..7..............5S.\n"..
                       "...3.............3..\n"..
                       "....j..l..n..q..s...\n"..
                       "....................\n"..
                       "...j..l..n..q..s....\n"..
                       "....................\n"..
                       "....................\n"..
                       "....................")

devMenu:subFolders("mixed")  -- technically not necessary, since all we have is folders

devMenu:activate()

return devMenu
