-- probably should add this to hs.doc at some point.
-- I'd really like to get it to work with the ERB files to generate the html docs as well...

local fnutils = require("hs.fnutils")

local sections = {
-- sort order according to scripts/docs/templates/ext.html.erb
    Deprecated  = 1,
    Command     = 2,
    Constant    = 3,
    Variable    = 4,
    Function    = 5,
    Constructor = 6,
    Field       = 7,
    Method      = 8,
}

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

getComments = function(where)
    local text = {}
    if type(where) == "string" then where = { where } end
    for _, path in ipairs(where) do
        for _, file in ipairs(fnutils.split(hs.execute("find "..path.." -name \\*.lua -print -o -name \\*.m -print"), "[\r\n]")) do
            if file ~= "" then
                local comment, incomment = {}, false
                for line in io.lines(file) do
                    local aline = line:match("^%s*(.-)$")
                    if (aline:match("^%-%-%-") or aline:match("^///")) and not aline:match("^...[%-/]") then
                        incomment = true
                        table.insert(comment, aline:match("^... ?(.-)$"))
                    elseif incomment then
                        table.insert(text, comment)
                        comment, incomment = {}, false
                    end
                end
            end
        end
    end
    return text
end,

parseComments = function(text)
    if type(text) == "string" then text = module.getComments(text) end
    local mods, items = {}, {}
    for _, v in ipairs(text) do
        if v[1]:match("===") then
            -- a module definition block
            table.insert(mods, {
                name  = v[1]:gsub("=", ""):match("^%s*(.-)%s*$"),
                desc  = (v[3] or "UNKNOWN DESC"):match("^%s*(.-)%s*$"),
                doc   = table.concat(v, "\n", 2, #v):match("^%s*(.-)%s*$"),
                items = {}
            })
        else
            -- an item block
            table.insert(items, {
                ["type"] = v[2],
                name     = nil,
                def      = v[1],
                doc      = (table.concat(v, "\n", 3, #v) or "UNKNOWN DOC"):match("^%s*(.-)%s*$")
            })
        end
    end
    -- by reversing the order of the module names, sub-modules come before modules, allowing items to
    -- be properly assigned; otherwise, a.b.c might get put into a instead of a.b
    table.sort(mods, function(a, b) return b.name < a.name end)
    local seen = {}
    for _, i in ipairs(items) do
        local mod = nil
        for _, m in ipairs(mods) do
            if i.def:match("^"..m.name.."[%.:]") then
                mod = m
                i.name = i.def:match("^"..m.name.."[%.:]([%w%d_]+)")
                if not sections[i["type"]] then
                    error("error: unknown type "..i["type"].." in "..m.name.."."..i.name..". This is either a documentation error, or scripts/docs/bin/genjson and scripts/docs/templates/ext.html.erb need to be updated to know about this tpe")
                end
                table.insert(m.items, i)
                break
            end
        end
        if not mod then
            error("error: couldn't find module for "..i.def.." ("..i["type"]..") ("..i.doc..")")
        end
    end
    table.sort(mods, function(a, b) return a.name < b.name end)
    for _, v in ipairs(mods) do
        table.sort(v.items, function(a, b)
            if sections[a["type"]] ~= sections[b["type"]] then
                return sections[a["type"]] < sections[b["type"]]
            else
                return a["name"] < b["name"]
            end
        end)
    end
    return mods
end,

genSQL = function(mods)
    if type(mods) == "string" then mods = module.parseComments(module.getComments(mods)) end
    local results = [[
CREATE TABLE searchIndex(id INTEGER PRIMARY KEY, name TEXT, type TEXT, path TEXT);
CREATE UNIQUE INDEX anchor ON searchIndex (name, type, path);
]]
    for _, m in ipairs(mods) do
        for _, i in ipairs(m.items) do
            results = results.."INSERT INTO searchIndex VALUES (NULL, '"..m.name.."."..i.name.."', '"..i["type"].."', '"..m.name..".html#"..i.name.."');\n"
        end
        results = results.."INSERT INTO searchIndex VALUES (NULL, '"..m.name.."', 'Module', '"..m.name..".html');\n"
    end
    return results
end,

genJSON = function(mods)
    if type(mods) == "string" then mods = module.parseComments(module.getComments(mods)) end
    return require("hs.json").encode(mods, true)
end,

genMarkdown = function(mods)
    if type(mods) == "string" then mods = module.parseComments(module.getComments(mods)) end
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

coreDocs = function(src)
    return module.parseComments(module.getComments{ src.."/extensions", src.."/Hammerspoon" })
end,

}

return module