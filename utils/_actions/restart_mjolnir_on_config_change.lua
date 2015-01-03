return hs.pathwatcher.new(
    os.getenv("HOME") .. '/.hammerspoon/',
    function (changedfiles)
        local function is_lua_file(filename)
            if string.match(filename, '%.lua$') then print(filename) end
            return string.match(filename, '%.lua$')
        end
        if not require("hs._asm.extras").fnutils_every(changedfiles, is_lua_file) then return end
--        hs.reload()
        print("you might wanna reload!")
    end
):start()
