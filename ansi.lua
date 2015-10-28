-- largely based on the code at https://github.com/balthamos/geektool-3/blob/ac91b2d03c4f6002b007695f5b0ce73514eb291f/NerdTool/classes/ANSIEscapeHelper.m but adjusted for lua and Hammerspoon's hs.styledtext in particular

-- convert ansi color sequences into styledtext, take 1

local drawing    = require("hs.drawing")
local color      = require("hs.drawing.color")
local styledtext = require("hs.styledtext")

-- "adjustFontStyle" indicates that we will need to modify the font in some way... it results in a "font"
--     attribute change.
-- "remove" is a place holder to indicate that the specified code has an effect on the attribute named.

local sgrCodeToAttributes = {
    [  0] = { adjustFontStyle    = "remove",
              backgroundColor    = "remove",
              color              = "remove",
              underlineStyle     = "remove",
              strikethroughStyle = "remove",
            },

    [  1] = { adjustFontStyle = true  }, -- increased intensity; generally bold, if the font isn't already
    [  2] = { adjustFontStyle = false }, -- fainter intensity; generally not available in fixed pitch fonts, but try
    [  3] = { adjustFontStyle = styledtext.fontTraits.italicFont },
    [ 22] = { adjustFontStyle = "remove" },

    [  4] = { underlineStyle = styledtext.lineStyles.single },
    [ 21] = { underlineStyle = styledtext.lineStyles.double },
    [ 24] = { underlineStyle = styledtext.lineStyles.none },

    [  9] = { strikethroughStyle = styledtext.lineStyles.single },
    [ 29] = { strikethroughStyle = styledtext.lineStyles.none },

    [ 30] = { color = color.colorsFor("ansiTerminalColors").fgBlack },
    [ 31] = { color = color.colorsFor("ansiTerminalColors").fgRed },
    [ 32] = { color = color.colorsFor("ansiTerminalColors").fgGreen },
    [ 33] = { color = color.colorsFor("ansiTerminalColors").fgYellow },
    [ 34] = { color = color.colorsFor("ansiTerminalColors").fgBlue },
    [ 35] = { color = color.colorsFor("ansiTerminalColors").fgMagenta },
    [ 36] = { color = color.colorsFor("ansiTerminalColors").fgCyan },
    [ 37] = { color = color.colorsFor("ansiTerminalColors").fgWhite },

-- if we want to add more colors (not official ANSI, but somewhat supported):
--       38;5;#m for 256 colors (supported in OSX Terminal and in xterm)
--       38;2;#;#;#m for rgb color (not in Terminal, but is in xterm)
--     [ 38] = { color = "special" },
    [ 39] = { color = "remove" },

    [ 90] = { color = color.colorsFor("ansiTerminalColors").fgBrightBlack },
    [ 91] = { color = color.colorsFor("ansiTerminalColors").fgBrightRed },
    [ 92] = { color = color.colorsFor("ansiTerminalColors").fgBrightGreen },
    [ 93] = { color = color.colorsFor("ansiTerminalColors").fgBrightYellow },
    [ 94] = { color = color.colorsFor("ansiTerminalColors").fgBrightBlue },
    [ 95] = { color = color.colorsFor("ansiTerminalColors").fgBrightMagenta },
    [ 96] = { color = color.colorsFor("ansiTerminalColors").fgBrightCyan },
    [ 97] = { color = color.colorsFor("ansiTerminalColors").fgBrightWhite },

    [ 40] = { backgroundColor = color.colorsFor("ansiTerminalColors").bgBlack },
    [ 41] = { backgroundColor = color.colorsFor("ansiTerminalColors").bgRed },
    [ 42] = { backgroundColor = color.colorsFor("ansiTerminalColors").bgGreen },
    [ 43] = { backgroundColor = color.colorsFor("ansiTerminalColors").bgYellow },
    [ 44] = { backgroundColor = color.colorsFor("ansiTerminalColors").bgBlue },
    [ 45] = { backgroundColor = color.colorsFor("ansiTerminalColors").bgMagenta },
    [ 46] = { backgroundColor = color.colorsFor("ansiTerminalColors").bgCyan },
    [ 47] = { backgroundColor = color.colorsFor("ansiTerminalColors").bgWhite },

-- if we want to add more colors (not official ANSI, but somewhat supported):
--       48;5;#m for 256 colors (supported in OSX Terminal and in xterm)
--       48;2;#;#;#m for rgb color (not in Terminal, but is in xterm)
--     [ 48] = { backgroundColor = "special" },
    [ 49] = { backgroundColor = "remove" },

    [100] = { backgroundColor = color.colorsFor("ansiTerminalColors").bgBrightBlack },
    [101] = { backgroundColor = color.colorsFor("ansiTerminalColors").bgBrightRed },
    [102] = { backgroundColor = color.colorsFor("ansiTerminalColors").bgBrightGreen },
    [103] = { backgroundColor = color.colorsFor("ansiTerminalColors").bgBrightYellow },
    [104] = { backgroundColor = color.colorsFor("ansiTerminalColors").bgBrightBlue },
    [105] = { backgroundColor = color.colorsFor("ansiTerminalColors").bgBrightMagenta },
    [106] = { backgroundColor = color.colorsFor("ansiTerminalColors").bgBrightCyan },
    [107] = { backgroundColor = color.colorsFor("ansiTerminalColors").bgBrightWhite },
}

local convertToStyledText = function(rawText, attr)
    assert(type(rawText) == "string", "string expected")

-- used for font bold and italic changes.
--    if no attr table is specified, assume the hs.drawing default font
--    if a table w/out font is specified, assume the NSAttributedString default (Helvetica at 12.0)
    local baseFont
    if type(attr) == "nil" then baseFont = drawing.defaultTextStyle().font end
    local baseFont = baseFont or (attr and attr.font) or { name = "Helvetica", size = 12.0 }

-- generate clean string and locate ANSI codes
    local cleanString = ""
    local formatCodes = {}
    local index = 1

    while true do
        local s, e = rawText:find("\27[", index, true)
        if s then
            local code, codes = 0, {}
            local incodeIndex = 1
            while true do
                local c = rawText:sub(e + incodeIndex, e + incodeIndex):byte()
                if 48 <= c and c <= 57 then       -- "0" - "9"
                    code = (code == 0) and (c - 48) or (code * 10 + (c - 48))
                elseif c == 109 then              -- "m", the terminator for SGR
                    table.insert(codes, code)
                    break
                elseif c == 59 then               -- ";" multi-code sequence separator
                    table.insert(codes, code)
                    code = 0
                elseif 64 <= c and c <= 126 then  -- other terminators indicate this is a sequence we ignore
                    codes = {}
                    break
                end
                incodeIndex = incodeIndex + 1
            end
            cleanString = cleanString .. rawText:sub(index, s - 1)
            if #codes > 0 then
                for i = 1, #codes, 1 do
                    table.insert(formatCodes, { #cleanString + 1, codes[i] })
                end
            end
            index = e + incodeIndex + 1
        else
            cleanString = cleanString .. rawText:sub(index)
            break
        end
    end

-- create base string with clean string and specified attributes, if any
    local newString = styledtext.new(cleanString, attr or {})

-- iterate through codes and determine what style attributes to apply
    for i = 1, #formatCodes, 1 do
        local s, code = formatCodes[i][1], formatCodes[i][2]
        if code ~= 0 then                                             -- skip reset everything code
            local action = sgrCodeToAttributes[code]
            if action then                                            -- only do codes we recognize
               for k, v in pairs(action) do
                  if not(type(v) == "string" and v == "remove") then  -- skip placeholder to turn something off
                      local e, newAttribute = #cleanString, {} -- end defaults to the end of the string
-- scan for what turns us off
                      for j = i + 1, #formatCodes, 1 do
                          local nextAction =  sgrCodeToAttributes[formatCodes[j][2]]
                          if nextAction[k] then
                              e = formatCodes[j][1] - 1 -- adjust the actual end point since something later resets it
                              break
                          end
                      end
-- apply the style now that we have an end point
                      if k == "adjustFontStyle" then
                          newAttribute.font = styledtext.convertFont(baseFont, v)
                      else
                          newAttribute[k] = v
                      end
                      newString = newString:modifyStyle(newAttribute, s, e)
                  end
               end
            end
        end
    end

    return newString
end

return convertToStyledText