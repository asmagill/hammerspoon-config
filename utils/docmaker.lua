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
> Copyright (c) 2016 Aaron Magill
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