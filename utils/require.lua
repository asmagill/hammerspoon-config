--- === utils.require ===
---
--- A module which can be used to override the built in require and provide some additional features, including the ability to `unrequire` lua based modules, require an entire directory at a time, etc.
---
--- Suggested use is by adding the following at the top of your ~/.hammerspoon/init.lua file:
---
---     require = require("utils.require")
---
---
local module = {}

local luafs = require("hs.fs")

-- private variables and methods -----------------------------------------

local builtin_require = require
local require_mt = {
    __call = function(_, ...) return module.require(...) end
}

-- if user_env is true, invoke user's shell as an interactive login shell to
-- ensure full paths, etc.  If false or not provided, skip this, as it does
-- add overhead to commands that don't require special paths or environment
-- variables set.
local shell_exec = function(command, user_env)
    local f
    if user_env then
        f = io.popen(os.getenv("SHELL").." -l -i -c \""..command.."\"", 'r')
    else
        f = io.popen(command, 'r')
    end
    local s = f:read('*a')
    local status, exit_type, rc = f:close()
    return s, status, exit_type, rc
end

-- Public interface ------------------------------------------------------

--- utils.require.load_order[]
--- Variable
--- Array of require and unrequire actions taken on modules in the order in which they occurred.  Each entry contains { name = "pkg", require|unrequire = true }.  This array is cleared only by utils.require.clearall() or by a has.reload().
module.load_order = {}

--- utils.require.loaded[]
--- Variable
--- Table of modules loaded, where the module name is the key and the module itself is the value.
module.loaded = {}

--- utils.require.clearall()
--- Function
--- Clears all required modules that this tool has managed from package.loaded[...], the internally maintained array, utils.require.loaded[...], and _G[...] (if it is equal to a package itself).  This is an attempt to remove all loaded modules as completely as possible without actually restarting the Lua state. Note that binary modules (those from a compiled language) require a has.reload(), as there is no way to unload a dynamically loaded library without resetting the Lua state.
---
module.clearall = function()
    for i,v in pairs(module.loaded) do module.unrequire(i) end
    module.load_order = {}
    collectgarbage()
end

--- utils.require.unrequire(pkg)
--- Function
--- Clears pkg, if it was loaded by this tool, from package.loaded[pkg], the internally maintained array, utils.require.loaded[pkg], and _G[pkg] (if it is equal to the package itself).  This is an attempt to remove a module as completely as possible, perhaps so a modified version can be reloaded, without requiring a restart. Note that binary modules (those from a compiled language) require a has.reload(), as there is no way to unload a dynamically loaded library without resetting the Lua state.
---
module.unrequire = function(pkg)
    if module.loaded[pkg] then
        if package.loaded[pkg] == module.loaded[pkg] then package.loaded[pkg] = nil end
        local root = _G
        for part, sep in string.gmatch(pkg, "([%w_]+)(%.?)") do
            if sep == "." then
                if type(root[part]) == "table" then
                    root = root[part]
                else
                    break
                end
            else
                if root[part] == module.loaded[pkg] then root[part] = nil end
            end
        end
        module.loaded[pkg] = nil
        table.insert(module.load_order, { name = pkg, unrequire = true })
        collectgarbage()
    else
        error("Pacakge "..pkg.." not loaded, so no unrequire possible.",2)
    end
end

--- utils.require.require(pkg)
--- Function
--- Our require function, which tracks loaded modules for removal via unrequire/clearall.  If you load this module and assign it to `require`, then all subsequent require invocations will be tracked by this module.
---
---     e.g. require = require("..path../require")
---
--- The metatable __call function for this module is set to invoke this function, so with the above example, you can override the builtin require function to use this version instead.
---
module.require = function(pkg)
    if type(pkg) ~= "string" then
        error("bad argument #1 to 'require' (string expected, got "..type(pkg)..")", 2)
    end
    local pkg, _ = string.gsub(pkg,"/",".")
    if module.loaded[pkg] then return module.loaded[pkg] end

    table.insert(module.load_order, { name = pkg, require = true })
    local good, value = xpcall(builtin_require, debug.traceback, pkg)
    if good then
        if type(value) == "nil" then
            module.loaded[pkg] = true
        else
            module.loaded[pkg] = value
        end
        return module.loaded[pkg]
    else
        table.remove(module.load_order)
        error("Unable to load required file "..pkg..": \n"..tostring(value),2)
    end
end

--- utils.require.reset()
--- Function
--- Resets the `require` function back to the version stored when this module was loaded (which is likely the builtin version, unless you've loaded another module which overrides the `require` function for it's own reasons).  This function will only reset the `require` function if it is equal to this module.
---
module.reset = function()
    if type(require) == "table" and require == module then
        require = builtin_require
    end
end

--- utils.require.require_path(path[, output]) -> table-of-modules
--- Function
--- Parses `package.path` and `package.cpath` by appending `path` to it and seeing what modules or files may exist at each location for loading, then requires them.  If `output` is true, then a log message is printed to the hammerspoon console for each file loaded. This function returns a table whose individual keys contain the loaded modules.
---
--- This only checks at the level of `path` for a match to ?.lua or ?/init.lua (or ?.so).  It does not recurse further subdirectories.  Load order is unspecified, so each module must (they really should anyways) make sure to require anything necessary for their successful loading internally, and not assume a specific load order.
---
module.require_path = function(path, output)
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

    if output then print("Loading '"..prefix.."' modules") end
    for i,v in pairs(package_list) do
        if output then print("\tincluding "..prefix.."."..i) end
        loaded[i] = require(prefix.."."..i)
    end

    return loaded
end

--- utils.require.update_require_paths(label, command|table[, append])
--- Function
--- Updates package.path and package.cpath with the output of command or the contents of table.  Label is used to identify the source of the added paths in the output to the hammerspoon console.  If `append` is true, then the new paths are attached to the end of `path` and `cpath`, otherwise they are attached to the beginning.  Duplicates are pruned from the added paths.
---
--- If the additional paths are provided by a table, then the first entry should contain paths to add to package.path and the second entry to package.cpath.  If the additional paths are from a command, then they are assumed to be from a command similar to `luarocks path`, which prints lines suitable for including in a shell configuration script, and that the first line is for package.path, and the second is for package.cpath.
---
---     $ luarocks path
---     export LUA_PATH='/usr/local/share/lua/5.2/?.lua;...'
---     export LUA_CPATH='/usr/local/lib/lua/5.2/?.so;...'
---
module.update_require_paths = function(label, command, append)
    print("Updating paths for '"..label.."'...")
    local paths = { "", "" }

    if type(command) == "string" then
        command = tostring(command)
        local results, _, _, rc = shell_exec(command, true)
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

setmetatable(module, require_mt)

return module
