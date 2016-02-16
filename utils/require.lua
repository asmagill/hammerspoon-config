--- === utils.requirePlus ===
---
--- Some useful additions to requiring stuff
---

local module = {}

local luafs = require("hs.fs")

-- private variables and methods -----------------------------------------

---- Public interface ------------------------------------------------------

--- utils.requirePlus.requirePath(path[, output]) -> table-of-modules
--- Function
--- Parses `package.path` and `package.cpath` by appending `path` to it and seeing what modules or files may exist at each location for loading, then requires them.  If `output` is true, then a log message is printed to the hammerspoon console for each file loaded. This function returns a table whose individual keys contain the loaded modules.
---
--- This only checks at the level of `path` for a match to ?.lua or ?/init.lua (or ?.so).  It does not recurse further subdirectories.  Load order is unspecified, so each module must (they really should anyways) make sure to require anything necessary for their successful loading internally, and not assume a specific load order.
---
module.requirePath = function(path, output)
    local prefix, _ = string.gsub(path,"/",".")
    local prefix_dir, _ = string.gsub(path,"%.","/")
    local package_list, loaded = {}, {}

    for dir, ending in package.path:gmatch("([%w%._/-]+)%?([%w_/-]*.lua);?") do
        if luafs.attributes(dir.."/"..prefix_dir) then
            for name in luafs.dir(dir.."/"..prefix_dir) do
                local pkg = name:match("([%w_]+)"..ending.."$")
                if pkg then
                    if not package_list[pkg] then package_list[pkg] = true end
                end
            end
        end
    end

    for dir, ending in package.cpath:gmatch("([%w%._/-]+)%?([%w_/-]*.so);?") do
        if luafs.attributes(dir.."/"..prefix_dir) then
            for name in luafs.dir(dir.."/"..prefix_dir) do
                local pkg = name:match("([%w_]+)"..ending.."$")
                if pkg then
                    if not package_list[pkg] then package_list[pkg] = true end
                end
            end
        end
    end

    if output then print("++ Load: "..prefix.." -") end
    for i,v in pairs(package_list) do
        if output then print("         "..prefix.."."..i) end
        loaded[i] = require(prefix.."."..i)
    end

    return loaded
end

--- utils.requirePlus.updatePaths(label, command|table[, append])
--- Function
--- Updates package.path and package.cpath with the output of command or the contents of table.  Label is used to identify the source of the added paths in the output to the hammerspoon console.  If `append` is true, then the new paths are attached to the end of `path` and `cpath`, otherwise they are attached to the beginning.  Duplicates are pruned from the added paths.
---
--- If the additional paths are provided by a table, then the first entry should contain paths to add to package.path and the second entry to package.cpath.  If the additional paths are from a command, then they are assumed to be from a command similar to `luarocks path`, which prints lines suitable for including in a shell configuration script, and that the first line is for package.path, and the second is for package.cpath.
---
---     $ luarocks path
---     export LUA_PATH='/usr/local/share/lua/5.2/?.lua;...'
---     export LUA_CPATH='/usr/local/lib/lua/5.2/?.so;...'
---
module.updatePaths = function(label, command, append)
    print("++ Updating paths for '"..label.."'...")
    local paths = { "", "" }

    if type(command) == "string" then
        command = tostring(command)
        local results, _, _, rc = hs.execute(command, true)
        if rc ~= 0 then
            print("\tFailed: rc="..rc.." output="..results.." command="..command)
        else
            paths = table.pack(results:match("='(.*)'%s.*='(.*)'"))
        end
    elseif type(command) == "table" then
        paths = command
    else
        print("\tInvalid command specifier: ("..type(command)..") "..tostring(command))
    end
    if append then
        package.path = package.path..";"..paths[1]
        package.cpath = package.cpath..";"..paths[2]
    else
        package.path = paths[1]..";"..package.path
        package.cpath = paths[2]..";"..package.cpath
    end
    local singlepaths, singlecpaths = {}, {}
    for test_path, sep in string.gmatch(package.path,"([^;]+)(;?)") do
        if not singlepaths[test_path] then
            singlepaths[test_path] = true
            singlepaths[#singlepaths+1] = test_path
        end
    end
    for test_path, sep in string.gmatch(package.cpath,"([^;]+)(;?)") do
        if not singlecpaths[test_path] then
            singlecpaths[test_path] = true
            singlecpaths[#singlecpaths+1] = test_path
        end
    end
    package.path = table.concat(singlepaths, ";") ;
    package.cpath = table.concat(singlecpaths, ";") ;
end

-- Return Module Object --------------------------------------------------

return module
