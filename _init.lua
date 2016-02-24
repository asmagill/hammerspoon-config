print("-- "..os.date())

inspect = require("hs.inspect")
inspect1 = function(what) return inspect(what, {depth=1}) end
inspect2 = function(what) return inspect(what, {depth=2}) end
inspectnm = function(what) return inspect(what ,{process=function(item,path) if path[#path] == inspect.METATABLE then return nil else return item end end}) end
inspectnm1 = function(what) return inspect(what ,{process=function(item,path) if path[#path] == inspect.METATABLE then return nil else return item end end, depth=1}) end

isinf = function(x) return x == math.huge end
isnan = function(x) return x ~= x end

tobits = function(num, bits)
    bits = bits or (math.floor(math.log(num,2) / 8) + 1) * 8
    if bits == -(1/0) then bits = 8 end
    local value = ""
    for i = (bits - 1), 0, -1 do
        value = value..tostring((num >> i) & 0x1)
    end
    return value
end
