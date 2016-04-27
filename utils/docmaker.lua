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

genMarkdown = function(mods)
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
    return results
end,

}

return module