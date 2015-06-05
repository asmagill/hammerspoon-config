
-- a=hs.drawing.image({w=30,h=30},"ASCII:............\n.....14.....\n............\n............\n............\n............\n.B........A.\n..8......9..\n............\n..2......5..\n...3....6...\n............"):show()


AppMenu = {}
myMenu = nil

appList = function(startingDir)
  local startDir = startingDir or "/Applications"
  local list = {}

  string.gsub(
    _asm.extras.exec([[find "]]..startDir..[[" -name *.app -maxdepth 1]]),
    "[^\r\n]+",
    function(c)
        local label = c:gsub("^"..startDir.."/",""):gsub(".app$","")
        list[#list+1] = { title=label, fn=function() hs.application.launchOrFocus(c) end }
        --print(label,c)
    end
  )

  -- Get subdirectories at this level

  string.gsub(
    _asm.extras.exec([[find -L "]]..startDir..[[" -type d ! -name *.app -maxdepth 1]]),
    "[^\r\n]+",
    function(c)
      if c ~= startDir then
        local label = c:gsub("^"..startDir.."/","")
        local subDirs = appList(c)
        if next(subDirs) ~= nil then
          --print(label)
          list[#list+1] = { title=label, menu=subDirs }
        end
      end
    end
  )

  return list
end

doMenu = function(mods)
  print(inspect(mods))
  return AppMenu
end

makeMenu = function()
  AppMenu = appList("/Applications")

  myMenu = hs.menubar.new() ;
  myMenu:setIcon(
    "ASCII:....................\n"..
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
    "...................."
  )
  myMenu:setMenu(doMenu)
end

