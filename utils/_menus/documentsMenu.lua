local module = {
--[=[
    _NAME        = 'documentsMenu.lua',
    _VERSION     = '0.1',
    _URL         = 'https://github.com/asmagill/hammerspoon-config',
    _DESCRIPTION = [[ applicationMenu to replace XMenu and the like ]],
    _TODO        = [[]],
    _LICENSE     = [[ See README.md ]]
--]=]
}

local fileListMenu = require("utils.fileListMenu")
local actionFunction = function(x, mods)
    if mods["cmd"] then
        os.execute([[open -a Finder "]]..x..[["]])
    else
        os.execute([[edit "]]..x..[["]])
    end
end
local docMenu = fileListMenu.new("Docs") ;

-- the commented out lines are actually in the defaults, included here just for completness
-- in case change desired:

--docMenu:showForMenu("icon")
docMenu:menuCriteria(function(file, path, purpose)
      if string.match(file, "^%..*$") then return false end -- ignore dot files
      if purpose == "file" then
          if hs.fs.attributes(path.."/"..file).mode == "directory" then return false end -- for file match, ignore directories.
          return true, file -- otherwise, return true and file as label
      elseif purpose == "directory" then
          if hs.fs.attributes(path.."/"..file).mode == "directory" then return true, file end -- for dir match, return true and dir as label
          return false -- otherwise, return false
      elseif purpose == "update" then
          return true, file -- let's see how bad this gets...
      end
    end
)

docMenu:actionFunction(actionFunction)
docMenu:folderFunction(actionFunction)
docMenu:rootDirectory(os.getenv("HOME").."/Documents")

--docMenu:subFolderDepth(12)
docMenu:showWarnings(true)

docMenu:menuIcon("ASCII:....................\n"..
                       "....................\n"..
                       "...c........ce......\n"..
                       "...d........i.......\n"..
                       "....................\n"..
                       "............i...e...\n"..
                       "............g..gb...\n"..
                       "....................\n"..
                       "....................\n"..
                       "....................\n"..
                       "....................\n"..
                       "....................\n"..
                       "....................\n"..
                       "....................\n"..
                       "....................\n"..
                       "....................\n"..
                       "...d............b...\n"..
                       "...a............a...\n"..
                       "....................\n"..
                       "....................")
docMenu:subFolders("mixed")
docMenu:activate()

return docMenu