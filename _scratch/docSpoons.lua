-- spoon doc support
--
-- [x] find spoons installed
-- [x] identify documentation json file for each
--   [ ] if found, register for docs:
--     [ ] console help
--     [ ] hsdocs
--     [ ] exportable html/md ?   -- not in initial release
--     [ ] custom built docset ?  -- not in initial release
--   [x] if not found, generate json then register
--     [ ] should this be a separate task to occur after initial HS load?
--
-- [ ] see what changes `hs.doc` requires
--   [ ] scheduled rescan?

local module = {}
-- won't default to debug in release... debating between "error" and "none" as default and
-- using hs.settings to allow setting it based on user preference
local log = require("hs.logger").new("spoonDocs", "debug")

local documentationFileName = "docs.json"

local fs  = require "hs.fs"
local doc = require "hs.doc"

local findSpoons = function()
    local spoonPaths, installedSpoons = {}, {}
    for path in package.path:gmatch("([^;]+Spoons/%?%.spoon/init%.lua)") do
        table.insert(spoonPaths, path)
    end
    for i, v in ipairs(spoonPaths) do
        for file in fs.dir(v:match("^(.+)/%?%.spoon/init%.lua$")) do
            local name = file:match("^(.+)%.spoon$")
            local spoonInit = name and package.searchpath(name, package.path)
            if name and spoonInit then
                spoonDetails = {}
                spoonDetails.path     = spoonInit:match("^(.+)/init%.lua$")
                spoonDetails.docPath  = spoonDetails.path .. "/" .. documentationFileName
                spoonDetails.hasDocs  = fs.attributes(spoonDetails.docPath) and true or false
                installedSpoons[name] = spoonDetails
            else
                if not file:match("^%.%.?$") then
                    log.df("skipping %s -- missing init.lua", file)
                end
            end
        end
    end
    return spoonPaths, installedSpoons
end

local makeDocsFile = function(path, overwrite)
    assert(type(path) == "string", "must specify a path")

    local destinationPath = path .. "/" .. documentationFileName
    if overwrite or not fs.attributes(destinationPath) then
        local stat, output = pcall(doc.builder.genJSON, path)
        if stat then
            local f, e = io.open(destinationPath, "w+")
            if f then
                f:write(output)
                f:close()
            else
                log.ef("unable to open %s for writing:\n\t%s", destinationPath, e)
            end
        else
            log.ef("error generating documentation for %s:\n\t%s", path, output)
        end
    else
        log.wf("will not overwrite %s without being forced", destinationPath)
    end
end

local updateDocsFiles = function()
    local spoonPaths, installedSpoons = findSpoons()
    for k, v in pairs(installedSpoons) do
        if not v.hasDocs then
            log.df("creating docs file for %s", k)
            makeDocsFile(v.path)
        else
            local initFile, docsFile = fs.attributes(v.path .. "/init.lua"), fs.attributes(v.docPath)
            if initFile.change > docsFile.creation then
                log.df("updating docs file for %s", k)
                makeDocsFile(v.path, true)
            else
                log.vf("docs file for %s current", k)
            end
        end
    end
end

module.log             = log
module.findSpoons      = findSpoons
module.updateDocsFiles = updateDocsFiles
module.makeDocsFile    = makeDocsFile

return module

