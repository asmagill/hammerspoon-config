local module = {
--[=[
    _NAME        = 'typee',
    _VERSION     = 'the 1st digit of Pi/0',
    _URL         = 'https://github.com/asmagill/hammerspoon-config',
    _LICENSE     = [[ See README.md ]]
    _DESCRIPTION = [[]],
    _TODO        = [[
                        document
                        support completion
                        support position of input box
                        support left/center/right justify of input
    ]]

--]=]
}

local _mt_index = {}

local mods     = require("hs._asm.extras").mods
local modal    = require("hs.hotkey").modal
local keycodes = require("hs.keycodes").map

local drawing  = require("hs.drawing")
local timer    = require("hs.timer")
local screen   = require("hs.screen")

-- private variables and methods -----------------------------------------

local drawCursor = function(self)
    local frame = screen.mainScreen():frame()
    local cursorPos = {
--                        x = frame.x + frame.w/2 +                             -- screen midpoint + (1/2 input) - (input - (position + .5))
--                                (self.input:len() / 2) * self.displayBlockWidth) -
--                                (self.input:len() - (self.textCursor.position + .5)) * self.displayBlockWidth,
--         Reduces to:
                        x = frame.x + frame.w/2 + (self.textCursor.position - ((self.input:len() + 1) / 2)) * self.displayBlockWidth,
                        y = frame.y + frame.h/2 - self.displayBlockHeight / 2,
                      }
    if self.textCursor.visible then
        self.textCursor.image:hide()
--        self.textCursor.rect:hide()
        self.textCursor.visible = false
    else
        self.textCursor.image:setTopLeft(cursorPos):show()
--        self.textCursor.rect:setTopLeft(cursorPos):show()
        self.textCursor.visible = true
    end
end

local drawText = function(self)
    self.cursorTimer:stop() ; self.textCursor.visible = true ; drawCursor(self) -- force cursor to disappear
    local frame = screen.mainScreen():frame()
    local textFrame = {
                        x = frame.x + frame.w/2 - (self.input:len() * self.displayBlockWidth) / 2,
                        y = frame.y + frame.h/2 - self.displayBlockHeight / 2,
                        h = self.displayBlockHeight,
                        w = (self.input:len() * self.displayBlockWidth),
                      }
    self.textInputBlock:setFrame(textFrame):setText(self.input):show()
--    self.textInputRect:setFrame(textFrame):show()
    self.cursorTimer:start() -- we now return you to your regularly scheduled cursor
end

local keyEntered = function(self, keyName)
    if self.specialKeys[keyName] then
        keyName = self.specialKeys[keyName](self)
    end
    if keyName then
        if self.historyPosition ~= 0 then self.historyPosition = 0 end
        self.input = self.input:sub(1, self.textCursor.position) .. keyName ..
                          self.input:sub(self.textCursor.position+1, self.input:len())
        self.textCursor.position = self.textCursor.position + keyName:len()
        drawText(self)
    end
end

_mt_index.beginCapture = function(self, startingText)
    startingText = (type(startingText) ~= "nil") and tostring(startingText) or ""
    self.input = startingText
    self.historyPosition = 0
    self.backupInput = ""
    self.typees:enter()
end

_mt_index.endCapture = function(self)
    if self.input ~= "" then
        table.insert(self.history, 1, self.input)
    end
    self.typees:exit()
end

local doNothingFunction = function() return nil end

local doKey_up = function(self)
    if self.historyPosition < #self.history then
        if self.historyPosition == 0 then self.backupInput = self.input end
        self.historyPosition = self.historyPosition + 1
        self.input = self.history[self.historyPosition]
        self.textCursor.position =
            (self.textCursor.position > self.input:len()) and self.input:len() or self.textCursor.position
        drawText(self)
    end
end

local doKey_down = function(self)
    if self.historyPosition > 0 then
        self.historyPosition = self.historyPosition - 1
        if self.historyPosition == 0 then
            self.input = self.backupInput
        else
            self.input = self.history[self.historyPosition]
        end
        self.textCursor.position =
            (self.textCursor.position > self.input:len()) and self.input:len() or self.textCursor.position
        drawText(self)
    end
end

local doKey_pageup = function(self)
    if self.historyPosition ~= #self.history then
        if self.historyPosition == 0 then self.backupInput = self.input end
        self.historyPosition = #self.history
        self.input = self.history[self.historyPosition]
        self.textCursor.position =
            (self.textCursor.position > self.input:len()) and self.input:len() or self.textCursor.position
        drawText(self)
    end
end

local doKey_pagedown = function(self)
    if self.historyPosition ~= 0 then
        self.historyPosition = 0
        self.input = self.backupInput
        self.textCursor.position =
            (self.textCursor.position > self.input:len()) and self.input:len() or self.textCursor.position
        drawText(self)
    end
end

local doKey_left = function(self)
    self.textCursor.position = (self.textCursor.position > 0) and (self.textCursor.position - 1) or 0
    drawCursor(self)
end

local doKey_right = function(self)
    self.textCursor.position =
        (self.textCursor.position < self.input:len()) and (self.textCursor.position + 1) or self.input:len()
    drawCursor(self)
end

local doKey_padclear = function(self)
    if self.historyPosition ~= 0 then self.historyPostion = 0 end
    self.input = ""
    self.textCursor.position = 0
    drawText(self)
end

local doKey_home = function(self)
    self.textCursor.position = 0
    drawCursor(self)
end

local doKey_end = function(self)
    self.textCursor.position = self.input:len()
    drawCursor(self)
end

local doKey_forwarddelete = function(self)
    if self.historyPosition ~= 0 then self.historyPostion = 0 end
    self.input = self.input:sub(1,self.textCursor.position)..
        self.input:sub(self.textCursor.position + 2, self.input:len())
    drawText(self)
end

local doKey_delete = function(self)
    if self.historyPosition ~= 0 then self.historyPostion = 0 end
    if self.textCursor.position > 0 then
        self.input = self.input:sub(1,self.textCursor.position - 1)..
            self.input:sub(self.textCursor.position + 1, self.input:len())
        self.textCursor.position = self.textCursor.position - 1
        drawText(self)
    end
end

local doKey_escape = function(self)
    self.input = ""
    self:endCapture()
    self.exitHook(false)
end

local doKey_enter = function(self)
    self:endCapture()
    self.exitHook(true)
end

local _mt_typee = {
    __index = _mt_index,
--    __gc = function(self) self:endCapture() end,
    __tostring = function(self)
        return "This is the state data for a typee object"
    end,
}

-- Public interface ------------------------------------------------------

--- hs._asm.typee.new() -> typeeObject
--- Constructor
--- Creates a new typee object.
---
--- Parameters:
---  * None
---
--- Returns:
---  * returns typee object
module.new = function(menuLabel)
    local tmp = setmetatable({}, _mt_typee)

    tmp.typees = modal.new(nil, nil)
        function tmp.typees:entered()
            drawText(tmp)
            tmp.textCursor.position = tmp.input:len()
            tmp.cursorTimer:start()
            tmp.recording = true
        end

        function tmp.typees:exited()
            tmp.textInputBlock:hide()
            tmp.textCursor.image:hide()
            tmp.textInputBlock:hide()
            tmp.textCursor.visible = false
            tmp.cursorTimer:stop()
            tmp.recording = false

        --    tmp.textInputRect:hide()
        --    tmp.textCursor.rect:hide()
        end

        for i,v in pairs(keycodes) do
            if type(i) ~= "number" then
                tmp.typees:bind(mods.casc, i, function() keyEntered(tmp, i) end)
            end
        end

    tmp.exitHook          = function(status) end

    tmp.displayFont       = "Menlo" -- cursor works best with a monospace font
    tmp.displayFontSize   = 48
    tmp.displayBlockHeight= tmp.displayFontSize * 1.5
    tmp.displayBlockWidth = 30
    tmp.displayFontColor  = { red = 1, blue = 1, green = 0, alpha = .8 }
    tmp.textInputBlock    = drawing.text({
                                          x = 0, y = 0, h = tmp.displayBlockHeight, w = tmp.displayBlockWidth
                                      }, "")
                                      :setTextFont(tmp.displayFont)
                                      :setTextSize(tmp.displayFontSize)
                                      :setTextColor(tmp.displayFontColor)
    --tmp.textInputRect    = drawing.rectangle{
    --                                      x = 0, y = 0, h = tmp.displayBlockHeight, w = tmp.displayBlockWidth
    --                                  }
    --                                  :setStrokeColor(tmp.displayFontColor):setStroke(true):setFill(false)
    tmp.textCursor        = {
                                visible = false,
                                image = drawing.text({
                                          x = 0, y = 0, h = tmp.displayBlockHeight, w = tmp.displayBlockWidth
                                      }, "|")
                                      :setTextFont(tmp.displayFont)
                                      :setTextSize(tmp.displayFontSize)
                                      :setTextColor(tmp.displayFontColor),
    --                            rect = drawing.rectangle{
    --                                      x = 0, y = 0, h = tmp.displayBlockHeight, w = tmp.displayBlockWidth
    --                                  }
    --                                  :setStrokeColor(tmp.displayFontColor):setStroke(true):setFill(false),
                                time = .5,
                                position = 0,
                              }

    tmp.historyPosition = 0
    tmp.backupInput = ""
    tmp.history = {}

    tmp.input = ""
    tmp.recording = false
    tmp.cursorTimer = timer.new(tmp.textCursor.time, function() drawCursor(tmp) end)

    tmp.specialKeys = {
        ["f1"]  = doNothingFunction,  ["f2"]  = doNothingFunction,  ["f3"]  = doNothingFunction,  ["f4"]  = doNothingFunction,
        ["f5"]  = doNothingFunction,  ["f6"]  = doNothingFunction,  ["f7"]  = doNothingFunction,  ["f8"]  = doNothingFunction,
        ["f9"]  = doNothingFunction,  ["f10"] = doNothingFunction,  ["f11"] = doNothingFunction,  ["f12"] = doNothingFunction,
        ["f13"] = doNothingFunction,  ["f14"] = doNothingFunction,  ["f15"] = doNothingFunction,  ["f16"] = doNothingFunction,
        ["f17"] = doNothingFunction,  ["f18"] = doNothingFunction,  ["f19"] = doNothingFunction,  ["f20"] = doNothingFunction,

        ["help"]          = doNothingFunction,  -- insert on some keyboards
        ["tab"]           = doNothingFunction,  -- use for completions? must consider...

        ["up"]            = doKey_up,               -- history up
        ["down"]          = doKey_down,             -- history down
        ["left"]          = doKey_left,             -- move left
        ["right"]         = doKey_right,            -- move right

        ["home"]          = doKey_home,             -- line beginning
        ["end"]           = doKey_end,              -- line end
        ["pageup"]        = doKey_pageup,           -- history top
        ["pagedown"]      = doKey_pagedown,         -- history bottom

        ["delete"]        = doKey_delete,           -- delete to the left
        ["padclear"]      = doKey_padclear,         -- clear input
        ["forwarddelete"] = doKey_forwarddelete,    -- delete to the right

        ["escape"]        = doKey_escape,           -- "bad" exit
        ["padenter"]      = doKey_enter,            -- "good" exit
        ["return"]        = doKey_enter,            -- "good" exit

        ["pad-"]  = function() return "-" end,  ["pad."]  = function() return "." end,  ["pad*"]  = function() return "*" end,
        ["pad/"]  = function() return "/" end,  ["pad+"]  = function() return "+" end,  ["pad="]  = function() return "=" end,
        ["pad0"]  = function() return "0" end,  ["pad1"]  = function() return "1" end,  ["pad2"]  = function() return "2" end,
        ["pad3"]  = function() return "3" end,  ["pad4"]  = function() return "4" end,  ["pad5"]  = function() return "5" end,
        ["pad6"]  = function() return "6" end,  ["pad7"]  = function() return "7" end,  ["pad8"]  = function() return "8" end,
        ["pad9"]  = function() return "9" end,  ["space"] = function() return " " end,
    }

    return tmp
end

--- hs._asm.typee:delete() -> nil
--- Method
--- Deletes the typee object.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
module.delete = function(self)
    if self then
        setmetatable(self, nil)
    end
    self = nil
    return self
end

-- Return Module Object --------------------------------------------------

return module

