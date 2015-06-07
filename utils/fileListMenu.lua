local module = {
--[=[
    _NAME        = 'fileListMenu.lua',
    _VERSION     = '0.1',
    _URL         = 'https://github.com/asmagill/hammerspoon-config',
    _DESCRIPTION = [[ applicationMenu to replace XMenu and the like ]],
    _TODO        = [[
                        add expression tester for testing new patterns
                        allow function/table for matchCriteria -- yes, soon
                            table   list of patterns or functions, with pass/fail flag?
                          * function returns T/F, label
                          * function takes flag indicating file check, dir check, change check
                      * pass mods to templates?
                      * prune subdir flag
                        alt/toggles for status menu?  modify mods for status menu?

                        hide data to make it necessary to use helpers?
                            (protect data, inspect as method shortcut list, etc.)
                        better error detection (e.g. wrong data types)
                        document

                        Other so I don't forget:
                            ipc cli needs to handle paths with spaces
    ]],
    _LICENSE     = [[ See README.md ]]
--]=]
}

-- private variables and methods -----------------------------------------

local l_generateAppList -- because this function is recursive, we have to pre-declare it to keep it local
l_generateAppList = function(self, startDir, expression, depth)
    local startDir = startDir or self.root
    local expression = expression or self.matchCriteria
    local depth = depth or 1
    local list = {}

    if depth > self.maxDepth then
        if self.warnings then print("Maximum search depth of "..self.maxDepth.." reached for menu "..self.label.." at "..startDir) end
    else
-- get files at this level -- we want a label and a path
        for name in hs.fs.dir(startDir) do
            local label, accept
            if type(expression) == "string" then
                label = name:match(expression)
            elseif type(expression) == "function" then
                accept, label = expression(name, startDir, "file")
                if not accept then label = nil end
            end
            if label then
                list[#list+1] = { title = label, fn = function() if type(self.template) == "function" then self.template(startDir.."/"..name, self.triggerMods) else if self.warnings then print("Menu action template must be a function") end end end }
            end
        end

        if self.subFolderBehavior ~= 0 then
-- get sub-dirs at this level -- we want a label and a table -- recursion!
            for name in hs.fs.dir(startDir) do
                local label, accept
                if type(expression) == "string" then
                    if not (name == "." or name == ".." or name:match(expression)) then
                        accept = hs.fs.attributes(startDir.."/"..name, "mode") == "directory"
                        label = name
                    else
                        accept = false
                    end
                elseif type(expression) == "function" then
                    accept, label = expression(name, startDir, "directory")
                    if not accept then label = nil end
                end
                if accept then
                    local subDirs = l_generateAppList(self, startDir.."/"..name, expression, depth + 1)
                    if  next(subDirs) or not self.pruneEmpty then
                        if next(subDirs) then
                            list[#list+1] = { title = label, menu = subDirs, fn = function() if type(self.folderTemplate) == "function" then self.folderTemplate(startDir.."/"..name, self.triggerMods) else if self.warnings then print("Menu folder action template must be a function") end end end }
                        else
                            list[#list+1] = { title = label, fn = function() if type(self.folderTemplate) == "function" then self.folderTemplate(startDir.."/"..name, self.triggerMods) else if self.warnings then print("Menu folder action template must be a function") end end end }
                        end
                    end
                end
            end
        end
    end
    return list
end

local l_tableSortSubFolders
l_tableSortSubFolders = function(theTable, Behavior)
    table.sort(theTable, function(c,d)
        if (Behavior % 2 == 0) or (c.menu and d.menu) or not (c.menu or d.menu) then -- == 0 or 2 (ignored or mixed)
            return string.lower(c.title) < string.lower(d.title)
        else
            if Behavior == 1 then                                 -- == 1 (before)
                return c.menu and true
            else                                                  -- == 3 (after)
                return d.menu and true
            end
        end
    end)
    for _,v in ipairs(theTable) do
        if v.menu then l_tableSortSubFolders(v.menu, Behavior) end
    end
end


local l_sortMenuItems = function(self)
    if self.menuListRawData then
        l_tableSortSubFolders(self.menuListRawData, self.subFolderBehavior)
    end
end

local l_populateMenu = function(self)
    if self.menuUserdata then
        self.menuListRawData = l_generateAppList(self)
        l_sortMenuItems(self)
        collectgarbage() -- we may have just replaced a semi-large data structure
        self.menuLastUpdated = os.date()
    end
    return self
end

local l_updateMenuView = function(self)
    if self.menuUserdata then
        if self.menuView == 0 and self.icon then
            self.menuUserdata:setIcon(self.icon)
            self.menuUserdata:setTitle("")
        else
            self.menuUserdata:setIcon("ASCII:")
            self.menuUserdata:setTitle(self.label)
            if self.menuView == 2 and self.icon then
                self.menuUserdata:setIcon(self.icon)
            end
        end
    end
end

local l_menuViewEval = function(self, x)
    if type(x) ~= "nil" then
        local y = tonumber(x) or 0
        if type(x) == "string" then
            if string.lower(x) == "icon"  then y = 0 end
            if string.lower(x) == "label" then y = 1 end
            if string.lower(x) == "both"  then y = 2 end
        end
        self.menuView = y
        l_updateMenuView(self)
    end
    return self.menuView
end

local l_subFolderEval = function(self, x)
    if type(x) ~= "nil" then
        local y = tonumber(x) or 0
        if type(x) == "string" then
            if string.lower(x) == "ignore" then y = 0 end
            if string.lower(x) == "before" then y = 1 end
            if string.lower(x) == "mixed"  then y = 2 end
            if string.lower(x) == "after"  then y = 3 end
        end
        local populateNeeded = (y == 0) or (self.subFolderBehavior == 0)
        self.subFolderBehavior = y
        if populateNeeded then
            l_populateMenu(self)
        else
            l_sortMenuItems(self)
        end
    end
    return self.subFolderBehavior
end

local l_doFileListMenu = function(self, mods)
    self.triggerMods = mods
    if mods["ctrl"] then
        return {
            { title = self.label.." fileListMenu" },
            { title = "Open "..self.root.." in Finder", fn = function() os.execute([[open -a Finder "]]..self.root..[["]]) end },
            { title = "-" },
            { title = "Sub Directories - Ignore",  checked = ( self.subFolderBehavior == 0 ), fn = function() l_subFolderEval(self, 0) end },
            { title = "Sub Directories - Before",  checked = ( self.subFolderBehavior == 1 ), fn = function() l_subFolderEval(self, 1) end },
            { title = "Sub Directories - Mixed",   checked = ( self.subFolderBehavior == 2 ), fn = function() l_subFolderEval(self, 2) end },
            { title = "Sub Directories - After",   checked = ( self.subFolderBehavior == 3 ), fn = function() l_subFolderEval(self, 3) end },
            { title = "Prune Empty Directories",   checked = ( self.pruneEmpty ), fn = function() self.pruneEmpty = not self.pruneEmpty ; l_populateMenu(self) end },
            { title = "-" },
            { title = "Show Icon",                 checked = ( self.menuView == 0 ),          fn = function() l_menuViewEval(self, 0) end  },
            { title = "Show Label",                checked = ( self.menuView == 1 ),          fn = function() l_menuViewEval(self, 1) end  },
            { title = "Show Both",                 checked = ( self.menuView == 2 ),          fn = function() l_menuViewEval(self, 2) end  },
            { title = "-" },
            { title = "Repopulate Now", fn = function() l_populateMenu(self) end },
            { title = "-" },
            { title = "List generated: "..self.menuLastUpdated, disabled = true },
            { title = "Last change seen: "..self.lastChangeSeen, disabled = true },
            { title = "-" },
            { title = "Remove Menu", fn = function() self:deactivate() end  },
        }
    else
        if not self.menuListRawData then l_populateMenu(self) end
        return self.menuListRawData
    end
end

local l_changeWatcher = function(self, paths)
    local doUpdate = false
    local name, path
    for _, v in pairs(paths) do
        name = string.sub(v,string.match(v, '^.*()/')+1)
        path = string.sub(v, 1, string.match(v, '^.*()/')-1)
        if type(self.matchCriteria) == "string" then
            if name:match(self.matchCriteria) then
                doUpdate = true
                break
            end
        elseif type(self.matchCriteria) == "function" then
            local accept, _ = self.matchCriteria(name, path, "update")
            if accept then
                doUpdate = true
                break
            end
        end
    end
    if doUpdate then
        self.lastChangeSeen = os.date()
        self.menuListRawdata = nil        -- only rebuild when they actually look at it
        collectgarbage()
--        l_populateMenu(self)
        -- need some sense of how often this occurs... may remove or make option in the future
--        hs.notify.new(nil,{title="Menu "..self.label.." Updated",subTitle=name}):send()
        if self.warnings then print("Menu "..self.label.." Updated: "..name) end
    end
end

local l_deactivateMenu = function(self)
    if self.menuUserdata then
        self.watcher:stop()
        self.menuUserdata:delete()
    end
    self.watcher = nil
    self.menuListRawData = nil
    self.menuUserdata = nil
    collectgarbage()
    return self
end

local l_activateMenu = function(self)
    if not self.menuUserdata then
        self.menuUserdata = hs.menubar.new()
        self.watcher = hs.pathwatcher.new(self.root, function(paths) l_changeWatcher(self, paths) end):start()
        l_updateMenuView(self)
        self.menuUserdata:setMenu(function(mods) return l_doFileListMenu(self, mods) end)
    end
    return self
end

local mt_fileListMenu = {
    __index = {
        menuIcon       = function(self, x) if type(x) ~= "nil" then self.icon = x ;  l_updateMenuView(self) end ; return self.icon  end,
        menuLabel      = function(self, x) if type(x) ~= "nil" then self.label = x ; l_updateMenuView(self) end ; return self.label end,
        showForMenu    = l_menuViewEval,
        subFolders     = l_subFolderEval,
        subFolderDepth = function(self, x) if type(x) ~= "nil" then self.maxDepth = x       ; l_populateMenu(self) end ; return self.maxDepth       end,
        menuCriteria   = function(self, x) if type(x) ~= "nil" then self.matchCriteria = x  ; l_populateMenu(self) end ; return self.matchCriteria  end,
        actionFunction = function(self, x) if type(x) ~= "nil" then self.template = x                              end ; return self.template       end,
        folderFunction = function(self, x) if type(x) ~= "nil" then self.folderTemplate = x                        end ; return self.folderTemplate end,
        showWarnings   = function(self, x) if type(x) ~= "nil" then self.warnings = x                              end ; return self.warnings       end,
        rootDirectory  = function(self, x) if type(x) ~= "nil" then self.root = x           ; l_populateMenu(self) end ; return self.root           end,
        pruneEmptyDirs = function(self, x) if type(x) ~= "nil" then self.pruneEmpty = x                            end ; return self.pruneEmpty     end,
        activate       = l_activateMenu,
        deactivate     = l_deactivateMenu,

        subFolderBehavior = 0,
        menuView          = 0,
        matchCriteria     = "([^/]+)%.app$",
        template          = function(x) hs.application.launchOrFocus(x) end,
        folderTemplate    = function(x) os.execute([[open -a Finder "]]..x..[["]]) end,
        root              = "/Applications",
        menuLastUpdated   = "not yet",
        lastChangeSeen    = "not yet",
        warnings          = false,
        pruneEmpty        = true,
        maxDepth          = 10,
        triggerMods       = {},
    },
    __gc = function(self)
        return self:l_deactivateMenu()
    end,
    __tostring = function(self)
        return "This is the state data for menu "..self.label.."."
    end,
}
-- Public interface ------------------------------------------------------

module.new = function(menuLabel)
    local tmp = {}
    local menuLabel = menuLabel or tostring(tmp)
    tmp.label = menuLabel
    return setmetatable(tmp, mt_fileListMenu)
end

module.delete = function(self)
    if self then
        self:deactivate()
        setmetatable(self, nil)
    end
    return nil
end

-- Return Module Object --------------------------------------------------

return module
