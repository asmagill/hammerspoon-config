--
-- Code snippit to check/add LSUIElement to Hammerspoon's Info.plist file
-- if running 10.8, since this entry is required for HS to be able to toggle
-- the dock icon.  Surprisingly it isn't in later versions...
--
-- Save this file as LSUIElementCheck.lua in ~/.hammerspoon/ and add:
--
--   dofile("LSUIElementCheck.lua")
--
-- to the top of your init.lua also located in ~/.hammerspoon/
--

local host    = require("hs.host")
local fnutils = require("hs.fnutils")

local osVersion = host.operatingSystemVersion()

if osVersion.major == 10 and osVersion.minor < 9 then
    local f = io.open(hs.docstrings_json_file:gsub("Resources/docs.json$","Info.plist"), 'r')
    local c = f:read("*a")
    f:close()

    local NeedsFix = true

    local LSUIElementFound = false
    local LSUIElementLine  = 0
    local CloseDictLine    = 0
    local Contents         = fnutils.split(c, "[\r\n]")

    for i,v in ipairs(Contents) do
        if v:match("^</dict>$") then
            CloseDictLine = i
        elseif v:match("\t<key>LSUIElement</key>$") then
            LSUIElementFound = true
            LSUIElementLine  = i
        end
    end

    if LSUIElementFound then
        if Contents[LSUIElementLine + 1]:match("\t<true/>") then
            print("-- Update to LSUIElement already in place.")
            NeedsFix = false
        else
            Contents[LSUIElementLine + 1] = "\t<true/>"
        end
    else
        table.insert(Contents, CloseDictLine, "\t<true/>")
        table.insert(Contents, CloseDictLine, "\t<key>LSUIElement</key>")
    end

    if NeedsFix then
        f = io.open(hs.docstrings_json_file:gsub("Resources/docs.json$","Info.plist"), 'w')
        f:write(table.concat(Contents, "\n"))
        f:close()
        print("-- LSUIElement Updated.  You will need to restart Hammerspoon.")
--
--  Uncomment the following if you want Hammerspoon to restart automatically
--

--        os.execute([[ (while ps -p ]]..hs.processInfo.processID..[[ > /dev/null ; do sleep 1 ; done ; open -a "]]..hs.processInfo.bundlePath..[[" ) & ]])
--        hs._exit(true, true)

    end
else
    print("-- Update to LSUIElement not required for "..host.operatingSystemVersionString())
end