local styleOne = {
  font = "Helvetica",
  size = 24,
  color = {},
}

local textOne = "This is a test string!"

local sizeOne = hs.drawing.getTextDrawingSize(textOne, styleOne) ;

print(textOne, "h = "..sizeOne.h..", w = "..sizeOne.w) ;

local d1 = hs.drawing.text({}, textOne):setSize(sizeOne):
            setTopLeft{x = 40, y = 40}:setTextStyle(styleOne):show()

local d2 = hs.drawing.text({}, textOne):setSize(sizeOne):
            setTopLeft{x = 40, y = 80}:setTextStyle(styleOne):
            setTextStyle{lineBreak="clip"}:show()

local d3 = hs.drawing.text({}, textOne):setSize(sizeOne):
            setTopLeft{x = 40, y = 120}:setTextStyle(styleOne):
            setTextStyle{alignment="justified"}:show()

local d4 = hs.drawing.text({}, textOne):setSize(sizeOne):
            setTopLeft{x = 40, y = 160}:setTextStyle(styleOne):
            setTextStyle{lineBreak="truncateMiddle"}:show()

sizeOne.w = sizeOne.w + 4

local d11 = hs.drawing.text({}, textOne):setSize(sizeOne):
            setTopLeft{x = 260, y = 40}:setTextStyle(styleOne):show()

local d12 = hs.drawing.text({}, textOne):setSize(sizeOne):
            setTopLeft{x = 260, y = 80}:setTextStyle(styleOne):
            setTextStyle{lineBreak="clip"}:show()

local d13 = hs.drawing.text({}, textOne):setSize(sizeOne):
            setTopLeft{x = 260, y = 120}:setTextStyle(styleOne):
            setTextStyle{alignment="justified"}:show()

local d14 = hs.drawing.text({}, textOne):setSize(sizeOne):
            setTopLeft{x = 260, y = 160}:setTextStyle(styleOne):
            setTextStyle(nil):show()

sizeOne.w = sizeOne.w * 2

local d21 = hs.drawing.text({}, textOne):setSize(sizeOne):
            setTopLeft{x = 40, y = 200}:setTextStyle(styleOne):
            setTextStyle{alignment="left", color={red=1}}:show()

local d22 = hs.drawing.text({}, textOne):setSize(sizeOne):
            setTopLeft{x = 40, y = 240}:setTextStyle(styleOne):
            setTextStyle{alignment="center", color={blue=1}}:show()

local d23 = hs.drawing.text({}, textOne):setSize(sizeOne):
            setTopLeft{x = 40, y = 280}:setTextStyle(styleOne):
            setTextStyle{alignment="right", color={green=1}}:show()

sizeOne.w = sizeOne.w / 3

local d31 = hs.drawing.text({}, textOne):setSize(sizeOne):
            setTopLeft{x = 40, y = 320}:setTextStyle(styleOne):
            setTextStyle{lineBreak="truncateHead", color={red=1, blue=1}}:show()

local d32 = hs.drawing.text({}, textOne):setSize(sizeOne):
            setTopLeft{x = 190, y = 320}:setTextStyle(styleOne):
            setTextStyle{lineBreak="truncateMiddle", color={blue=1, green=1}}:show()

local d33 = hs.drawing.text({}, textOne):setSize(sizeOne):
            setTopLeft{x = 340, y = 320}:setTextStyle(styleOne):
            setTextStyle{lineBreak="truncateTail", color={red=1, green=1}}:show()

local styleTwo= {
  font = "Times",
  size = 36,
  color = {},
}

local textTwo = "This is a multi-line test.\rThe second line is longer on purpose."

local sizeTwo = hs.drawing.getTextDrawingSize(textTwo, styleTwo) ;

print(textTwo, "h = "..sizeTwo.h..", w = "..sizeTwo.w) ;

sizeTwo.w = sizeTwo.w + 4

local d51 = hs.drawing.text({}, textTwo):setSize(sizeTwo):
            setTopLeft{x = 40, y = 360}:setTextStyle(styleTwo):show()



