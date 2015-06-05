local module = {
--[=[
    _NAME        = 'fileListMenu.lua',
    _VERSION     = '0.1',
    _URL         = 'https://github.com/asmagill/hammerspoon-config',
    _DESCRIPTION = [[ applicationMenu to replace XMenu and the like ]],
    _TODO        = [[
                        add hs.pathwatcher to detect changes that may require updating the menu
                        add hs.settings to store state so reload/restart of HS doesn't require repopulate
                        can I speed this up at all?  via hs.fs?
    ]],
    _LICENSE     = [[ See README.md ]]
--]=]
}

-- private variables and methods -----------------------------------------

local shellExec = function(command)
    local f = io.popen(command, 'r')
    local s = f:read('*a')
    local status, exit_type, rc = f:close()
    return s, status, exit_type, rc
end

local l_generateAppList -- because this function is recursive, we have to pre-declare it to keep it local
l_generateAppList = function(self, startDir, expression)
    local list = {}
-- get files at this level -- we want a label and a path
    string.gsub(
        shellExec([[find -EL "]]..startDir..[[" -regex '.*/]]..expression..[[' -maxdepth 1]]),
        "[^\r\n]+",
        function(c)
            local l = c:gsub([[^]]..startDir..[[/]],"")
            local _, _, nl = string.find(c:gsub([[^]]..startDir..[[/]],""), expression:gsub("\\.","%%."))
            l = nl or l
            list[#list+1] = { l, c }
        end
    )
    if self.subFolderBehavior ~= 0 then
-- get sub-dirs at this level -- we want a label and a table -- recursion!
        string.gsub(
            shellExec([[find -EL "]]..startDir..[[" -type d ! -regex '.*/]]..expression..[[' -maxdepth 1]]),
            "[^\r\n]+",
            function(c)
                if c ~= startDir then
                    local subDirs = l_generateAppList(self, c, expression)
                    if next(subDirs) ~= nil then
                        list[#list+1] = { c:gsub([[^]]..startDir..[[/]],""), subDirs, c }
                    end
                end
            end
        )
    end
    return list
end

local l_backupMenuListData = function(self) print("backupMenuListData not yet immplemented") end

local l_generateMenu -- because this function is recursive, we have to pre-declare it to keep it local
l_generateMenu = function(self, menuPart)
    local list = {}
    for _,v in ipairs(menuPart) do
        if type(v[2]) ~= "table" then
            table.insert(list, { title = v[1], fn = function() self.template(v[2]) end })
        else
            table.insert(list, { title = v[1], menu = l_generateMenu(self, v[2]), fn = function() os.execute([[open -a Finder "]]..v[3]..[["]]) end })
        end
    end
    return list
end

local l_tableSortSubFolders
l_tableSortSubFolders = function(theTable, Behavior)
    table.sort(theTable, function(c,d)
        if (type(c[2]) == type(d[2])) or (Behavior % 2 == 0) then -- == 0 or 2 (ignored or mixed)
            return string.lower(c[1]) < string.lower(d[1])
        else
            if Behavior == 1 then                                 -- == 1 (before)
                return type(c[2]) == "table"
            else                                                  -- == 3 (after)
                return type(d[2]) == "table"
            end
        end
    end)
    for _,v in ipairs(theTable) do
        if type(v[2]) == "table" then l_tableSortSubFolders(v[2], Behavior) end
    end
end


local l_sortMenuItems = function(self)
    if self.menuListRawData then
        l_tableSortSubFolders(self.menuListRawData, self.subFolderBehavior)
        self.actualMenuTable = l_generateMenu(self, self.menuListRawData)
    end
end

local l_populateMenu = function(self)
    hs.alert.show("Populating menu...")
    self.menuListRawData = l_generateAppList(self, self.root, self.matchCriteria)
    l_sortMenuItems(self)
    self.menuLastUpdated = os.date()
    collectgarbage() -- we may have just replaced a semi-large data structure
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
    if x then
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
    if x then
        local y = tonumber(x) or 0
        if type(x) == "string" then
            if string.lower(x) == "ignore" then y = 0 end
            if string.lower(x) == "before" then y = 1 end
            if string.lower(x) == "mixed"  then y = 2 end
            if string.lower(x) == "after"  then y = 3 end
        end
        self.subFolderBehavior = y
        l_sortMenuItems(self)
    end
    return self.subFolderBehavior
end

local l_changeDetectionEval = function(self, x)
    if x then
        local y = tonumber(x) or 0
        if type(x) == "string" then
            if string.lower(x) == "ignore"     then y = 0 end
            if string.lower(x) == "silent"     then y = 1 end
            if string.lower(x) == "notify"     then y = 2 end
            if string.lower(x) == "repopulate" then y = 3 end
        end
        self.changeBehavior = y
    end
    return self.changeBehavior
end

local l_doFileListMenu = function(self, mods)
    if mods["ctrl"] then
        return {
            { title = self.label.." fileListMenu" },
            { title = "Open "..self.root.." in Finder", fn = function() os.execute([[open -a Finder "]]..self.root..[["]]) end },
            { title = "-" },
            { title = "Sub Directories - Before",  checked = ( self.subFolderBehavior == 1 ), fn = function() l_subFolderEval(self, 1) end,       disabled = (self.subFolderBehavior == 0) },
            { title = "Sub Directories - Mixed",   checked = ( self.subFolderBehavior == 2 ), fn = function() l_subFolderEval(self, 2) end,       disabled = (self.subFolderBehavior == 0) },
            { title = "Sub Directories - After",   checked = ( self.subFolderBehavior == 3 ), fn = function() l_subFolderEval(self, 3) end,       disabled = (self.subFolderBehavior == 0) },
            { title = "-" },
            { title = "File Changes - Ignore",     checked = ( self.changeBehavior == 0 ),    fn = function() l_changeDetectionEval(self, 0) end, disabled = true },
            { title = "File Changes - Silent",     checked = ( self.changeBehavior == 1 ),    fn = function() l_changeDetectionEval(self, 1) end, disabled = true },
            { title = "File Changes - Notify",     checked = ( self.changeBehavior == 2 ),    fn = function() l_changeDetectionEval(self, 2) end, disabled = true },
            { title = "File Changes - Repopulate", checked = ( self.changeBehavior == 3 ),    fn = function() l_changeDetectionEval(self, 3) end, disabled = true },
            { title = "-" },
            { title = "Show Icon",                 checked = ( self.menuView == 0 ),          fn = function() l_menuViewEval(self, 0) end        },
            { title = "Show Label",                checked = ( self.menuView == 1 ),          fn = function() l_menuViewEval(self, 1) end        },
            { title = "Show Both",                 checked = ( self.menuView == 2 ),          fn = function() l_menuViewEval(self, 2) end        },
            { title = "-" },
            { title = "Repopulate Now", fn = function() l_populateMenu(self) end },
            { title = "-" },
            { title = "List generated: "..self.menuLastUpdated, disabled = true },
            { title = "Last change seen: "..self.lastChangeSeen, disabled = true },
            { title = "-" },
            { title = "Remove Menu", fn = function() self:deactivate() end  },
        }
    else
        if not self.actualMenuTable then
            return { { title = "Populate...", fn = function() l_populateMenu(self) end } }
        else
            return self.actualMenuTable
        end
    end
end

local l_deactivateMenu = function(self)
    if self.menuUserdata then
        if self.storageLabel then l_backupMenuListData(self) end
        self.menuUserdata:delete()
    end
    self.menuUserdata = nil
    collectgarbage()
    return self
end

local l_activateMenu = function(self)
    if self.menuUserdata then
        hs.alert.show("Menu '"..self.label.."' already present... bug?")
    else
        self.menuUserdata = hs.menubar.new()
        l_updateMenuView(self)
        self.menuUserdata:setMenu(function(mods) return l_doFileListMenu(self, mods) end)
    end
    return self
end

local mt_fileListMenu = {
    __index = {
        menuIcon        = function(self, x) if x then self.icon = x ;  l_updateMenuView(self) end ; return self.icon  end,
        menuLabel       = function(self, x) if x then self.label = x ; l_updateMenuView(self) end ; return self.label end,
        showForMenu     = l_menuViewEval,
        subFolders      = l_subFolderEval,
        changeDetect    = l_changeDetectionEval,
        menuCriteria    = function(self, x) if x and not self.menuUserdata then self.matchCriteria = x end ; return self.matchCriteria end,
        actionFunction  = function(self, x) if x and not self.menuUserdata then self.template = x      end ; return self.template      end,
        rootDirectory   = function(self, x) if x and not self.menuUserdata then self.root = x          end ; return self.root          end,
        storageKey      = function(self, x) if x and not self.menuUserdata then self.settingsKey = x   end ; return self.settingsKey   end,
        populate        = l_populateMenu,
        activate        = l_activateMenu,
        deactivate      = l_deactivateMenu,

        subFolderBehavior = 0,
        changeBehavior    = 0,
        menuView          = 0,
        matchCriteria     = "([^/]+)\\.app$",
        template          = function(x) hs.application.launchOrFocus(x) end,
        root              = "/Applications",
        menuLastUpdated   = "not yet",
        lastChangeSeen    = "not yet",
    },
    __gc = function(self)
        return self:l_deactivateMenu()
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
        collectgarbage()
    end
    return nil
end

-- Return Module Object --------------------------------------------------

return module
