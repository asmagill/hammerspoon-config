-- In this example we create a menu of the users Documents folder.  We
-- want to match all files and folders (except for dot-files)

local FLM =  require("hs._asm.filelistmenu")
local hsfs = require("hs.fs")
local eventtap = require("hs.eventtap")

-- Here we define an action function which takes the modifiers pressed when the
-- menu is clicked on so we can choose what action to perform.  This action function
-- is used for both Files and Folders
local actionFunction = function(x)
    local mods = eventtap.checkKeyboardModifiers()
    if mods["cmd"] then
        os.execute([[/usr/local/bin/edit "]]..x..[["]])
    else
        os.execute([[open -a Finder "]]..x..[["]])
    end
end

local docMenu = FLM.new("Docs") ;

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
docMenu:menuCriteria(function(file, path, purpose)

      -- ignore dot files
      if string.match(file, "^%..*$") then return false end

      -- For file checks, we want to ignore directories
      if purpose == "file" then
          if hsfs.attributes(path.."/"..file, "mode") == "directory" then return false end
          return true, file -- otherwise, return true and file as label

      -- We want all folders as well, when looking for them
      elseif purpose == "directory" then
          if hsfs.attributes(path.."/"..file, "mode") == "directory" then return true, file end
          return false -- otherwise, return false

      -- And any update which makes it this far should also be accepted
      elseif purpose == "update" then
          return true, file
      end
    end
)

docMenu:actionFunction(actionFunction)
docMenu:folderFunction(actionFunction)
docMenu:rootDirectory(os.getenv("HOME").."/Documents")

docMenu:showWarnings(false)

docMenu:menuIcon("ASCII:....................\n"..
                       "....................\n"..
                       "...c........c.......\n"..
                       "...dt....tri12......\n"..
                       "....v...............\n"..
                       "...............3....\n"..
                       "...........i...4b...\n"..
                       "..........rg...g....\n"..
                       "..........p...pm....\n"..
                       "....................\n"..
                       "....................\n"..
                       "....................\n"..
                       "....................\n"..
                       "....................\n"..
                       "....................\n"..
                       "....v..........m....\n"..
                       "...dk..........kb...\n"..
                       "...a............a...\n"..
                       "....................\n"..
                       "....................")

docMenu:subFolders("mixed")

--docMenu:activate()

return docMenu