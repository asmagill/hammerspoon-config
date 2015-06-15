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
    all = { eet.keydown, eet.keyup, eet.leftmousedown, eet.leftmouseup, eet.leftmousedragged, eet.rightmousedown, eet.rightmouseup, eet.rightmousedragged, eet.middlemousedown, eet.middlemouseup, eet.middlemousedragged, eet.mousemoved, eet.flagschanged, eet.scrollwheel, eet.tabletpointer, eet.tabletproximity },
    key = { eet.keydown, eet.keyup, eet.flagschanged },
    mouse = { eet.leftmousedown, eet.leftmouseup, eet.leftmousedragged, eet.rightmousedown, eet.rightmouseup, eet.rightmousedragged, eet.middlemousedown, eet.middlemouseup, eet.middlemousedragged, eet.mousemoved, eet.scrollwheel, eet.tabletpointer, eet.tabletproximity },
    other = { "all", eet.keydown, eet.keyup, eet.flagschanged, eet.leftmousedown, eet.leftmouseup, eet.leftmousedragged, eet.rightmousedown, eet.rightmouseup, eet.rightmousedragged, eet.middlemousedown, eet.middlemouseup, eet.middlemousedragged, eet.mousemoved, eet.scrollwheel, eet.tabletpointer, eet.tabletproximity, eet.nullevent },
}

f = function(o)
    local event_details = {
        { n_type = o:getType(), s_type = eet[o:getType()] },
        { t_flags = o:getFlags(), n_keycode = o:getKeyCode(), s_keycode = k.map[o:getKeyCode()] },
        {
            MouseEventNumber = o:getProperty(eep.MouseEventNumber) ~= 0 and o:getProperty(eep.MouseEventNumber) or nil,
            MouseEventClickState = o:getProperty(eep.MouseEventClickState) ~= 0 and o:getProperty(eep.MouseEventClickState) or nil,
            MouseEventPressure = o:getProperty(eep.MouseEventPressure) ~= 0 and o:getProperty(eep.MouseEventPressure) or nil,
            MouseEventButtonNumber = o:getProperty(eep.MouseEventButtonNumber) ~= 0 and o:getProperty(eep.MouseEventButtonNumber) or nil,
            MouseEventDeltaX = o:getProperty(eep.MouseEventDeltaX) ~= 0 and o:getProperty(eep.MouseEventDeltaX) or nil,
            MouseEventDeltaY = o:getProperty(eep.MouseEventDeltaY) ~= 0 and o:getProperty(eep.MouseEventDeltaY) or nil,
            MouseEventInstantMouser = o:getProperty(eep.MouseEventInstantMouser) ~= 0 and o:getProperty(eep.MouseEventInstantMouser) or nil,
            MouseEventSubtype = o:getProperty(eep.MouseEventSubtype) ~= 0 and o:getProperty(eep.MouseEventSubtype) or nil,
            KeyboardEventAutorepeat = o:getProperty(eep.KeyboardEventAutorepeat) ~= 0 and o:getProperty(eep.KeyboardEventAutorepeat) or nil,
            KeyboardEventKeycode = o:getProperty(eep.KeyboardEventKeycode) ~= 0 and o:getProperty(eep.KeyboardEventKeycode) or nil,
            KeyboardEventKeyboardType = o:getProperty(eep.KeyboardEventKeyboardType) ~= 0 and o:getProperty(eep.KeyboardEventKeyboardType) or nil,
            ScrollWheelEventDeltaAxis1 = o:getProperty(eep.ScrollWheelEventDeltaAxis1) ~= 0 and o:getProperty(eep.ScrollWheelEventDeltaAxis1) or nil,
            ScrollWheelEventDeltaAxis2 = o:getProperty(eep.ScrollWheelEventDeltaAxis2) ~= 0 and o:getProperty(eep.ScrollWheelEventDeltaAxis2) or nil,
            ScrollWheelEventDeltaAxis3 = o:getProperty(eep.ScrollWheelEventDeltaAxis3) ~= 0 and o:getProperty(eep.ScrollWheelEventDeltaAxis3) or nil,
            ScrollWheelEventFixedPtDeltaAxis1 = o:getProperty(eep.ScrollWheelEventFixedPtDeltaAxis1) ~= 0 and o:getProperty(eep.ScrollWheelEventFixedPtDeltaAxis1) or nil,
            ScrollWheelEventFixedPtDeltaAxis2 = o:getProperty(eep.ScrollWheelEventFixedPtDeltaAxis2) ~= 0 and o:getProperty(eep.ScrollWheelEventFixedPtDeltaAxis2) or nil,
            ScrollWheelEventFixedPtDeltaAxis3 = o:getProperty(eep.ScrollWheelEventFixedPtDeltaAxis3) ~= 0 and o:getProperty(eep.ScrollWheelEventFixedPtDeltaAxis3) or nil,
            ScrollWheelEventPointDeltaAxis1 = o:getProperty(eep.ScrollWheelEventPointDeltaAxis1) ~= 0 and o:getProperty(eep.ScrollWheelEventPointDeltaAxis1) or nil,
            ScrollWheelEventPointDeltaAxis2 = o:getProperty(eep.ScrollWheelEventPointDeltaAxis2) ~= 0 and o:getProperty(eep.ScrollWheelEventPointDeltaAxis2) or nil,
            ScrollWheelEventPointDeltaAxis3 = o:getProperty(eep.ScrollWheelEventPointDeltaAxis3) ~= 0 and o:getProperty(eep.ScrollWheelEventPointDeltaAxis3) or nil,
            ScrollWheelEventInstantMouser = o:getProperty(eep.ScrollWheelEventInstantMouser) ~= 0 and o:getProperty(eep.ScrollWheelEventInstantMouser) or nil,
            TabletEventPointX = o:getProperty(eep.TabletEventPointX) ~= 0 and o:getProperty(eep.TabletEventPointX) or nil,
            TabletEventPointY = o:getProperty(eep.TabletEventPointY) ~= 0 and o:getProperty(eep.TabletEventPointY) or nil,
            TabletEventPointZ = o:getProperty(eep.TabletEventPointZ) ~= 0 and o:getProperty(eep.TabletEventPointZ) or nil,
            TabletEventPointButtons = o:getProperty(eep.TabletEventPointButtons) ~= 0 and o:getProperty(eep.TabletEventPointButtons) or nil,
            TabletEventPointPressure = o:getProperty(eep.TabletEventPointPressure) ~= 0 and o:getProperty(eep.TabletEventPointPressure) or nil,
            TabletEventTiltX = o:getProperty(eep.TabletEventTiltX) ~= 0 and o:getProperty(eep.TabletEventTiltX) or nil,
            TabletEventTiltY = o:getProperty(eep.TabletEventTiltY) ~= 0 and o:getProperty(eep.TabletEventTiltY) or nil,
            TabletEventRotation = o:getProperty(eep.TabletEventRotation) ~= 0 and o:getProperty(eep.TabletEventRotation) or nil,
            TabletEventTangentialPressure = o:getProperty(eep.TabletEventTangentialPressure) ~= 0 and o:getProperty(eep.TabletEventTangentialPressure) or nil,
            TabletEventDeviceID = o:getProperty(eep.TabletEventDeviceID) ~= 0 and o:getProperty(eep.TabletEventDeviceID) or nil,
            TabletEventVendor1 = o:getProperty(eep.TabletEventVendor1) ~= 0 and o:getProperty(eep.TabletEventVendor1) or nil,
            TabletEventVendor2 = o:getProperty(eep.TabletEventVendor2) ~= 0 and o:getProperty(eep.TabletEventVendor2) or nil,
            TabletEventVendor3 = o:getProperty(eep.TabletEventVendor3) ~= 0 and o:getProperty(eep.TabletEventVendor3) or nil,
            TabletProximityEventVendorID = o:getProperty(eep.TabletProximityEventVendorID) ~= 0 and o:getProperty(eep.TabletProximityEventVendorID) or nil,
            TabletProximityEventTabletID = o:getProperty(eep.TabletProximityEventTabletID) ~= 0 and o:getProperty(eep.TabletProximityEventTabletID) or nil,
            TabletProximityEventPointerID = o:getProperty(eep.TabletProximityEventPointerID) ~= 0 and o:getProperty(eep.TabletProximityEventPointerID) or nil,
            TabletProximityEventDeviceID = o:getProperty(eep.TabletProximityEventDeviceID) ~= 0 and o:getProperty(eep.TabletProximityEventDeviceID) or nil,
            TabletProximityEventSystemTabletID = o:getProperty(eep.TabletProximityEventSystemTabletID) ~= 0 and o:getProperty(eep.TabletProximityEventSystemTabletID) or nil,
            TabletProximityEventVendorPointerType = o:getProperty(eep.TabletProximityEventVendorPointerType) ~= 0 and o:getProperty(eep.TabletProximityEventVendorPointerType) or nil,
            TabletProximityEventVendorPointerSerialNumber = o:getProperty(eep.TabletProximityEventVendorPointerSerialNumber) ~= 0 and o:getProperty(eep.TabletProximityEventVendorPointerSerialNumber) or nil,
            TabletProximityEventVendorUniqueID = o:getProperty(eep.TabletProximityEventVendorUniqueID) ~= 0 and o:getProperty(eep.TabletProximityEventVendorUniqueID) or nil,
            TabletProximityEventCapabilityMask = o:getProperty(eep.TabletProximityEventCapabilityMask) ~= 0 and o:getProperty(eep.TabletProximityEventCapabilityMask) or nil,
            TabletProximityEventPointerType = o:getProperty(eep.TabletProximityEventPointerType) ~= 0 and o:getProperty(eep.TabletProximityEventPointerType) or nil,
            TabletProximityEventEnterProximity = o:getProperty(eep.TabletProximityEventEnterProximity) ~= 0 and o:getProperty(eep.TabletProximityEventEnterProximity) or nil,
            EventTargetProcessSerialNumber = o:getProperty(eep.EventTargetProcessSerialNumber) ~= 0 and o:getProperty(eep.EventTargetProcessSerialNumber) or nil,
            EventTargetUnixProcessID = o:getProperty(eep.EventTargetUnixProcessID) ~= 0 and o:getProperty(eep.EventTargetUnixProcessID) or nil,
            EventSourceUnixProcessID = o:getProperty(eep.EventSourceUnixProcessID) ~= 0 and o:getProperty(eep.EventSourceUnixProcessID) or nil,
            EventSourceUserData = o:getProperty(eep.EventSourceUserData) ~= 0 and o:getProperty(eep.EventSourceUserData) or nil,
            EventSourceUserID = o:getProperty(eep.EventSourceUserID) ~= 0 and o:getProperty(eep.EventSourceUserID) or nil,
            EventSourceGroupID = o:getProperty(eep.EventSourceGroupID) ~= 0 and o:getProperty(eep.EventSourceGroupID) or nil,
            EventSourceStateID = o:getProperty(eep.EventSourceStateID) ~= 0 and o:getProperty(eep.EventSourceStateID) or nil,
            ScrollWheelEventIsContinuous = o:getProperty(eep.ScrollWheelEventIsContinuous) ~= 0 and o:getProperty(eep.ScrollWheelEventIsContinuous) or nil,
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
