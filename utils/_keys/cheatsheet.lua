-- modified from code found at https://github.com/dharmapoudel/hammerspoon-config
--
-- Modified to more closely match my usage style and test some possible additions proposed for hs.application

------------------------------------------------------------------------
--/ Cheatsheet Copycat /--
------------------------------------------------------------------------

-- local commandEnum = {
--       [0] = '⌘',
--       [1] = '⇧ ⌘',
--       [2] = '⌥ ⌘',
--       [3] = '^ ⌥ ⌘',
--       [4] = '⌃ ⌘',
--       [5] = '⇧ ⌃ ⌘',
--       [7] = '',
--       [12] ='⌃',
--       [13] ='⌃',
--     }

-- gleaned from http://superuser.com/questions/415213/mac-app-to-compile-and-reference-keyboard-shortcuts

local commandEnum = {
    [0] = '⌘',
          '⇧⌘',
          '⌥⌘',
          '⌥⇧⌘',
          '⌃⌘',
          '⌃⇧⌘',
          '⌃⌥⌘',
          '⌃⌥⇧⌘',
          '',
          '⇧',
          '⌥',
          '⌥⇧',
          '⌃',
          '⌃⇧',
          '⌃⌥',
          '⌃⌥⇧',
}

-- /System/Library/Frameworks/Carbon.framework/Frameworks/HIToolbox.framework/Headers/Menus.h
local glyphs = {
                    -- kMenuNullGlyph, 0x00, Null (always glyph 1)
    [2] = "⇥",     -- kMenuTabRightGlyph, 0x02, Tab to the right key (for left-to-right script systems)
    [3] = "⇤",     -- kMenuTabLeftGlyph, 0x03, Tab to the left key (for right-to-left script systems)
    [4] = "⌤",     -- kMenuEnterGlyph, 0x04, Enter key
    [5] = "⇧",     -- kMenuShiftGlyph, 0x05, Shift key
    [6] = "⌃",     -- kMenuControlGlyph, 0x06, Control key
    [7] = "⌥",     -- kMenuOptionGlyph, 0x07, Option key
    [9] = "␣",      -- kMenuSpaceGlyph, 0x09, Space (always glyph 3) key
    [10] = "⌦",    -- kMenuDeleteRightGlyph, 0x0A, Delete to the right key (for right-to-left script systems)
    [11] = "↩",    -- kMenuReturnGlyph, 0x0B, Return key (for left-to-right script systems)
    [12] = "↪",    -- kMenuReturnR2LGlyph, 0x0C, Return key (for right-to-left script systems)
                    -- kMenuNonmarkingReturnGlyph, 0x0D, Nonmarking return key
    [15] = "",    -- kMenuPencilGlyph, 0x0F, Pencil key
    [16] = "↓",     -- kMenuDownwardArrowDashedGlyph, 0x10, Downward dashed arrow key
    [17] = "⌘",    -- kMenuCommandGlyph, 0x11, Command key
    [18] = "✓",    -- kMenuCheckmarkGlyph, 0x12, Checkmark key
    [19] = "⃟",    -- kMenuDiamondGlyph, 0x13, Diamond key
    [20] = "",     -- kMenuAppleLogoFilledGlyph, 0x14, Apple logo key (filled)
                    -- kMenuParagraphKoreanGlyph, 0x15, Unassigned (paragraph in Korean)
    [23] = "⌫",    -- kMenuDeleteLeftGlyph, 0x17, Delete to the left key (for left-to-right script systems)
    [24] = "←",    -- kMenuLeftArrowDashedGlyph, 0x18, Leftward dashed arrow key
    [25] = "↑",     -- kMenuUpArrowDashedGlyph, 0x19, Upward dashed arrow key
    [26] = "→",     -- kMenuRightArrowDashedGlyph, 0x1A, Rightward dashed arrow key
    [27] = "⎋",    -- kMenuEscapeGlyph, 0x1B, Escape key
    [28] = "⌧",    -- kMenuClearGlyph, 0x1C, Clear key
    [29] = "『",    -- kMenuLeftDoubleQuotesJapaneseGlyph, 0x1D, Unassigned (left double quotes in Japanese)
    [30] = "』",    -- kMenuRightDoubleQuotesJapaneseGlyph, 0x1E, Unassigned (right double quotes in Japanese)
                    -- kMenuTrademarkJapaneseGlyph, 0x1F, Unassigned (trademark in Japanese)
    [97] = "␢",     -- kMenuBlankGlyph, 0x61, Blank key
    [98] = "⇞",     -- kMenuPageUpGlyph, 0x62, Page up key
    [99] = "⇪",    -- kMenuCapsLockGlyph, 0x63, Caps lock key
    [100] = "←",   -- kMenuLeftArrowGlyph, 0x64, Left arrow key
    [101] = "→",    -- kMenuRightArrowGlyph, 0x65, Right arrow key
    [102] = "↖",   -- kMenuNorthwestArrowGlyph, 0x66, Northwest arrow key
    [103] = "﹖",   -- kMenuHelpGlyph, 0x67, Help key
    [104] = "↑",    -- kMenuUpArrowGlyph, 0x68, Up arrow key
    [105] = "↘",   -- kMenuSoutheastArrowGlyph, 0x69, Southeast arrow key
    [106] = "↓",    -- kMenuDownArrowGlyph, 0x6A, Down arrow key
    [107] = "⇟",    -- kMenuPageDownGlyph, 0x6B, Page down key
                    -- kMenuAppleLogoOutlineGlyph, 0x6C, Apple logo key (outline)
    [109] = "",   -- kMenuContextualMenuGlyph, 0x6D, Contextual menu key
    [110] = "⌽",   -- kMenuPowerGlyph, 0x6E, Power key
    [111] = "F1",   -- kMenuF1Glyph, 0x6F, F1 key
    [112] = "F2",   -- kMenuF2Glyph, 0x70, F2 key
    [113] = "F3",   -- kMenuF3Glyph, 0x71, F3 key
    [114] = "F4",   -- kMenuF4Glyph, 0x72, F4 key
    [115] = "F5",   -- kMenuF5Glyph, 0x73, F5 key
    [116] = "F6",   -- kMenuF6Glyph, 0x74, F6 key
    [117] = "F7",   -- kMenuF7Glyph, 0x75, F7 key
    [118] = "F8",   -- kMenuF8Glyph, 0x76, F8 key
    [119] = "F9",   -- kMenuF9Glyph, 0x77, F9 key
    [120] = "F10",  -- kMenuF10Glyph, 0x78, F10 key
    [121] = "F11",  -- kMenuF11Glyph, 0x79, F11 key
    [122] = "F12",  -- kMenuF12Glyph, 0x7A, F12 key
    [135] = "F13",  -- kMenuF13Glyph, 0x87, F13 key
    [136] = "F14",  -- kMenuF14Glyph, 0x88, F14 key
    [137] = "F15",  -- kMenuF15Glyph, 0x89, F15 key
    [138] = "⎈",   -- kMenuControlISOGlyph, 0x8A, Control key (ISO standard)
    [140] = "⏏",   -- kMenuEjectGlyph, 0x8C, Eject key (available on Mac OS X 10.2 and later)
    [141] = "英数", -- kMenuEisuGlyph, 0x8D, Japanese eisu key (available in Mac OS X 10.4 and later)
    [142] = "かな", -- kMenuKanaGlyph, 0x8E, Japanese kana key (available in Mac OS X 10.4 and later)
    [143] = "F16",  -- kMenuF16Glyph, 0x8F, F16 key (available in SnowLeopard and later)
    [144] = "F17",  -- kMenuF16Glyph, 0x90, F17 key (available in SnowLeopard and later)
    [145] = "F18",  -- kMenuF16Glyph, 0x91, F18 key (available in SnowLeopard and later)
    [146] = "F19",  -- kMenuF16Glyph, 0x92, F19 key (available in SnowLeopard and later)
}

-- make the functions all local so we don't pollute the global namespace

local getAllMenuItems -- forward reference

local getAllMenuItemsTable = function(t)
      local menu = {}
          for pos,val in pairs(t) do
              if(type(val)=="table") then
                  if(val['AXRole'] =="AXMenuBarItem" and type(val['AXChildren']) == "table") then
                      menu[pos] = {}
                      menu[pos]['AXTitle'] = val['AXTitle']
                      menu[pos][1] = getAllMenuItems(val['AXChildren'][1])
                  elseif(val['AXRole'] =="AXMenuItem" and not val['AXChildren']) then
                    if( val['AXMenuItemCmdModifiers'] ~='0' and (val['AXMenuItemCmdChar'] ~='' or type(val['AXMenuItemCmdGlyph']) == "number")) then
                        menu[pos] = {}
                        menu[pos]['AXTitle'] = val['AXTitle']
                        if val['AXMenuItemCmdChar'] == "" then
                            menu[pos]['AXMenuItemCmdChar'] = glyphs[val['AXMenuItemCmdGlyph']] or "?"..tostring(val['AXMenuItemCmdGlyph']).."?"
                        else
                            menu[pos]['AXMenuItemCmdChar'] = val['AXMenuItemCmdChar']
                        end
                        menu[pos]['AXMenuItemCmdModifiers'] = val['AXMenuItemCmdModifiers']
                      end
                  elseif(val['AXRole'] =="AXMenuItem" and type(val['AXChildren']) == "table") then
                      menu[pos] = {}
                      menu[pos][1] = getAllMenuItems(val['AXChildren'][1])
                  end
              end
          end
      return menu
end


getAllMenuItems = function(t)
    local menu = ""
        for pos,val in pairs(t) do
            if(type(val)=="table") then
                -- do not include help menu for now until I find best way to remove menubar items with no shortcuts in them
                if(val['AXRole'] =="AXMenuBarItem" and type(val['AXChildren']) == "table") and val['AXTitle'] ~="Help" then
                    menu = menu.."<ul class='col col"..pos.."'>"
                    menu = menu.."<li class='title'><strong>"..val['AXTitle'].."</strong></li>"
                    menu = menu.. getAllMenuItems(val['AXChildren'][1])
                    menu = menu.."</ul>"
                elseif(val['AXRole'] =="AXMenuItem" and not val['AXChildren']) then
                    if( val['AXMenuItemCmdModifiers'] ~='0' and (val['AXMenuItemCmdChar'] ~='' or type(val['AXMenuItemCmdGlyph']) == "number")) then
                        if val['AXMenuItemCmdChar'] == "" then
                            menu = menu.."<li><div class='cmdModifiers'>"..commandEnum[val['AXMenuItemCmdModifiers']].." "..(glyphs[val['AXMenuItemCmdGlyph']] or "?"..tostring(val['AXMenuItemCmdGlyph']).."?").."</div><div class='cmdtext'>".." "..val['AXTitle'].."</div></li>"
                        else
                            menu = menu.."<li><div class='cmdModifiers'>"..commandEnum[val['AXMenuItemCmdModifiers']].." "..val['AXMenuItemCmdChar'].."</div><div class='cmdtext'>".." "..val['AXTitle'].."</div></li>"
                        end
                    end
                elseif(val['AXRole'] =="AXMenuItem" and type(val['AXChildren']) == "table") then
                    menu = menu..getAllMenuItems(val['AXChildren'][1])
                end

            end
        end
    return menu
end

local generateHtml = function()
    --local focusedApp= hs.window.frontmostWindow():application()
    local focusedApp = require("hs.application").frontmostApplication()
    local appTitle = focusedApp:title()
    local allMenuItems = focusedApp:getMenuItems();
    local myMenuItems = getAllMenuItems(allMenuItems)

    local html = [[
        <!DOCTYPE html>
        <html>
        <head>
        <style type="text/css">
            *{margin:0; padding:0;}
            html, body{
              background-color:#eee;
              font-family: arial;
              font-size: 13px;
            }
            a{
              text-decoration:none;
              color:#000;
              font-size:12px;
            }
            li.title{ text-align:center;}
            ul, li{list-style: inside none; padding: 0 0 5px;}
            footer{
              position: fixed;
              left: 0;
              right: 0;
              height: 48px;
              background-color:#eee;
            }
            header{
              position: fixed;
              top: 0;
              left: 0;
              right: 0;
              height:48px;
              background-color:#eee;
              z-index:99;
            }
            footer{ bottom: 0; }
            header hr,
            footer hr {
              border: 0;
              height: 0;
              border-top: 1px solid rgba(0, 0, 0, 0.1);
              border-bottom: 1px solid rgba(255, 255, 255, 0.3);
            }
            .title{
                padding: 15px;
            }
            li.title{padding: 0  10px 15px}
            .content{
              padding: 0 0 15px;
              font-size:12px;
              overflow:hidden;
            }
            .content.maincontent{
            position: relative;
              height: 577px;
              margin-top: 46px;
            }
            .content > .col{
              width: 23%;
              padding:10px 0 20px 20px;
            }

            li:after{
              visibility: hidden;
              display: block;
              font-size: 0;
              content: " ";
              clear: both;
              height: 0;
            }
            .cmdModifiers{
              width: 60px;
              padding-right: 15px;
              text-align: right;
              float: left;
              font-weight: bold;
            }
            .cmdtext{
              float: left;
              overflow: hidden;
              width: 165px;
            }
        </style>
        </head>
          <body>
            <header>
              <div class="title"><strong>]]..appTitle..[[</strong></div>
              <hr />
            </header>
            <div class="content maincontent">]]..myMenuItems..[[</div>

          <footer>
            <hr />
              <div class="content" >
                <div class="col">
                  by <a href="https://github.com/dharmapoudel" target="_parent">dharma poudel</a>
                </div>
              </div>
          </footer>
          <script src="https://cdnjs.cloudflare.com/ajax/libs/jquery.isotope/2.2.2/isotope.pkgd.min.js"></script>
        	<script type="text/javascript">
              var elem = document.querySelector('.content');
              var iso = new Isotope( elem, {
                // options
                itemSelector: '.col',
                layoutMode: 'masonry'
              });
              console.log("test");
            </script>
          </body>
        </html>
        ]]

    return html
end



-- local myView = nil
--
-- hs.hotkey.bind({"cmd", "alt", "ctrl"}, "C", function()
--   if not myView then
--     myView = hs.webview.new({x = 100, y = 100, w = 1080, h = 600}, { developerExtrasEnabled = true })
--       :windowStyle("utility")
--       :closeOnEscape(true)
--       :html(generateHtml())
--       :allowGestures(true)
--       :windowTitle("CheatSheets")
--       :show()
--     --myView:asHSWindow():focus()
--     --myView:asHSDrawing():setAlpha(.98):bringToFront()
--   else
--     myView:delete()
--     myView=nil
--   end
-- end)

-- I prefer a different type of key invocation/remove setup
local alert  = require("hs.alert")
local hotkey = require("hs.hotkey")
local timer  = require("hs.timer")
local module = {}

local cs = hotkey.modal.new({"cmd", "alt"}, "return")
    function cs:entered()
        alert("Building Cheatsheet Display...")
        -- Wrap in timer so alert has a chance to show when building the display is slow (I'm talking
        -- to you, Safari!).  Using a value of 0 seems to halt the alert animation in mid-sequence,
        -- so we use something almost as "quick" as 0.  Need to look at hs.timer someday and figure out
        -- why; perhaps 0 means "dispatch immediately, even before anything else in the queue"?
        timer.doAfter(.1, function()
            local screenFrame = require("hs.screen").mainScreen():frame()
            local viewFrame = {
                x = screenFrame.x + 100,
                y = screenFrame.y + 100,
                h = screenFrame.h - 200,
                w = screenFrame.w - 200,
            }
            module.myView = require("hs.webview").new(viewFrame, { developerExtrasEnabled = true })
              :windowStyle("utility")
              :closeOnEscape(true)
              :html(generateHtml())
              :allowGestures(true)
              :windowTitle("CheatSheets")
              :setLevel(require("hs.drawing").windowLevels.floating)
              :show()
              alert.closeAll() -- hide alert, if we finish fast enough
        end)
    end
    function cs:exited()
        module.myView:delete()
        module.myView=nil
    end
cs:bind({}, "ESCAPE", function() cs:exit() end)
cs:bind({"cmd", "alt"}, "return", function() cs:exit() end) -- match the invoker, in case you're used to that

return module