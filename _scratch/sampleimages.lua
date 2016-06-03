
-- the primary "known good" list is handled a little differently than the rest, so...
local primaryTable = {}
for k, v in hs.fnutils.sortByKeys(hs.image.systemImageNames) do table.insert(primaryTable, v) end

local sources = {
    { "hs.image.systemImageNames", primaryTable },
}

for k,v in hs.fnutils.sortByKeys(hs.image.additionalImageNames) do
    table.insert(sources, { "hs.image.additionalImageNames." .. k, v })
end

local position = 1
local currentOffset = 0
local maxCols = 14
local maxRows = 5
local maxPerPage = maxCols * maxRows

local drawBlock
drawBlock = function()
    local imageSource = sources[position][2]

    local a = {
      hs.drawing.rectangle{x=10, y=40, w=1420, h=740}
          :setRoundedRectRadii(20,20):setStroke(true):setStrokeWidth(10)
          :setFill(true):setFillColor{red=1, blue=1, green = 1, alpha = 1}:show()
    }

    local pos = 0
    local c = 0

    for i,v in ipairs(imageSource) do
        pos = pos + 1
        if pos >= currentOffset then
            c = c + 1
            table.insert(a, hs.drawing.text({
                  x=20, y=45, h=30, w=1380}, sources[position][1])
                  :setTextSize(20):setTextColor{red = 0, blue = 0, green = 0, alpha=1}
                  :setTextFont("Menlo"):show())
            local picture = hs.image.imageFromName(v)
            if picture then
                table.insert(a, hs.drawing.image({
                      x=20 + ((c - 1) % 14) * 100,
                      y=75 + math.floor((c-1)/14) * 140,
                      h=100, w=100}, picture):show())
            end
            table.insert(a, hs.drawing.text({
                  x=20 + ((c - 1) % 14) * 100,
                  y=175 + math.floor((c-1)/14) * 140,
                  h=50, w=100}, v)
                  :setTextSize(10):setTextColor{red = 0, blue = 0, green = 0, alpha=1}
                  :setTextFont("Menlo"):show())
        end
        if c == maxPerPage then break end
    end

    esc = function() hs.fnutils.map(a, function(a) a:delete() end) end

    if position < #sources or pos < #imageSource then
        nextPage = hs.hotkey.bind({},"right",
            function() esc() end,
            function()
                if xyzzy    then xyzzy:disable() ; xyzzy = nil end
                if nextPage then nextPage:disable() ; nextPage = nil end
                if prevPage then prevPage:disable() ; prevPage = nil end
                if pos < #imageSource then
                    currentOffset = currentOffset + maxPerPage
                else
                    currentOffset = 0
                    position = position + 1
                end
                drawBlock()
            end
        )
    end

    if position > 1 then
        prevPage = hs.hotkey.bind({}, "left",
            function() esc() end,
            function()
                if xyzzy    then xyzzy:disable() ; xyzzy = nil end
                if nextPage then nextPage:disable() ; nextPage = nil end
                if prevPage then prevPage:disable() ; prevPage = nil end
                if currentOffset == 0 then
                    position = position - 1
                else
                    currentOffset = currentOffset - maxPerPage
                end
                drawBlock()
            end
        )
    end

    xyzzy = hs.hotkey.bind({},"escape",
        function() esc() end,
        function()
            if xyzzy    then xyzzy:disable() ; xyzzy = nil end
            if nextPage then nextPage:disable() ; nextPage = nil end
            if prevPage then prevPage:disable() ; prevPage = nil end
        end
    )
end

drawBlock()
