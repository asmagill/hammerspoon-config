-- Doc tools

local module = {}

local sorted_keys = function(t, f)
    if t then
        local a = {}
        for n in pairs(t) do table.insert(a, n) end
        table.sort(a, f)
        local i = 0      -- iterator variable
        local iter = function ()   -- iterator function
            i = i + 1
            if a[i] == nil then return nil
                else return a[i], t[a[i]]
            end
        end
        return iter
    else
        return function() return nil end
    end
end

module.rdoc = function(thing)
    if type(thing) ~= "table" then
        print("rdoc(docObject, filename) -- Output recursive documentation dump.")
    else
        print(thing)
        print("--------------------------------------------------------------------------------")
        print()
        for name, item in sorted_keys(thing,  function(m,n)
                                                  if type(m) == type(n) then
                                                      return m < n
                                                  else
                                                      return tostring(m) < tostring(n)
                                                  end
                                              end)
        do
            if type(item) == "table" then module.rdoc(item) end
        end
    end
end

module.fdoc = function(thing, file)
    if type(thing) ~= "table" or type(file) ~= "string" then
        print("fdoc(docObject, filename) -- Output recursive documentation dump to file.")
    else
        local f  = io.open(file, "w+")
        local op = print
        local np = function(a)
            if type(a) == "nil" then
                f:write("\n\n")
            else
                f:write(tostring(a))
            end
        end

        print = np
        module.rdoc(thing)
        f:close()
        print = op
        print("File '"..file.."' has been written.")
    end
end

return module