if a then a:delete() end
result = nil
cf = hs.fnutils.sortByKeys(hs.drawing.color.colorsFor("x11"))
cName = nil

for i,v in hs.fnutils.sortByKeys(hs.utf8.registeredKeys) do
    if not result then
        result = hs.styledtext.new("{", {
                        font            = { name = "Monaco", size = 12 },
                        color           = { list = "Apple", name = "White" },
                        backgroundColor = { alpha = .75 }
        })
    else
        result = result.."{"
    end
    s = #result + 1
    result = result..v
    e = #result
    result = result.."} "..i.."\n"
    if not cName then cName, _ = cf(nil) end
    result = result:setStyle({ color = { list = "x11", name = cName } }, s, e)
    cName, _ = cf(cName)
end

a = hs.drawing.text({x = 100, y = 50, w = 200, h = 800}, result):wantsLayer(true):show()
