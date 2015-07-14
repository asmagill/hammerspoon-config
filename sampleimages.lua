
a = {
  hs.drawing.rectangle{x=10, y=40, w=1420, h=720}
      :setRoundedRectRadii(20,20):setStroke(true):setStrokeWidth(10)
      :setFill(true):setFillColor{red=1, blue=1, green = 1, alpha = 1}:show()
}

c = 0

for i,v in pairs(hs.image.systemImageNames) do
    c = c + 1
    table.insert(a, hs.drawing.image({
          x=20 + ((c - 1) % 14) * 100,
          y=60 + math.floor((c-1)/14) * 140,
          h=100, w=100}, hs.image.imageFromName(v)):show())
    table.insert(a, hs.drawing.text({
          x=20 + ((c - 1) % 14) * 100,
          y=160 + math.floor((c-1)/14) * 140,
          h=40, w=100}, i)
          :setTextSize(10):setTextColor{red = 0, blue = 0, green = 0, alpha=1}
          :setTextFont("Menlo"):show())
end

b = function() hs.fnutils.map(a, function(a) a:delete() end) end
