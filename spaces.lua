-- From: http://ianyh.com/blog/2013/06/05/accessibility/
--
-- AMAccessibilityElement *windowElement = [self window];
-- AMAccessibilityElement *zoomButtonElement = [windowElement elementForKey:kAXZoomButtonAttribute];
-- CGRect zoomButtonFrame = zoomButtonElement.frame;
-- CGRect windowFrame = windowElement.frame;
--
-- CGPoint mouseCursorPoint = { .x = CGRectGetMaxX(zoomButtonFrame) + 5.0, .y = windowFrame.origin.y + 5.0 };//
-- CGEventRef mouseMoveEvent = CGEventCreateMouseEvent(NULL, kCGEventMouseMoved, mouseCursorPoint, kCGMouseButtonLeft);
-- CGEventRef mouseDownEvent = CGEventCreateMouseEvent(NULL, kCGEventLeftMouseDown, mouseCursorPoint, kCGMouseButtonLeft);
-- CGEventRef mouseUpEvent = CGEventCreateMouseEvent(NULL, kCGEventLeftMouseUp, mouseCursorPoint, kCGMouseButtonLeft);
--
-- CGEventRef keyboardDownEvent = CGEventCreateKeyboardEvent(NULL, kVK_RightArrow, true);
-- CGEventRef keyboardUpEvent = CGEventCreateKeyboardEvent(NULL, kVK_RightArrow, false);
--
-- CGEventSetFlags(mouseMoveEvent, 0);
-- CGEventSetFlags(mouseDownEvent, 0);
-- CGEventSetFlags(mouseUpEvent, 0);
-- CGEventSetFlags(keyboardDownEvent, kCGEventFlagMaskControl);
-- CGEventSetFlags(keyboardUpEvent, 0);
--
-- CGEventPost(kCGHIDEventTap, mouseMoveEvent);
-- CGEventPost(kCGHIDEventTap, mouseDownEvent);
-- CGEventPost(kCGHIDEventTap, keyboardDownEvent);
-- CGEventPost(kCGHIDEventTap, keyboardUpEvent);
-- CGEventPost(kCGHIDEventTap, mouseUpEvent);
--
-- CFRelease(mouseMoveEvent);
-- CFRelease(mouseDownEvent);
-- CFRelease(mouseUpEvent);
-- CFRelease(keyboardEvent);
-- CFRelease(keyboardEventUp);

local mouse    = hs.mouse
local event    = hs.eventtap.event
local fnutils  = hs.fnutils
local geometry = hs.geometry
local window   = hs.window

spaceKeySequence = function(win, key, mods)
    local originalMousePosition = mouse.getAbsolutePosition()

    win  = win or fnutils.find(window.orderedWindows(), function(_)
        return geometry.isPointInRect(originalMousePosition, _:frame()) and _:isStandard()
    end)

    key  = key  or "right"
    mods = mods or {"ctrl"}
--     print(win,win:topLeft().x,win:topLeft().y) ;
--     _asm.extras.doSpacesKey(win, key, mods) ;

    local moveMouseTo = { x=win:frame().x + 24, y = win:frame().y + 11 }
    win:focus()
    hs.timer.usleep(125000)

    local mouseDown = event.newMouseEvent(event.types.leftMouseDown, moveMouseTo, {})
    local mouseUp   = event.newMouseEvent(event.types.leftMouseUp,   moveMouseTo, {})
    local keyDown   = event.newKeyEvent(mods, key, true)
    local keyUp     = event.newKeyEvent({}, key, false)

    mouse.setAbsolutePosition(moveMouseTo)
    mouseDown:post()
    hs.timer.usleep(125000)
    keyDown:post()
    hs.timer.usleep(125000)
    keyUp:post()
    mouseUp:post()

    mouse.setAbsolutePosition(originalMousePosition)
end
