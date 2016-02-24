return require("hs.pathwatcher").new(
    hs.configdir,
    function (changedfiles)
        local function is_lua_file(filename)
            if string.match(filename, '%.lua$') then print(filename) end
            return string.match(filename, '%.lua$')
        end
        if not require("hs.fnutils").every(changedfiles, is_lua_file) then return end
--        hs.reload()
        print("you might wanna reload!")
    end
):start()
