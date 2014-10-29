return hs.pathwatcher.new(
        os.getenv("HOME") .. '/.hammerspoon/',
       function (changedfiles)
            local function is_lua_file(filename)
                if string.match(filename, '%.lua$') then print(filename) end
                return string.match(filename, '%.lua$')
            end
            if not hs.fnutils.every(changedfiles, is_lua_file) then return end
--             hammerspoon.reload()
            print("you better reload!")
        end
    ):start()
