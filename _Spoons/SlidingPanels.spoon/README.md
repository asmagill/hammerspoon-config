SlidingPanels
=============

Create sliding panels which can emerge from the sides of your monitor to display canvas and guitk element objects

Also requires [hs._asm.guitk](https://github.com/asmagill/hammerspoon_asm/tree/master/guitk) version 0.1.4.1alpha or newer to be installed.  GUITK is a candidate for future inclusion in the Hammerspoon core modules, so hopefully this requirement is temporary

TODO:
  * Document, including docs.json file and slidingPanelObject.lua version
  * Add methods to add/remove canvas and guitk element objects, including slidingPanelObject.lua version

Download: `svn export https://github.com/asmagill/hammerspoon-config/trunk/_Spoons/SlidingPanels.spoon`

This is so much a work in progress that I hesitate to even recommend that you look at it. An example can be tried by saving the following in a file and the loading it with `require` or `dofile`:

~~~lua
local slidingPanels = hs.loadSpoon("SlidingPanels")

slidingPanels:addPanel("infoPanel", {
    size              = 1/3,
    modifiers         = { "fn" },
    persistent        = true,
    animationDuration = 0.1,
    color             = { white = .35 },
    fillAlpha         = .95,
}):enable()

slidingPanels:panel("infoPanel"):addWidget("HCalendar",      { rX = "100%", bY = "100%" })
slidingPanels:panel("infoPanel"):addWidget("CircleClock",    { rX = "100%",  y = 0      })
slidingPanels:panel("infoPanel"):addWidget("MountedVolumes", { x = 0, bY = "100%" }, { cornerRadius = 20 })

return slidingPanels:panel("infoPanel")
~~~

You will also need the `MountedVolumes` spoon for the example (or remove the third `addWidget` line) which is currently available at https://github.com/asmagill/hammerspoon-config/tree/master/_Spoons/MountedVolumes.spoon (the MountedVolumes spoon doesn't require `hs._asm.guitk`, so it may be moved to the core spoon repository soon)

To trigger the panel, hold down the `fn` key on your keyboard and move the mouse pointer to the bottom of the screen and wait a second or two.  If you are not on a laptop, you can remove (or change) the requirement to use the `fn` key by removing the `modifiers` line above.

To release the panel, move the mouse up and then back to the bottom of the screen (`fn` is not required to release the panel).

As you can see here, documentation is lacking at present, and I'm not even positive the above syntax won't be changed in the future.

### Usage
~~~lua
SlidingPanels = hs.loadSpoon("SlidingPanels")
~~~

### Contents


##### Module Variables
* <a href="#logger">SlidingPanels.logger</a>

- - -

### Module Variables

<a name="logger"></a>
~~~lua
SlidingPanels.logger
~~~
Logger object used within the Spoon. Can be accessed to set the default log level for the messages coming from the Spoon.

- - -

### License

>     The MIT License (MIT)
>
> Copyright (c) 2017 Aaron Magill
>
> Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
>
> The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
>
> THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
>


