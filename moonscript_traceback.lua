local module = {
--[=[
    _NAME        = 'moonscript.traceback.lua',
    _VERSION     = 'the 1st digit of Pi/0',
    _URL         = 'https://github.com/asmagill/hammerspoon-config',
    _LICENSE     = [[ See README.md ]]
    _DESCRIPTION = [[

          debug.traceback supplement for moonscript files

    ]],
--]=]
}

local _verbose = true -- default is to be verbose in operations

-- private variables and methods -----------------------------------------

local moonscript = require("moonscript.base")
local util = require("moonscript.util")
local errors = require("moonscript.errors")

local print_err = function(...)
    local msg = table.concat((function(...)
        local _accum_0 = { }
        local _len_0 = 1
        local _list_0 = {
            ...
        }
        for _index_0 = 1, #_list_0 do
            local v = _list_0[_index_0]
            _accum_0[_len_0] = tostring(v)
            _len_0 = _len_0 + 1
        end
        return _accum_0
    end)(...), "\t")
--    return io.stderr:write(msg .. "\n")
    return msg
end

local moonscript_traceback = function(_err)
    local err = _err
    local trace = debug._preMoonscript_traceback("", 2)

    if err then
        local truncated = errors.truncate_traceback(util.trim(trace))
        local rewritten = errors.rewrite_traceback(truncated, err)
        if rewritten then
            return print_err(rewritten)
        else
            return print_err(table.concat({
              err,
              util.trim(trace)
            }, "\n"))
        end
    end
end

-- Public interface ------------------------------------------------------

module.add = function(verbose)
    verbose = verbose or _verbose
    if not debug._preMoonscript_traceback then
        debug._preMoonscript_traceback = debug.traceback
        debug.traceback = moonscript_traceback
        if verbose then print("++ Moonscript traceback inserted.") end
    elseif debug._preMoonscript_traceback == debug.traceback then
        if verbose then print("++ Moonscript traceback already in place. Doing nothing.") end
    else
        print("++ Backup debug.traceback detected, but debug.traceback isn't ours. Cowardly doing nothing.")
    end
end

module.remove = function(verbose)
    verbose = verbose or _verbose
    if debug._preMoonscript_traceback then
        if debug.traceback == moonscript_traceback then
            debug.traceback = debug._preMoonscript_traceback
            debug._preMoonscript_traceback = nil
            if verbose then print("++ Moonscript traceback removed.") end
        else
            print("++ Backup debug.traceback detected, but debug.traceback isn't ours. Cowardly doing nothing.")
        end
    else
        if verbose then print("++ Moonscript traceback not installed. Doing nothing.") end
    end
end

-- Return Module Object --------------------------------------------------

return module

