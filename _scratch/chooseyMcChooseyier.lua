local count = 20

local buildNewTable = function()
    local queries = {}
    for i = 1, count, 1 do
        queries[i] = {
            text    = hs.host.uuid(),
            subText = hs.host.globallyUniqueString(),
        }
    end
    return queries
end

chooser = hs.chooser.new(function(result)
    print((hs.inspect(result):gsub("%s+", " ")))
end):choices(buildNewTable())

changer = hs.timer.doEvery(5, function()
    chooser:choices(buildNewTable())
end)

key = hs.hotkey.bind({"cmd", "ctrl", "alt"}, "8", function()
    chooser:show()
end)
