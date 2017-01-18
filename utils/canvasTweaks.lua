-- testing extension to canvas which allows referencing canvas elements by id as well
-- as index
-- testing and will probably add it to core at some point

local canvas = require "hs.canvas"

-- see if it's already working in case we get loaded twice or I forget to remove this once
-- core is updated...
local sample = canvas.new{}:appendElements({{id="byID", type="rectangle"}})
if not sample.byID then
    local canvasMT = hs.getObjectMetatable("hs.canvas")
    local originalIndex = canvasMT.__index
    canvasMT.__index = function(self, key)
        local value = originalIndex(self, key)
        if not value and type(key) == "string" then
            for i, v in ipairs(self) do
                if v.id == key then
                    value = v
                    break
                end
            end
        end
        return value
    end
end
sample:delete()

return canvas
