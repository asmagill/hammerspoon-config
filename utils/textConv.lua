local module = {}

local utf8    = require("hs.utf8")
local fnutils = require("hs.fnutils")

-- Also need way to convert in string while preserving UTF8
-- option to skip converting cr,lf,tab? yes in string one... in char one too?

module.visibleCtrlChar = function(char)
    if type(char) == "number" and char < 32 then char = string.char(char) end
    if type(char) ~= "string" or char:len() ~= 1 or char:byte() > 31 then
        return char
    else
        return utf8.codepointToUTF8(char:byte() + 0x2400)
    end
end

--- {PATH}.{MODULE}.hexDump(string [, count]) -> string
--- Function
--- Treats the input string as a binary blob and returns a prettied up hex dump of it's contents. By default, a newline character is inserted after every 16 bytes, though this can be changed by also providing the optional count argument.  This is useful with the results of `{PATH}.{MODULE}.userDataToString` or `string.dump` for debugging and the curious, and may also provide some help with troubleshooting utf8 data that is being mis-handled or corrupted.
module.hexDump = function(stuff, linemax)
    local ascii = ""
    local count = 0
    local linemax = tonumber(linemax) or 16
    local buffer = ""
    local rb = ""
    local offset = math.floor(math.log(#stuff,16)) + 1
    offset = offset + (offset % 2)

    local formatstr = "%0"..tostring(offset).."x : %-"..tostring(linemax * 3).."s : %s"

    for c in string.gmatch(tostring(stuff), ".") do
        buffer = buffer..string.format("%02X ",string.byte(c))
        -- using string.gsub(c,"%c",".") didn't work in Hydra, but I didn't dig any deeper -- this works.
        if string.byte(c) < 32 or string.byte(c) > 126 then
            ascii = ascii.."."
        else
            ascii = ascii..c
        end
        count = count + 1
        if count % linemax == 0 then
            rb = rb .. string.format(formatstr, count - linemax, buffer, ascii) .. "\n"
            buffer=""
            ascii=""
        end
    end
    if count % linemax ~= 0 then
        rb = rb .. string.format(formatstr, count - (count % linemax), buffer, ascii) .. "\n"
    end
    return rb
end

--- {PATH}.{MODULE}.asciiOnly(string[, all]) -> string
--- Function
--- Returns the provided string with all non-printable ascii characters (except for Return, Linefeed, and Tab unless `all` is provided and is true) escaped as \x## so that it can be safely printed in the {TARGET} console, rather than result in an uninformative '(null)'.  Note that this will break up Unicode characters into their individual bytes.
function module.asciiOnly(theString, all)
    local all = all or false
    if type(theString) == "string" then
        if all then
            return (theString:gsub("[\x00-\x1f\x7f-\xff]",function(a)
                    return string.format("\\x%02X",string.byte(a))
                end))
        else
            return (theString:gsub("[\x00-\x08\x0b\x0c\x0e-\x1f\x7f-\xff]",function(a)
                    return string.format("\\x%02X",string.byte(a))
                end))
        end
    else
        error("string expected", 2) ;
    end
end

return module