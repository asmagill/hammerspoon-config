-- see github issue #689

xyzzy = hs.hotkey.bind({}, "j",
    function()
        if hs.eventtap.checkKeyboardModifiers().fn then
            hs.alert.show("FN is DOWN!!!")
        else
            xyzzy:disable()
            hs.eventtap.keyStroke({}, "j")
            xyzzy:enable()
        end
    end
)
