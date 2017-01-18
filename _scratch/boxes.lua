function leftClick(point)
    hs.eventtap.event.newMouseEvent(hs.eventtap.event.types["leftMouseDown"], point):post()
    hs.eventtap.event.newMouseEvent(hs.eventtap.event.types["leftMouseUp"], point):post()
end

function drawBoxes()
	print("Drawing red and blue boxes.")
	redFrame = hs.geometry.rect({x=100, y=100, h=100, w=200})
	redBox = hs.drawing.rectangle(redFrame)
		:setFillColor({red=1.0})
		:setFill(true)
		:setClickCallback(function()
			print("Red clicked!")
		end)
		:show()
	blueFrame = hs.geometry.rect({x=350, y=100, h=100, w=200})
	blueBox = hs.drawing.rectangle(blueFrame)
		:setFillColor({red=0, blue=1.0})
		:setFill(true)
		:setClickCallback(function()
			print("Blue clicked!")
		end)
		:show()
end

function deleteBoxes()
	print("Deleting boxes.")
	redBox:delete()
	blueBox:delete()
end

function clickBox(box)
	local center = hs.geometry.rect(box:frame()).center
	hs.eventtap.leftClick(center)
--	leftClick(center)
end

function swapLocations(box1, box2)
	local frame = box1:frame()
	box1:setFrame(box2:frame())
	box2:setFrame(frame)
end

function redBlueClick()
	print("redBlueClick About to click red then blue box.")
	clickBox(redBox)
	clickBox(blueBox)
	print("redBlueClick Done.")
end

function redBlueClickSleep()
	print("redBlueClickSleep About to click red then blue box.")
	clickBox(redBox)
	clickBox(blueBox)
	hs.timer.usleep(1)
	print("redBlueClickSleep Done.")
end

function redBlueClickTimer()
	print("redBlueClickTimer About to click red then blue box.")
	clickBox(redBox)
	clickBox(blueBox)
	hs.timer.doAfter(0.000001, function()
		print("redBlueClickTimer Done.")
	end)
end

function redBlueClickSwapTimer()
	print("redBlueClickSwapTimer About to click red then blue box then swap them before the timer.")
	clickBox(redBox)
	clickBox(blueBox)
	swapLocations(redBox, blueBox)
	hs.timer.doAfter(0.000001, function()
		print("redBlueClickSwapTimer Done.")
	end)
end

drawBoxes()

hs.timer.doAfter(0.000001, function()
	redBlueClick()

	redBlueClickSleep()

	redBlueClickTimer()

	redBlueClickSwapTimer()

	hs.timer.doAfter(1, deleteBoxes)
end)
