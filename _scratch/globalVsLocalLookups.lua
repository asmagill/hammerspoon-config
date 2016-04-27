-- Hammerspoon/Lua global versus local lookups for a built-in function
--
-- based on http://www.ludicroussoftware.com/blog/2011/11/01/local-v--table-functions/
-- and http://stackoverflow.com/a/20480641

-- In Hammerspoon, MacbookAir6,1:
-- > dofile("/Users/amagill/test.lua")
-- Sample size of   100
--   global lookup average:   0.76152027  stdev:  0.02302169938916
--   local  lookup average:   0.51476572  stdev:  0.016631186701877
--
-- Lua 5.3.2  Copyright (C) 1994-2015 Lua.org, PUC-Rio
-- > dofile("test.lua")
-- Sample size of   100
--   global lookup average:   0.35828007  stdev:  0.013754442376776
--   local  lookup average:   0.25715287  stdev:  0.012281427961801

-- While it is interesting to me that Hammerspoon took almost double the time to run
-- compared to a raw Lua instance, (may have to look into that at some point),
-- a savings of approx a third of a second over 5,000,000 lookups does not justify
-- the loss of readability in my opinion.

local samples = 100

local runTest = function()
    local startTime = os.clock()
    for i = 1, 5000000 do
      local j = math.floor(4.35)
    end
    local gTime = os.clock() - startTime

    local floor = math.floor
    local startTime = os.clock()
    for i = 1, 5000000 do
      local j = floor(4.35)
    end
    local lTime = os.clock() - startTime
    return gTime, lTime
end

local gTotal, lTotal = 0.0, 0.0
local gSumSq, lSumSq = 0.0, 0.0

for i = 1, samples, 1 do
    local gTime, lTime = runTest()
    gTotal = gTotal + gTime
    lTotal = lTotal + lTime
    gSumSq = gSumSq + gTime^2
    lSumSq = lSumSq + lTime^2
end

local gAvg, lAvg = gTotal / samples, lTotal / samples
local gStdev = math.sqrt((samples * gSumSq - gTotal^2) / (samples * (samples - 1)))
local lStdev = math.sqrt((samples * lSumSq - lTotal^2) / (samples * (samples - 1)))

print("Sample size of ", samples)
print("  global lookup average: ", gAvg, "stdev:", gStdev)
print("  local  lookup average: ", lAvg, "stdev:", lStdev)

