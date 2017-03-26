-- modified from code found at https://github.com/dharmapoudel/hammerspoon-config
--
-- Modified to more closely match my usage style

-- I prefer a different type of key invocation/remove setup
local alert    = require("hs.alert")
local hotkey   = require("hs.hotkey")
local timer    = require("hs.timer")
local eventtap = require("hs.eventtap")
local notify   = require("hs.notify")
local distributednotifications = require"hs.distributednotifications"
local fnutils  = require "hs.fnutils"

local watchables = require("hs.watchable")

local events   = eventtap.event.types

local module   = {}

module.watchables = watchables.new("cheatsheet", true)

module.autoDismiss     = true
module.showEmptyMenus  = false
module.cmdKeyPressTime = 3.5

-- module.bgColor  = "#bbd" -- "#eee"
module.bgColor  = "#003f3f"
module.fgColor  = "#fff"
module.alpha    = 0.85

module.font     = "arial"
module.fontSize = 12


------------------------------------------------------------------------
--/ Cheatsheet Copycat /--
------------------------------------------------------------------------

-- gleaned from http://superuser.com/questions/415213/mac-app-to-compile-and-reference-keyboard-shortcuts

--local commandEnum = {
--    [0] = '⌘',
--          '⇧⌘',
--          '⌥⌘',
--          '⌥⇧⌘',
--          '⌃⌘',
--          '⌃⇧⌘',
--          '⌃⌥⌘',
--          '⌃⌥⇧⌘',
--          '',
--          '⇧',
--          '⌥',
--          '⌥⇧',
--          '⌃',
--          '⌃⇧',
--          '⌃⌥',
--          '⌃⌥⇧',
--}

local modifiersToString = function(mods)
    if type(mods) ~= "table" then
        print("~~ unrecognized type for menu shortcut modifier map: " .. type(mods))
        retrn ""
    end

    local map, result = {}, ""
    for i,v in ipairs(mods) do map[v] = true end
    if map["ctrl"] then
        result = result .. "⌃"
        map["ctrl"] = nil
    end
    if map["alt"] then
        result = result .. "⌥"
        map["alt"] = nil
    end
    if map["shift"] then
        result = result .. "⇧"
        map["shift"] = nil
    end
    if map["cmd"] then
        result = result .. "⌘"
        map["cmd"] = nil
    end
    if next(map) then
        print("~~ unrecognized modifier in menu shortcut map: { " .. table.concat(mods, ", ") .. " }")
    end
    return result
end

local glyphs = require("hs.application").menuGlyphs

local getAllMenuItems -- forward reference, since we're called recursively
getAllMenuItems = function(t)
    local menu = ""
        for pos,val in pairs(t) do
            if(type(val)=="table") then
                if(val['AXRole'] =="AXMenuBarItem" and type(val['AXChildren']) == "table") then
                    local menuDetails = getAllMenuItems(val['AXChildren'][1])
                    if module.showEmptyMenus or menuDetails ~= "" then
                        menu = menu.."<ul class='col col"..pos.."'>"
                        menu = menu.."<li class='title'><strong>"..val['AXTitle'].."</strong></li>"
                        menu = menu.. menuDetails
                        menu = menu.."</ul>"
                    end
                elseif(val['AXRole'] =="AXMenuItem" and not val['AXChildren']) then
                    if( val['AXMenuItemCmdModifiers'] ~='0' and (val['AXMenuItemCmdChar'] ~='' or type(val['AXMenuItemCmdGlyph']) == "number")) then
                        if val['AXMenuItemCmdChar'] == "" then
--                           menu = menu.."<li><div class='cmdModifiers'>"..(commandEnum[val['AXMenuItemCmdModifiers']] or tostring(val['AXMenuItemCmdModifiers']).."?").." "..(glyphs[val['AXMenuItemCmdGlyph']] or "?"..tostring(val['AXMenuItemCmdGlyph']).."?").."</div><div class='cmdtext'>".." "..val['AXTitle'].."</div></li>"
                            menu = menu.."<li><div class='cmdModifiers'>"..modifiersToString(val['AXMenuItemCmdModifiers']).." "..(glyphs[val['AXMenuItemCmdGlyph']] or "?"..tostring(val['AXMenuItemCmdGlyph']).."?").."</div><div class='cmdtext'>".." "..val['AXTitle'].."</div></li>"
                        else
--                           menu = menu.."<li><div class='cmdModifiers'>"..(commandEnum[val['AXMenuItemCmdModifiers']] or tostring(val['AXMenuItemCmdModifiers']).."?").." "..val['AXMenuItemCmdChar'].."</div><div class='cmdtext'>".." "..val['AXTitle'].."</div></li>"
                            menu = menu.."<li><div class='cmdModifiers'>"..modifiersToString(val['AXMenuItemCmdModifiers']).." "..val['AXMenuItemCmdChar'].."</div><div class='cmdtext'>".." "..val['AXTitle'].."</div></li>"
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
              background-color:]]..module.bgColor..[[;
              font-family: ]]..module.font..[[;
              font-size: ]]..module.fontSize..[[px;
              color: ]]..module.fgColor..[[;
            }
            a{
              text-decoration:none;
              color:#000;
              font-size: ]]..module.fontSize..[[px;
            }
            li.title{ text-align:center;}
            ul, li{list-style: inside none; padding: 0 0 5px;}
            footer{
              position: fixed;
              left: 0;
              right: 0;
              height: 48px;
              background-color:]]..module.bgColor..[[;
            }
            header{
              position: fixed;
              top: 0;
              left: 0;
              right: 0;
              height:48px;
              background-color:]]..module.bgColor..[[;
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
              font-size: ]]..module.fontSize..[[px;
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
              width: 65px;
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
<!--          <script src="https://cdnjs.cloudflare.com/ajax/libs/jquery.isotope/2.2.2/isotope.pkgd.min.js"></script> -->
          <script src="http://localhost:7734/isotope.pkgd.min.js"></script>
          <script type="text/javascript">
            var elem = document.querySelector('.content');
            var iso = new Isotope( elem, {
              // options
              itemSelector: '.col',
              layoutMode: 'masonry'
            });
          </script>
          </body>
        </html>
        ]]

    return html
end

-- We use a modal hotkey setup as a convenient wrapper which gives us an enter and an exit method for
-- generating the display, but we don't actually assign any keys

module.cs = hotkey.modal.new()
    function module.cs:entered()
        local screenFrame = require("hs.screen").mainScreen():frame()
        local viewFrame = {
            x = screenFrame.x + 50,
            y = screenFrame.y + 50,
            h = screenFrame.h - 100,
            w = screenFrame.w - 100,
        }
        module.myView = require("hs.webview").new(viewFrame, { developerExtrasEnabled = true })
          :windowStyle("utility")
          :closeOnEscape(true)
          :allowGestures(true)
          :windowTitle("CheatSheets")
          :level(require("hs.drawing").windowLevels.floating)
          :alpha(module.alpha or 1.0)
          :show()
        timer.doAfter(.1, function()
            local htmlOutput = generateHtml()
            -- make sure it hasn't been cleared already since the generation can be slow (Safari!)
            if module.myView then module.myView:html(htmlOutput) end
        end)
    end
    function module.cs:exited()
        module.myView:delete()
        module.myView=nil
    end
module.cs:bind({}, "escape", function() module.cs:exit() end)

-- mimic CheatSheet's trigger for holding Command Key
module.cmdPressed = false
module.eventwatcher = eventtap.new({events.flagsChanged}, function(ev)
    module.cmdPressed = false
    local count = 0
    for k, v in pairs(ev:getFlags()) do count = count + 1 end
    if module.myView == nil and count == 1 and ev:getFlags().cmd then
        module.cmdPressed = true
    end

    if module.cmdPressed then
        module.countDown = timer.doAfter(module.cmdKeyPressTime, function()
            module.cs:enter()
            module.cmdPressed = false
        end)
        module.eventwatcher2 = eventtap.new({events.flagsChanged, events.keyDown, events.leftMouseDown}, function(ev)
            if module.countDown then
                module.countDown:stop()
                module.countDown = nil
            end
            if module.myView ~= nil and module.autoDismiss then module.cs:exit() end
            module.eventwatcher2:stop()
            module.eventwatcher2 = nil
            module.eventwatcher:start()
            return false
        end):start()
        module.eventwatcher:stop()
    end
    return false ;
end):start()

module.remoteAccessWatcher = distributednotifications.new(function(n,o,i)
    local vn = i and i.ViewerNames or nil
    if not vn then
        print("~~ com.apple.remotedesktop.viewerNames with unknown details: object = " .. tostring(o) .. ", info = " .. tostring(i))
    else
        if #vn > 0 and module.eventwatcher:isEnabled() then
            notify.show("Remote Viewer Detected", "...disabling Cmd-Key Cheatsheat", "", "")
--            module.eventwatcher:stop()
            module.watchables.enabled = false
        elseif #vn == 0 and not module.eventwatcher:isEnabled() then
            notify.show("Remote Viewer Left", "...re-enabling Cmd-Key Cheatsheat", "", "")
--            module.eventwatcher:start()
            module.watchables.enabled = true
        end
--        module.watchables.enabled = module.eventwatcher:isEnabled()
    end
end, "com.apple.remotedesktop.viewerNames"):start()

module.toggle = function()
--    if module.eventwatcher:isEnabled() then
--        module.eventwatcher:stop()
--    else
--        module.eventwatcher:start()
--    end
--    module.watchables.enabled = module.eventwatcher:isEnabled()
   module.watchables.enabled = not module.watchables.enabled
end

module.watchables.enabled = module.eventwatcher:isEnabled()

module.toggleForWatchablesEnabled = watchables.watch("cheatsheet.enabled", function(w, p, i, oldValue, value)
    if value then
        module.eventwatcher:start()
    else
        module.eventwatcher:stop()
    end
end)

return module
