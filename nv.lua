
-- Note taker/searcher based on code from ventolin found at https://github.com/Hammerspoon/hammerspoon/issues/782

-- support functions

local ss = {}
local utils = {}
ss.u = utils
function utils.splitPath(file)
  local parent = file:match('(.+)/[^/]+$')
  if parent == nil then parent = '.' end
  local filename = file:match('/([^/]+)$')
  if filename == nil then filename = file end
  local ext = filename:match('%.([^.]+)$')
  return parent, filename, ext
end

-- Make a parent dir for a file, don't care if it exists already
function utils.makeParentDir(path)
  local parent, _, _ = utils.splitPath(path)
  local ok, err = hs.fs.mkdir(parent)
  if ok == nil then
    if err == "File exists" then
      ok = true
    end
  end
  return ok, err
end


function utils.fileCreate(path)
  if utils.makeParentDir(path) then
    io.open(path, 'w'):close()
  end
end

function utils.fileExists(name)
  local f = io.open(name,'r')
  if f ~= nil then
    io.close(f)
    return true
  else
    return false
  end
end

function utils.strSplit(str, pat)
  local t = {}  -- NOTE: use {n = 0} in Lua-5.0
  local fpat = "(.-)" .. pat
  local lastEnd = 1
  local s, e, cap = str:find(fpat, 1)
  while s do
    if s ~= 1 or cap ~= "" then
      table.insert(t,cap)
    end
    lastEnd = e+1
    s, e, cap = str:find(fpat, lastEnd)
  end
  if lastEnd <= #str then
    cap = str:sub(lastEnd)
    table.insert(t, cap)
  end
  return t
end




local m = {name = 'Notational Velocity'}

local TITLE_MATCH_WEIGHT = 5
local WIDTH = 60
local ROWS = 15

-- local DEFAULT_PATH = os.getenv('HOME') .. '/Documents/notes'
local DEFAULT_PATH = hs.configdir .. '/_localAssets/notes'
local lastApp = nil
local chooser = nil
local matchCache = {}
local rankCache = {}
local allChoices = nil
local currentPath = DEFAULT_PATH
local lastQueries = {}
local visible = false

-- COMMANDS
local commands = {
  {
    ['text'] = 'Create...',
    ['subText'] = 'Create a new note with the query as filename',
    ['command'] = 'create',
  }
}

-- filters can't be placed in the command table above because chooser choice
-- tables must be serializable.
local commandFilters = {
  ['create'] = function()
    return not ss.u.fileExists(currentPath .. '/' .. chooser:query())
  end,
}
--------------------

local function choiceSort(a, b)
  if a.rank == b.rank then return a.text < b.text end
  return a.rank > b.rank
end

local function getLastQuery()
  return lastQueries[currentPath] or ''
end

local function getAllChoices()
  local iterFn, dirObj = hs.fs.dir(currentPath)
  local item = iterFn(dirObj)
  local choices = {}

  while item do
    local filePath = currentPath .. '/' .. item
    if string.find(item, '^[^%.].-%.md') then
      local paragraph = {}
      local f = io.open(filePath)
      local line = f:read()
      while line ~= nil do
        if string.len(line) > 0 then
          paragraph[#paragraph+1] = line
        end
        line = f:read()
      end
      f:close()
      local contents = table.concat(paragraph, '\n')
      choices[#choices+1] = {
        ['text'] = item,
        ['additionalSearchText'] = contents,
        ['subText'] = paragraph[1],
        ['rank'] = 0,
        ['path'] = filePath,
      }
    end
    item = iterFn(dirObj)
  end

  table.sort(choices, choiceSort)
  return choices
end

local function refocus()
  if lastApp ~= nil then
    lastApp:activate()
    lastApp = nil
  end
end

local function launchEditor(path)
  if not ss.u.fileExists(path) then
    ss.u.fileCreate(path)
  end
  local task = hs.task.new('/usr/bin/open', nil, {'-t', path})
  task:start()
end

local function choiceCallback(choice)
  local query = chooser:query()
  local path

  refocus()
  visible = false
  lastQueries[currentPath] = query

  if choice.command == 'create' then
    path = currentPath .. '/' .. query
  else
    path = choice.path
  end

  if path ~= nil then
    if not string.find(path, '%.md$') then
      path = path .. '.md'
    end
    launchEditor(path)
  end
end

local function getRank(queries, choice)
  local rank = 0
  local choiceText = choice.text:lower()

  for _, q in ipairs(queries) do
    local qq = q:lower()
    local cacheKey = qq .. '|' .. choiceText

    if rankCache[cacheKey] == nil then
      local _, count1 = string.gsub(choiceText, qq, qq)
      local _, count2 = string.gsub(choice.additionalSearchText:lower(), qq, qq)
      -- title match is much more likely to be relevant
      rankCache[cacheKey] = count1 * TITLE_MATCH_WEIGHT + count2
    end

    -- If any single query term doesn't match then we don't match at all
    if rankCache[cacheKey] == 0 then return 0 end

    rank = rank + rankCache[cacheKey]
  end

  return rank
end

local function queryChangedCallback(query)
  if query == '' then
    chooser:choices(allChoices)
  else
    local choices = {}

    if matchCache[query] == nil then
      local queries = ss.u.strSplit(query, ' ')

      for _, aChoice in ipairs(allChoices) do
        aChoice.rank = getRank(queries, aChoice)
        if aChoice.rank > 0 then
          choices[#choices+1] = aChoice
        end
      end

      table.sort(choices, choiceSort)

      -- add commands last, after sorting
      for _, aCommand in ipairs(commands) do
        local filter = commandFilters[aCommand.command]
        if filter ~= nil and filter() then
          choices[#choices+1] = aCommand
        end
      end

      matchCache[query] = choices
    end

    chooser:choices(matchCache[query])
  end
end

function m.toggle(path)
  if chooser ~= nil then
    if visible then
      m.hide()
    else
      m.show(path)
    end
  end
end

function m.show(path)
  if chooser ~= nil then
    lastApp = hs.application.frontmostApplication()
    matchCache = {}
    rankCache = {}
    currentPath = path or DEFAULT_PATH
    chooser:query(getLastQuery())
    allChoices = getAllChoices()
    chooser:show()
    visible = true
  end
end

function m.hide()
  if chooser ~= nil then
    -- hide calls choiceCallback
    chooser:hide()
  end
end

function m.start()
  chooser = hs.chooser.new(choiceCallback)
  chooser:width(WIDTH)
  chooser:rows(ROWS)
  chooser:queryChangedCallback(queryChangedCallback)
  chooser:choices(allChoices)
end

function m.stop()
  if chooser then chooser:delete() end
  chooser = nil
  lastApp = nil
  matchCache = nil
  rankCache = nil
  allChoices = nil
  lastQueries = nil
  commands = nil
end

return m
