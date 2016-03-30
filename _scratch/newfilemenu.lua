local fs = require("hs.fs")
local pw = require("hs.pathwatcher")

module = {}

local stopWatching = function(self)
    if type(self.watcher) == "table" then
        for _,v in ipairs(self.watcher) do v:stop() end
    else
        self.watcher:stop()
    end
    self.watcher = nil
    return self
end

local watcherBody = function(self, paths)
end

local doUpdate = function(self)
    if type(self.root) == "string" then
        watcherBody(self, paths)
    elseif type(self.root) == "table" then
        self.watcher = {}
        for i,v in pairs(self.root) do
            watcherBody(self, paths)
        end
    end
    return self
end

local activate = function(self)
    if type(self.root) == "string" then
        self.watcher = pw.new(self.root, function(paths)
                                             watcherBody(self, paths)
                                         end):start()
        doUpdate(self)
    elseif type(self.root) == "table" then
        self.watcher = {}
        for i,v in pairs(self.root) do
            table.insert(self.watcher, pw.new(v, function(paths)
                                                     watcherBody(self, paths)
                                                 end):start())
        end
        doUpdate(self)
    end
    return self
end

local mt_menubuilder = {
    __init = {
        activate         = activate,
        stopWatching     = stopWatching,

        subFolderSorting = function(self, x)
                              if type(x) ~= "nil" then
                                  local y = tonumber(x) or 0
                                  if type(x) == "string" then
                                      if string.lower(x) == "ignore" then y = 0 end
                                      if string.lower(x) == "before" then y = 1 end
                                      if string.lower(x) == "mixed"  then y = 2 end
                                      if string.lower(x) == "after"  then y = 3 end
                                  end
                                  self.subFolderBehavior = y
                                  return doUpdate(self)
                              end
                              return self.subFolderBehavior
                          end,
        subFolderDepth   = function(self, x)
                              if type(x) == "number" then
                                  self.maxDepth = x
                                  return doUpdate(self)
                              end
                              return self.maxDepth
                          end,
        showWarnings     = function(self, x)
                              if type(x) == "boolean" then
                                  self.warnings = x
                              end
                              return self.warnings
                          end,
        rootDirectory    = function(self, x)
                              if type(x) == "string" or type(x) == "table" then
                                  self.root = x
                                  return doUpdate(self)
                              end
                              return self.root
                          end,
        menuCriteria     = function(self, x)
                              if type(x) ~= "nil" then
                                  self.matchCriteria = x
                                  return doUpdate(self)
                              end
                              return self.matchCriteria
                          end,
        pruneEmptyDirs   = function(self, x)
                              if type(x) ~= "nil" then
                                  self.pruneEmpty = x
                                  return doUpdate(self)
                              end
                              return self.pruneEmpty
                          end,
        actionFunction   = function(self, x)
                              if type(x) == "function" then
                                  self.template = x
                                  return doUpdate(self)
                              end
                              return self.template
                          end,
        folderFunction   = function(self, x)
                              if type(x) == "function" then
                                  self.folderTemplate = x
                                  return doUpdate(self)
                              end
                              return self.folderTemplate
                          end,

    -- default and place holder values
        subFolderBehavior = 0,
        matchCriteria     = "([^/]+)%.app$",
        template          = function(x) hs.application.launchOrFocus(x) end,
        folderTemplate    = function(x) os.execute([[open -a Finder "]]..x..[["]]) end,
        root              = "/Applications",
        lastChangeSeen    = "not yet",
        warnings          = false,
        pruneEmpty        = true,
        maxDepth          = 10,
    },
    __tostring = function(self)
        return "state information for "..self.label
    end,
    __gc = function(self)
        self:stopWatching()
    end,
}

module.new = function(label)
    local tmp = {}
    label = tostring(label) or tostring(tmp)
    tmp.label = label
    return setmetatable(tmp, mt_menubuilder)
end

return module