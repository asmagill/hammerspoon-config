--
-- Eventtap testing
--
-- This is a sample file for testing out eventtap modules.

-- Currently it only tests receiving events and displaying the details in the mjolnir console.
--
-- Place this file in your ~/.mjolnir directory.  Then you can play with it from the mjolnir
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
        { n_type = o:gettype(), s_type = eet[o:gettype()] },
        { t_flags = o:getflags(), n_keycode = o:getkeycode(), s_keycode = k.map[o:getkeycode()] },
        {
            MouseEventNumber = o:getproperty(eep.MouseEventNumber) ~= 0 and o:getproperty(eep.MouseEventNumber) or nil,
            MouseEventClickState = o:getproperty(eep.MouseEventClickState) ~= 0 and o:getproperty(eep.MouseEventClickState) or nil,
            MouseEventPressure = o:getproperty(eep.MouseEventPressure) ~= 0 and o:getproperty(eep.MouseEventPressure) or nil,
            MouseEventButtonNumber = o:getproperty(eep.MouseEventButtonNumber) ~= 0 and o:getproperty(eep.MouseEventButtonNumber) or nil,
            MouseEventDeltaX = o:getproperty(eep.MouseEventDeltaX) ~= 0 and o:getproperty(eep.MouseEventDeltaX) or nil,
            MouseEventDeltaY = o:getproperty(eep.MouseEventDeltaY) ~= 0 and o:getproperty(eep.MouseEventDeltaY) or nil,
            MouseEventInstantMouser = o:getproperty(eep.MouseEventInstantMouser) ~= 0 and o:getproperty(eep.MouseEventInstantMouser) or nil,
            MouseEventSubtype = o:getproperty(eep.MouseEventSubtype) ~= 0 and o:getproperty(eep.MouseEventSubtype) or nil,
            KeyboardEventAutorepeat = o:getproperty(eep.KeyboardEventAutorepeat) ~= 0 and o:getproperty(eep.KeyboardEventAutorepeat) or nil,
            KeyboardEventKeycode = o:getproperty(eep.KeyboardEventKeycode) ~= 0 and o:getproperty(eep.KeyboardEventKeycode) or nil,
            KeyboardEventKeyboardType = o:getproperty(eep.KeyboardEventKeyboardType) ~= 0 and o:getproperty(eep.KeyboardEventKeyboardType) or nil,
            ScrollWheelEventDeltaAxis1 = o:getproperty(eep.ScrollWheelEventDeltaAxis1) ~= 0 and o:getproperty(eep.ScrollWheelEventDeltaAxis1) or nil,
            ScrollWheelEventDeltaAxis2 = o:getproperty(eep.ScrollWheelEventDeltaAxis2) ~= 0 and o:getproperty(eep.ScrollWheelEventDeltaAxis2) or nil,
            ScrollWheelEventDeltaAxis3 = o:getproperty(eep.ScrollWheelEventDeltaAxis3) ~= 0 and o:getproperty(eep.ScrollWheelEventDeltaAxis3) or nil,
            ScrollWheelEventFixedPtDeltaAxis1 = o:getproperty(eep.ScrollWheelEventFixedPtDeltaAxis1) ~= 0 and o:getproperty(eep.ScrollWheelEventFixedPtDeltaAxis1) or nil,
            ScrollWheelEventFixedPtDeltaAxis2 = o:getproperty(eep.ScrollWheelEventFixedPtDeltaAxis2) ~= 0 and o:getproperty(eep.ScrollWheelEventFixedPtDeltaAxis2) or nil,
            ScrollWheelEventFixedPtDeltaAxis3 = o:getproperty(eep.ScrollWheelEventFixedPtDeltaAxis3) ~= 0 and o:getproperty(eep.ScrollWheelEventFixedPtDeltaAxis3) or nil,
            ScrollWheelEventPointDeltaAxis1 = o:getproperty(eep.ScrollWheelEventPointDeltaAxis1) ~= 0 and o:getproperty(eep.ScrollWheelEventPointDeltaAxis1) or nil,
            ScrollWheelEventPointDeltaAxis2 = o:getproperty(eep.ScrollWheelEventPointDeltaAxis2) ~= 0 and o:getproperty(eep.ScrollWheelEventPointDeltaAxis2) or nil,
            ScrollWheelEventPointDeltaAxis3 = o:getproperty(eep.ScrollWheelEventPointDeltaAxis3) ~= 0 and o:getproperty(eep.ScrollWheelEventPointDeltaAxis3) or nil,
            ScrollWheelEventInstantMouser = o:getproperty(eep.ScrollWheelEventInstantMouser) ~= 0 and o:getproperty(eep.ScrollWheelEventInstantMouser) or nil,
            TabletEventPointX = o:getproperty(eep.TabletEventPointX) ~= 0 and o:getproperty(eep.TabletEventPointX) or nil,
            TabletEventPointY = o:getproperty(eep.TabletEventPointY) ~= 0 and o:getproperty(eep.TabletEventPointY) or nil,
            TabletEventPointZ = o:getproperty(eep.TabletEventPointZ) ~= 0 and o:getproperty(eep.TabletEventPointZ) or nil,
            TabletEventPointButtons = o:getproperty(eep.TabletEventPointButtons) ~= 0 and o:getproperty(eep.TabletEventPointButtons) or nil,
            TabletEventPointPressure = o:getproperty(eep.TabletEventPointPressure) ~= 0 and o:getproperty(eep.TabletEventPointPressure) or nil,
            TabletEventTiltX = o:getproperty(eep.TabletEventTiltX) ~= 0 and o:getproperty(eep.TabletEventTiltX) or nil,
            TabletEventTiltY = o:getproperty(eep.TabletEventTiltY) ~= 0 and o:getproperty(eep.TabletEventTiltY) or nil,
            TabletEventRotation = o:getproperty(eep.TabletEventRotation) ~= 0 and o:getproperty(eep.TabletEventRotation) or nil,
            TabletEventTangentialPressure = o:getproperty(eep.TabletEventTangentialPressure) ~= 0 and o:getproperty(eep.TabletEventTangentialPressure) or nil,
            TabletEventDeviceID = o:getproperty(eep.TabletEventDeviceID) ~= 0 and o:getproperty(eep.TabletEventDeviceID) or nil,
            TabletEventVendor1 = o:getproperty(eep.TabletEventVendor1) ~= 0 and o:getproperty(eep.TabletEventVendor1) or nil,
            TabletEventVendor2 = o:getproperty(eep.TabletEventVendor2) ~= 0 and o:getproperty(eep.TabletEventVendor2) or nil,
            TabletEventVendor3 = o:getproperty(eep.TabletEventVendor3) ~= 0 and o:getproperty(eep.TabletEventVendor3) or nil,
            TabletProximityEventVendorID = o:getproperty(eep.TabletProximityEventVendorID) ~= 0 and o:getproperty(eep.TabletProximityEventVendorID) or nil,
            TabletProximityEventTabletID = o:getproperty(eep.TabletProximityEventTabletID) ~= 0 and o:getproperty(eep.TabletProximityEventTabletID) or nil,
            TabletProximityEventPointerID = o:getproperty(eep.TabletProximityEventPointerID) ~= 0 and o:getproperty(eep.TabletProximityEventPointerID) or nil,
            TabletProximityEventDeviceID = o:getproperty(eep.TabletProximityEventDeviceID) ~= 0 and o:getproperty(eep.TabletProximityEventDeviceID) or nil,
            TabletProximityEventSystemTabletID = o:getproperty(eep.TabletProximityEventSystemTabletID) ~= 0 and o:getproperty(eep.TabletProximityEventSystemTabletID) or nil,
            TabletProximityEventVendorPointerType = o:getproperty(eep.TabletProximityEventVendorPointerType) ~= 0 and o:getproperty(eep.TabletProximityEventVendorPointerType) or nil,
            TabletProximityEventVendorPointerSerialNumber = o:getproperty(eep.TabletProximityEventVendorPointerSerialNumber) ~= 0 and o:getproperty(eep.TabletProximityEventVendorPointerSerialNumber) or nil,
            TabletProximityEventVendorUniqueID = o:getproperty(eep.TabletProximityEventVendorUniqueID) ~= 0 and o:getproperty(eep.TabletProximityEventVendorUniqueID) or nil,
            TabletProximityEventCapabilityMask = o:getproperty(eep.TabletProximityEventCapabilityMask) ~= 0 and o:getproperty(eep.TabletProximityEventCapabilityMask) or nil,
            TabletProximityEventPointerType = o:getproperty(eep.TabletProximityEventPointerType) ~= 0 and o:getproperty(eep.TabletProximityEventPointerType) or nil,
            TabletProximityEventEnterProximity = o:getproperty(eep.TabletProximityEventEnterProximity) ~= 0 and o:getproperty(eep.TabletProximityEventEnterProximity) or nil,
            EventTargetProcessSerialNumber = o:getproperty(eep.EventTargetProcessSerialNumber) ~= 0 and o:getproperty(eep.EventTargetProcessSerialNumber) or nil,
            EventTargetUnixProcessID = o:getproperty(eep.EventTargetUnixProcessID) ~= 0 and o:getproperty(eep.EventTargetUnixProcessID) or nil,
            EventSourceUnixProcessID = o:getproperty(eep.EventSourceUnixProcessID) ~= 0 and o:getproperty(eep.EventSourceUnixProcessID) or nil,
            EventSourceUserData = o:getproperty(eep.EventSourceUserData) ~= 0 and o:getproperty(eep.EventSourceUserData) or nil,
            EventSourceUserID = o:getproperty(eep.EventSourceUserID) ~= 0 and o:getproperty(eep.EventSourceUserID) or nil,
            EventSourceGroupID = o:getproperty(eep.EventSourceGroupID) ~= 0 and o:getproperty(eep.EventSourceGroupID) or nil,
            EventSourceStateID = o:getproperty(eep.EventSourceStateID) ~= 0 and o:getproperty(eep.EventSourceStateID) or nil,
            ScrollWheelEventIsContinuous = o:getproperty(eep.ScrollWheelEventIsContinuous) ~= 0 and o:getproperty(eep.ScrollWheelEventIsContinuous) or nil,
            MouseButtons = {
                o:getbuttonstate( 0), o:getbuttonstate( 1), o:getbuttonstate( 2), o:getbuttonstate( 3),
                o:getbuttonstate( 4), o:getbuttonstate( 5), o:getbuttonstate( 6), o:getbuttonstate( 7),
                o:getbuttonstate( 8), o:getbuttonstate( 9), o:getbuttonstate(10), o:getbuttonstate(11),
                o:getbuttonstate(12), o:getbuttonstate(13), o:getbuttonstate(14), o:getbuttonstate(15),
                o:getbuttonstate(16), o:getbuttonstate(17), o:getbuttonstate(18), o:getbuttonstate(19),
                o:getbuttonstate(20), o:getbuttonstate(21), o:getbuttonstate(22), o:getbuttonstate(23),
                o:getbuttonstate(24), o:getbuttonstate(25), o:getbuttonstate(26), o:getbuttonstate(27),
                o:getbuttonstate(28), o:getbuttonstate(29), o:getbuttonstate(30), o:getbuttonstate(31),
            },
        },
    }
    print(os.date("%c",os.time()), i(event_details))
    --local myFile = io.open("output.txt","a+") ; myFile:write(os.date("%c",os.time())..i(event_details).."\n") ; myFile:close()
    return false
end
