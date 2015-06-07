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
local devMenu = fileListMenu.new("HammerDev") ;

devMenu:menuCriteria(function(file, path, purpose)
      if string.match(file, "^%..*$") then return false end -- ignore dot files
      if purpose == "file" then return false -- this is a test of getting just the folders
      elseif purpose == "directory" then
          if hs.fs.attributes(path.."/"..file).mode == "directory" then return true, file end -- for dir match, return true and dir as label
          return false -- otherwise, return false
      elseif purpose == "update" then
          return true, file -- let's see how bad this gets...
      end
    end
)

devMenu:actionFunction(actionFunction)
devMenu:folderFunction(actionFunction)
devMenu:rootDirectory("/opt/amagill/src/hammerspoon")

devMenu:showWarnings(false)
devMenu:pruneEmptyDirs(false)

devMenu:menuIcon("ASCII:....................\n"..
                       "....................\n"..
                      "....................\n"..
                       ".....G..E..C..A.....\n"..
                       "....................\n"..
                       "....................\n"..
                       "...1.G..E..C..A.1...\n"..
                       "...7............5...\n"..
                       "....................\n"..
                       "....................\n"..
                       "....................\n"..
                       "....................\n"..
                       "...7............5...\n"..
                       "...3.g..e..c..a.3...\n"..
                       "....................\n"..
                       "....................\n"..
                       ".....g..e..c..a.....\n"..
                       "....................\n"..
                       "....................\n"..
                       "....................")
devMenu:subFolders("mixed")
devMenu:activate()

return devMenu