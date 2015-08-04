test = hs.hotkey.modal.new({"cmd","alt","ctrl"},"y")
function test:entered() hs.alert.show("entered modal mode") end
test:bind({"cmd"},"c", function() print("cmd-c down") end, nil, function() print("cmd-c repeat") end)
test:bind({},"escape", function() test:exit() end)
function test:exited() hs.alert.show("exiting modal mode") end