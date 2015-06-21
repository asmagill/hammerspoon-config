local module = {
--[=[
    _NAME        = 'utils.fonts.lua',
    _VERSION     = 'the 1st digit of Pi/0',
    _URL         = 'https://github.com/asmagill/hammerspoon-config',
    _LICENSE     = [[ See README.md ]]
    _DESCRIPTION = [[
                        Some font related doo-dads until I decide if this and
                        some of the stuff in extras is worth making a module
    ]],
--]=]
}

-- better to create drawing objects, then use setText on them rather than clear and redraw


local screen  = require("hs.screen")
local drawing = require("hs.drawing")
local utf8    = require("hs.utf8_53")

-- private variables and methods -----------------------------------------

-- FontList Display Variables

local fDD = {}
      fDD.fontSize        = 14

      fDD.bgColor         = { red = 0, green = 0, blue = 0, alpha = 0.75 }
      fDD.bgColorLighten  = { red = 0, green = 0, blue = 0, alpha = 0.25 }
      fDD.fgColor         = { red = 1, green = 1, blue = 1, alpha = 1    }
      fDD.rectCornerCurve = 20

      fDD.edgeBuffer      = 20
      fDD.columns         = 4
      fDD.rows            = 25
      fDD.perPage         = fDD.columns * fDD.rows

      fDD.fieldWidth      = 250
      fDD.fieldHeight     = 30

      fDD.blockWidth      = fDD.fieldWidth   + 2
      fDD.blockHeight     = fDD.fieldHeight  + 2

      fDD.neededWidth     = fDD.blockWidth   * fDD.columns
      fDD.neededHeight    = fDD.blockHeight  * fDD.rows
      fDD.bgWidth         = fDD.neededWidth  + fDD.edgeBuffer * 2
      fDD.bgHeight        = fDD.neededHeight + fDD.edgeBuffer * 2

      fDD.fontListObjects = {}
      fDD.beingDisplayed  = false
      fDD.background      = nil
      fDD.previousPage    = -1
      fDD.lastMainScreen  = screen.mainScreen()

-- CharacterSet Display Variables

local cDD = {}          -- CharacterSetDisplayData
      cDD.labelFont       = "Menlo"
      cDD.labelFontSize   = 12
      cDD.charFontSize    = 24

      cDD.bgColor         = { red = 0, green = 0, blue = 0, alpha = 0.75 }
      cDD.bgColorLighten  = { red = 0, green = 0, blue = 0, alpha = 0.25 }
      cDD.fgColor         = { red = 1, green = 1, blue = 1, alpha = 1    }
      cDD.rectCornerCurve = 20

      cDD.edgeBuffer      = 20
      cDD.charWidth       = 72
      cDD.charHeight      = 72
      cDD.columns         = 16
      cDD.rows            = 8
      cDD.perPage         = cDD.columns   * cDD.rows

      cDD.labelWidth      = cDD.charWidth * cDD.columns
      cDD.labelHeight     = 20

      cDD.blockWidth      = cDD.charWidth
      cDD.blockHeight     = cDD.charHeight   + cDD.labelHeight

      cDD.neededWidth     = cDD.blockWidth   * cDD.columns
      cDD.neededHeight    = cDD.blockHeight  * cDD.rows
      cDD.bgWidth         = cDD.neededWidth  + cDD.edgeBuffer * 2
      cDD.bgHeight        = cDD.neededHeight + cDD.edgeBuffer * 2

      cDD.fontSpots       = {}
      cDD.labelSpots      = {}
      cDD.beingDisplayed  = false
      cDD.previousPage    = -1
      cDD.previousFont    = 0
      cDD.background      = nil
      cDD.lastMainScreen  = screen.mainScreen()

-- Public interface ------------------------------------------------------

-- FontListDisplay Functions

module.populateFontList = function()
    local screenFrame = screen.mainScreen():frame()
    local bgX         = screenFrame.x + math.floor((screenFrame.w - fDD.bgWidth ) / 2)
    local bgY         = screenFrame.y + math.floor((screenFrame.h - fDD.bgHeight) / 2)

    if not fDD.background then
        fDD.background      =  drawing.rectangle{
                                          x = bgX,
                                          y = bgY,
                                          w = fDD.bgWidth,
                                          h = fDD.bgHeight
                                      }:setFill(true):setStroke(false):setFillColor(
                                          fDD.bgColor
                                      ):setRoundedRectRadii(fDD.rectCornerCurve, fDD.rectCornerCurve)
        for i = 0, (fDD.columns - 1) do
            for j = 0, (fDD.rows - 1) do
                table.insert(fDD.fontListObjects, drawing.text({
                                  x = bgX + fDD.edgeBuffer + i * fDD.blockWidth,
                                  y = bgY + fDD.edgeBuffer + j * fDD.blockHeight,
                                  h = fDD.fieldHeight,
                                  w = fDD.fieldWidth
                            }, ""):setTextColor(
                                  fDD.fgColor
                            ):setTextSize(fDD.fontSize)
                )
            end
        end
        fDD.beingDisplayed  = false
        fDD.lastMainScreen  = screen.mainScreen()
    end
end

module.lightenFontList = function(toggle)
    if fDD.background then
        if toggle then
            fDD.background:setFillColor(fDD.bgColorLighten)
        else
            fDD.background:setFillColor(fDD.bgColor)
        end
    end
end

module.depopulateFontList = function()
    if fDD.background then
        for _, v in pairs(fDD.fontListObjects) do v:delete() end
        fDD.background:delete()

        fDD.fontListObjects = {}
        fDD.background      = nil
        fDD.beingDisplayed  = false
    end
end

module.displayFontList = function(pageNumber)
--    if cDD.beingDisplayed                        then module.clearCharacterSet()  end
    if screen.mainScreen() ~= fDD.lastMainScreen then module.depopulateFontList() end
    if not fDD.background                        then module.populateFontList()   end

    local fonts       = drawing.fontNames()
    table.sort(fonts)

    pageNumber = pageNumber or fDD.previousPage + 1
    pageNumber = pageNumber % math.ceil(#fonts / fDD.perPage)

    local startAt = pageNumber * fDD.perPage

    if not fDD.beingDisplayed then fDD.background:show() end

    for i = startAt,(startAt + fDD.perPage - 1) do
        local v = fDD.fontListObjects[i + 1 - startAt]
        if (i + 1) <= #fonts then
            v:setTextFont(fonts[i + 1]):setText(tonumber(i)..":  "..fonts[i + 1])
        else
            v:setText("")
        end
        if not fDD.beingDisplayed then v:show() end
    end

    fDD.previousPage = pageNumber
    fDD.beingDisplayed = true

    return pageNumber
end

module.clearFontList = function()
    for _,v in ipairs(fDD.fontListObjects) do
        v:hide()
    end
    fDD.background:hide()
    fDD.beingDisplayed = false
end

-- CharacterSetDisplay Functions

module.populateCharacterSet = function()
    local screenFrame = screen.mainScreen():frame()
    local bgX         = screenFrame.x + math.floor((screenFrame.w - cDD.bgWidth ) / 2)
    local bgY         = screenFrame.y + math.floor((screenFrame.h - cDD.bgHeight) / 2)
    local fonts       = drawing.fontNames()
    table.sort(fonts)

    if not cDD.background then
        cDD.background      =  drawing.rectangle{
                                          x = bgX,
                                          y = bgY,
                                          w = cDD.bgWidth,
                                          h = cDD.bgHeight
                                      }:setFill(true):setStroke(false):setFillColor(
                                          cDD.bgColor
                                      ):setRoundedRectRadii(cDD.rectCornerCurve, cDD.rectCornerCurve)
        for i = 0, (cDD.rows - 1) do
            table.insert(cDD.labelSpots, drawing.text({
                                  x = bgX + cDD.edgeBuffer,
                                  y = bgY + cDD.edgeBuffer + i * cDD.blockHeight,
                                  h = cDD.labelHeight,
                                  w = cDD.labelWidth
                            }, ""):setTextColor(
                                  cDD.fgColor
                            ):setTextFont(cDD.labelFont):setTextSize(cDD.labelFontSize)
            )
            for j = 0, (cDD.columns - 1) do
                table.insert(cDD.fontSpots, drawing.text({
                                  x = bgX + cDD.edgeBuffer + j * cDD.blockWidth,
                                  y = bgY + cDD.edgeBuffer + i * cDD.blockHeight + cDD.labelHeight,
                                  h = cDD.charHeight,
                                  w = cDD.charWidth
                            }, ""):setTextColor(
                                  cDD.fgColor
                            ):setTextFont(fonts[cDD.previousFont + 1]):setTextSize(cDD.charFontSize)
                )
            end
        end
        cDD.beingDisplayed  = false
        cDD.lastMainScreen  = screen.mainScreen()
    end
end

module.lightenCharacterSet = function(toggle)
    if cDD.background then
        if toggle then
            cDD.background:setFillColor(cDD.bgColorLighten)
        else
            cDD.background:setFillColor(cDD.bgColor)
        end
    end
end

module.depopulateCharacterSet = function()
    if cDD.background then
        for _,v in ipairs(cDD.labelSpots) do v:delete() end
        for _,v in ipairs(cDD.fontSpots) do v:delete() end
        cDD.background:delete()

        cDD.background     = nil
        cDD.labelSpots     = {}
        cDD.fontSpots      = {}
        cDD.beingDisplayed = false
    end
end

module.displayCharacterSet = function(fontNumber, pageNumber)
--    if fDD.beingDisplayed                        then module.clearFontList()          end
    if screen.mainScreen() ~= cDD.lastMainScreen then module.depopulateCharacterSet() end
    if not cDD.background                        then module.populateCharacterSet()   end

    local fonts         = drawing.fontNames()
    table.sort(fonts)

    fontNumber = fontNumber or cDD.previousFont
    while (fontNumber < 0) do fontNumber = #fonts + fontNumber end
    fontNumber = fontNumber % #fonts

    if fontNumber ~= cDD.previousFont then
        for _,v in ipairs(cDD.fontSpots) do v:setTextFont(fonts[fontNumber + 1]) end
    end

    pageNumber = pageNumber or cDD.previousPage + 1
    while (pageNumber < 0) do pageNumber = math.ceil(0x110000 / cDD.perPage) + pageNumber end
    pageNumber = pageNumber % math.ceil(0x110000 / cDD.perPage)

    if not cDD.beingDisplayed then cDD.background:show() end

    local startChar = pageNumber * cDD.perPage
    local labelPos  = 0

    for i,v in ipairs(cDD.fontSpots) do
        if (i - 1) % cDD.columns == 0 then
            labelPos = labelPos + 1
            if (startChar + i - 1) < 0x110000 then
                cDD.labelSpots[labelPos]:setText(string.format(
                    fonts[fontNumber + 1].." : U+%04X - U+%04X",
                    startChar + (i - 1),
                    ((startChar + (i - 1) + (cDD.columns - 1)) < 0x110000) and (startChar + (i - 1) + (cDD.columns - 1)) or 0x10FFFF
                ))
            else
                cDD.labelSpots[labelPos]:setText("")
            end
            if not cDD.beingDisplayed then cDD.labelSpots[labelPos]:show() end
        end
        if (startChar + i - 1) < 0x110000 then
            v:setText(
                     utf8.codepointToUTF8(startChar + i - 1)
                    )
        else
            v:setText("")
        end
        if not cDD.beingDisplayed then v:show() end
    end

    cDD.previousFont = fontNumber
    cDD.previousPage = pageNumber
    cDD.beingDisplayed = true

    return fontNumber, pageNumber
end

module.clearCharacterSet = function()
    for _,v in ipairs(cDD.fontSpots) do
        v:hide()
    end
    cDD.background:hide()
    cDD.beingDisplayed = false
end

-- Return Module Object --------------------------------------------------

return module
