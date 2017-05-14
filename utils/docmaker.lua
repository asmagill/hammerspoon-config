-- probably should add this to hs.doc at some point.
-- I'd really like to get it to work with the ERB files to generate the html docs as well...

local fnutils    = require("hs.fnutils")
local docBuilder = require("hs.doc").builder

local sectionsMDOrder = {
-- sort order I prefer for README.md files
    Deprecated  = 8,
    Command     = 1,
    Constant    = 6,
    Variable    = 5,
    Function    = 3,
    Constructor = 2,
    Field       = 7,
    Method      = 4,
}

module = {

genMarkdown = function(mods, withTOC)
    if type(mods) == "string" then mods = docBuilder.genComments(mods) end
    local results = ""
    local onceThrough = false
    for _, m in ipairs(mods) do
        if onceThrough then
            results = results.."\n"..string.rep("* ", 40).."\n\n"
        else
            onceThrough = true
        end
        results = results..m.name.."\n"
        results = results..string.rep("=", #m.name).."\n"
        results = results.."\n"
        results = results..m.doc.."\n"
        results = results.."\n"

        results = results .. [[

### Installation

A precompiled version of this module can be found in this directory with a name along the lines of `]] .. m.name:match("^.-([^%.]+)$") .. [[-v0.x.tar.gz`. This can be installed by downloading the file and then expanding it as follows:

~~~sh
$ cd ~/.hammerspoon # or wherever your Hammerspoon init.lua file is located
$ tar -xzf ~/Downloads/]] .. m.name:match("^.-([^%.]+)$") .. [[-v0.x.tar.gz # or wherever your downloads are located
~~~

If you wish to build this module yourself, and have XCode installed on your Mac, the best way (you are welcome to clone the entire repository if you like, but no promises on the current state of anything else) is to download `init.lua`, `internal.m`, and `Makefile` (at present, nothing else is required) into a directory of your choice and then do the following:

~~~sh
$ cd wherever-you-downloaded-the-files
$ [HS_APPLICATION=/Applications] [PREFIX=~/.hammerspoon] make docs install
~~~

If your Hammerspoon application is located in `/Applications`, you can leave out the `HS_APPLICATION` environment variable, and if your Hammerspoon files are located in their default location, you can leave out the `PREFIX` environment variable.  For most people it will be sufficient to just type `make docs install`.

As always, whichever method you chose, if you are updating from an earlier version it is recommended to fully quit and restart Hammerspoon after installing this module to ensure that the latest version of the module is loaded into memory.

]]

        results = results.."### Usage\n"
        results = results.."~~~lua\n"
        results = results..m.name:match("^.-([^%.]+)$").." = require(\""..m.name.."\")\n"
        results = results.."~~~\n"

        if (withTOC) then
            results = results.."\n"
            results = results.."### Contents\n"
            results = results.."\n"
            for k, _ in fnutils.sortByKeyValues(sectionsMDOrder) do
                local sectionLabelPrinted = false
                for _, i in ipairs(m.items) do
                    if i["type"] == k then
                        if not sectionLabelPrinted then
                            sectionLabelPrinted = true
                            results = results.."\n"
                            results = results.."##### Module "..k..(k ~= "Deprecated" and "s" or "").."\n"
                        end
                        results = results.."* <a href=\"#"..i.name.."\">"
                        results = results..i.def:match("^.-("..m.name:match("^.-([^%.]+)$").."[%.:]"..i.name..".*)$")
                        results = results.."</a>\n"
                    end
                end
            end
            results = results.."\n"
            results = results.."- - -\n"
        end

        for k, _ in fnutils.sortByKeyValues(sectionsMDOrder) do
            local sectionLabelPrinted = false
            for _, i in ipairs(m.items) do
                if i["type"] == k then
                    if not sectionLabelPrinted then
                        sectionLabelPrinted = true
                        results = results.."\n"
                        results = results.."### Module "..k..(k ~= "Deprecated" and "s" or "").."\n"
                        results = results.."\n"
                    else
                        results = results.."\n"
                        results = results.."- - -\n"
                        results = results.."\n"
                    end
                    results = results.."<a name=\""..i.name.."\"></a>\n"
                    results = results.."~~~lua\n"
                    results = results..i.def:match("^.-("..m.name:match("^.-([^%.]+)$").."[%.:]"..i.name..".*)$").."\n"
                    results = results.."~~~\n"
                    results = results..i.doc.."\n"
                end
            end
        end
    end

    results = results .. [[

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

]]
    return results
end,

}

return module
