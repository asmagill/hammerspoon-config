-- Doc tools

local module = {}
local fnutils = require("hs.fnutils")

module.rdoc = function(thing)
    if type(thing) ~= "table" then
        print("rdoc(docObject, filename) -- Output recursive documentation dump.")
    else
        print(thing)
        print("--------------------------------------------------------------------------------")
        print()
        for name, item in fnutils.sortByKeys(thing)
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