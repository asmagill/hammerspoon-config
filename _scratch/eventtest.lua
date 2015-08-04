--
-- Eventtap testing
--
-- This is a sample file for testing out eventtap modules.

-- Currently it only tests receiving events and displaying the details in the hs console.
--
-- Place this file in your ~/.hammerspoon directory.  Then you can play with it from the hs
-- console as follows:
--
-- dofile("eventtest.lua")
--
-- a = e.new(et.key,f) -- capture only keyboard events
--   or
-- a = e.new(et.all,f) -- all defined events
--   or
-- a = e.new({eep.keydown, eep.keyup} ,f) -- capture only keydown and keyup events
--     (this differs from et.key in that flag changes (i.e. key modifiers) are not
--     sufficient to trigger an event by themselves.)
--
-- a:start()
--

e = require("hs.eventtap")
k = require("hs.keycodes")
i = require("hs.inspect")
eet = e.event.types
eep = e.event.properties

et = {
    all = { eet.keyDown, eet.keyUp, eet.leftMouseDown, eet.leftMouseUp, eet.leftMouseDragged, eet.rightMouseDown, eet.rightMouseUp, eet.rightMouseDragged, eet.middleMouseDown, eet.middleMouseUp, eet.middleMouseDragged, eet.mouseMoved, eet.flagsChanged, eet.scrollWheel, eet.tabletPointer, eet.tabletProximity },
    key = { eet.keyDown, eet.keyUp, eet.flagsChanged },
    mouse = { eet.leftMouseDown, eet.leftMouseUp, eet.leftMouseDragged, eet.rightMouseDown, eet.rightMouseUp, eet.rightMouseDragged, eet.middleMouseDown, eet.middleMouseUp, eet.middleMouseDragged, eet.mouseMoved, eet.scrollWheel, eet.tabletPointer, eet.tabletProximity },
    other = { "all", eet.keyDown, eet.keyUp, eet.leftMouseDown, eet.leftMouseUp, eet.leftMouseDragged, eet.rightMouseDown, eet.rightMouseUp, eet.rightMouseDragged, eet.middleMouseDown, eet.middleMouseUp, eet.middleMouseDragged, eet.mouseMoved, eet.flagsChanged, eet.scrollWheel, eet.tabletPointer, eet.tabletProximity, eet.nullEvent },
}

f = function(o)
    local event_details = {
        { n_type = o:getType(), s_type = eet[o:getType()] },
        { t_flags = o:getFlags(), n_keycode = o:getKeyCode(), s_keycode = k.map[o:getKeyCode()] },
        {
            mouseEventNumber = o:getProperty(eep.mouseEventNumber) ~= 0 and o:getProperty(eep.mouseEventNumber) or nil,
            mouseEventClickState = o:getProperty(eep.mouseEventClickState) ~= 0 and o:getProperty(eep.mouseEventClickState) or nil,
            mouseEventPressure = o:getProperty(eep.mouseEventPressure) ~= 0 and o:getProperty(eep.mouseEventPressure) or nil,
            mouseEventButtonNumber = o:getProperty(eep.mouseEventButtonNumber) ~= 0 and o:getProperty(eep.mouseEventButtonNumber) or nil,
            mouseEventDeltaX = o:getProperty(eep.mouseEventDeltaX) ~= 0 and o:getProperty(eep.mouseEventDeltaX) or nil,
            mouseEventDeltaY = o:getProperty(eep.mouseEventDeltaY) ~= 0 and o:getProperty(eep.mouseEventDeltaY) or nil,
            mouseEventInstantMouser = o:getProperty(eep.mouseEventInstantMouser) ~= 0 and o:getProperty(eep.mouseEventInstantMouser) or nil,
            mouseEventSubtype = o:getProperty(eep.mouseEventSubtype) ~= 0 and o:getProperty(eep.mouseEventSubtype) or nil,
            keyboardEventAutorepeat = o:getProperty(eep.keyboardEventAutorepeat) ~= 0 and o:getProperty(eep.keyboardEventAutorepeat) or nil,
            keyboardEventKeycode = o:getProperty(eep.keyboardEventKeycode) ~= 0 and o:getProperty(eep.keyboardEventKeycode) or nil,
            keyboardEventKeyboardType = o:getProperty(eep.keyboardEventKeyboardType) ~= 0 and o:getProperty(eep.keyboardEventKeyboardType) or nil,
            scrollWheelEventDeltaAxis1 = o:getProperty(eep.scrollWheelEventDeltaAxis1) ~= 0 and o:getProperty(eep.scrollWheelEventDeltaAxis1) or nil,
            scrollWheelEventDeltaAxis2 = o:getProperty(eep.scrollWheelEventDeltaAxis2) ~= 0 and o:getProperty(eep.scrollWheelEventDeltaAxis2) or nil,
            scrollWheelEventDeltaAxis3 = o:getProperty(eep.scrollWheelEventDeltaAxis3) ~= 0 and o:getProperty(eep.scrollWheelEventDeltaAxis3) or nil,
            scrollWheelEventFixedPtDeltaAxis1 = o:getProperty(eep.scrollWheelEventFixedPtDeltaAxis1) ~= 0 and o:getProperty(eep.scrollWheelEventFixedPtDeltaAxis1) or nil,
            scrollWheelEventFixedPtDeltaAxis2 = o:getProperty(eep.scrollWheelEventFixedPtDeltaAxis2) ~= 0 and o:getProperty(eep.scrollWheelEventFixedPtDeltaAxis2) or nil,
            scrollWheelEventFixedPtDeltaAxis3 = o:getProperty(eep.scrollWheelEventFixedPtDeltaAxis3) ~= 0 and o:getProperty(eep.scrollWheelEventFixedPtDeltaAxis3) or nil,
            scrollWheelEventPointDeltaAxis1 = o:getProperty(eep.scrollWheelEventPointDeltaAxis1) ~= 0 and o:getProperty(eep.scrollWheelEventPointDeltaAxis1) or nil,
            scrollWheelEventPointDeltaAxis2 = o:getProperty(eep.scrollWheelEventPointDeltaAxis2) ~= 0 and o:getProperty(eep.scrollWheelEventPointDeltaAxis2) or nil,
            scrollWheelEventPointDeltaAxis3 = o:getProperty(eep.scrollWheelEventPointDeltaAxis3) ~= 0 and o:getProperty(eep.scrollWheelEventPointDeltaAxis3) or nil,
            scrollWheelEventInstantMouser = o:getProperty(eep.scrollWheelEventInstantMouser) ~= 0 and o:getProperty(eep.scrollWheelEventInstantMouser) or nil,
            tabletEventPointX = o:getProperty(eep.tabletEventPointX) ~= 0 and o:getProperty(eep.tabletEventPointX) or nil,
            tabletEventPointY = o:getProperty(eep.tabletEventPointY) ~= 0 and o:getProperty(eep.tabletEventPointY) or nil,
            tabletEventPointZ = o:getProperty(eep.tabletEventPointZ) ~= 0 and o:getProperty(eep.tabletEventPointZ) or nil,
            tabletEventPointButtons = o:getProperty(eep.tabletEventPointButtons) ~= 0 and o:getProperty(eep.tabletEventPointButtons) or nil,
            tabletEventPointPressure = o:getProperty(eep.tabletEventPointPressure) ~= 0 and o:getProperty(eep.tabletEventPointPressure) or nil,
            tabletEventTiltX = o:getProperty(eep.tabletEventTiltX) ~= 0 and o:getProperty(eep.tabletEventTiltX) or nil,
            tabletEventTiltY = o:getProperty(eep.tabletEventTiltY) ~= 0 and o:getProperty(eep.tabletEventTiltY) or nil,
            tabletEventRotation = o:getProperty(eep.tabletEventRotation) ~= 0 and o:getProperty(eep.tabletEventRotation) or nil,
            tabletEventTangentialPressure = o:getProperty(eep.tabletEventTangentialPressure) ~= 0 and o:getProperty(eep.tabletEventTangentialPressure) or nil,
            tabletEventDeviceID = o:getProperty(eep.tabletEventDeviceID) ~= 0 and o:getProperty(eep.tabletEventDeviceID) or nil,
            tabletEventVendor1 = o:getProperty(eep.tabletEventVendor1) ~= 0 and o:getProperty(eep.tabletEventVendor1) or nil,
            tabletEventVendor2 = o:getProperty(eep.tabletEventVendor2) ~= 0 and o:getProperty(eep.tabletEventVendor2) or nil,
            tabletEventVendor3 = o:getProperty(eep.tabletEventVendor3) ~= 0 and o:getProperty(eep.tabletEventVendor3) or nil,
            tabletProximityEventVendorID = o:getProperty(eep.tabletProximityEventVendorID) ~= 0 and o:getProperty(eep.tabletProximityEventVendorID) or nil,
            tabletProximityEventTabletID = o:getProperty(eep.tabletProximityEventTabletID) ~= 0 and o:getProperty(eep.tabletProximityEventTabletID) or nil,
            tabletProximityEventPointerID = o:getProperty(eep.tabletProximityEventPointerID) ~= 0 and o:getProperty(eep.tabletProximityEventPointerID) or nil,
            tabletProximityEventDeviceID = o:getProperty(eep.tabletProximityEventDeviceID) ~= 0 and o:getProperty(eep.tabletProximityEventDeviceID) or nil,
            tabletProximityEventSystemTabletID = o:getProperty(eep.tabletProximityEventSystemTabletID) ~= 0 and o:getProperty(eep.tabletProximityEventSystemTabletID) or nil,
            tabletProximityEventVendorPointerType = o:getProperty(eep.tabletProximityEventVendorPointerType) ~= 0 and o:getProperty(eep.tabletProximityEventVendorPointerType) or nil,
            tabletProximityEventVendorPointerSerialNumber = o:getProperty(eep.tabletProximityEventVendorPointerSerialNumber) ~= 0 and o:getProperty(eep.tabletProximityEventVendorPointerSerialNumber) or nil,
            tabletProximityEventVendorUniqueID = o:getProperty(eep.tabletProximityEventVendorUniqueID) ~= 0 and o:getProperty(eep.tabletProximityEventVendorUniqueID) or nil,
            tabletProximityEventCapabilityMask = o:getProperty(eep.tabletProximityEventCapabilityMask) ~= 0 and o:getProperty(eep.tabletProximityEventCapabilityMask) or nil,
            tabletProximityEventPointerType = o:getProperty(eep.tabletProximityEventPointerType) ~= 0 and o:getProperty(eep.tabletProximityEventPointerType) or nil,
            tabletProximityEventEnterProximity = o:getProperty(eep.tabletProximityEventEnterProximity) ~= 0 and o:getProperty(eep.tabletProximityEventEnterProximity) or nil,
            eventTargetProcessSerialNumber = o:getProperty(eep.eventTargetProcessSerialNumber) ~= 0 and o:getProperty(eep.eventTargetProcessSerialNumber) or nil,
            eventTargetUnixProcessID = o:getProperty(eep.eventTargetUnixProcessID) ~= 0 and o:getProperty(eep.eventTargetUnixProcessID) or nil,
            eventSourceUnixProcessID = o:getProperty(eep.eventSourceUnixProcessID) ~= 0 and o:getProperty(eep.eventSourceUnixProcessID) or nil,
            eventSourceUserData = o:getProperty(eep.eventSourceUserData) ~= 0 and o:getProperty(eep.eventSourceUserData) or nil,
            eventSourceUserID = o:getProperty(eep.eventSourceUserID) ~= 0 and o:getProperty(eep.eventSourceUserID) or nil,
            eventSourceGroupID = o:getProperty(eep.eventSourceGroupID) ~= 0 and o:getProperty(eep.eventSourceGroupID) or nil,
            eventSourceStateID = o:getProperty(eep.eventSourceStateID) ~= 0 and o:getProperty(eep.eventSourceStateID) or nil,
            scrollWheelEventIsContinuous = o:getProperty(eep.scrollWheelEventIsContinuous) ~= 0 and o:getProperty(eep.scrollWheelEventIsContinuous) or nil,
            MouseButtons = {
                o:getButtonState( 0), o:getButtonState( 1), o:getButtonState( 2), o:getButtonState( 3),
                o:getButtonState( 4), o:getButtonState( 5), o:getButtonState( 6), o:getButtonState( 7),
                o:getButtonState( 8), o:getButtonState( 9), o:getButtonState(10), o:getButtonState(11),
                o:getButtonState(12), o:getButtonState(13), o:getButtonState(14), o:getButtonState(15),
                o:getButtonState(16), o:getButtonState(17), o:getButtonState(18), o:getButtonState(19),
                o:getButtonState(20), o:getButtonState(21), o:getButtonState(22), o:getButtonState(23),
                o:getButtonState(24), o:getButtonState(25), o:getButtonState(26), o:getButtonState(27),
                o:getButtonState(28), o:getButtonState(29), o:getButtonState(30), o:getButtonState(31),
            },
        },
    }
    print(os.date("%c",os.time()), i(event_details))
    --local myFile = io.open("output.txt","a+") ; myFile:write(os.date("%c",os.time())..i(event_details).."\n") ; myFile:close()
    return false
end
