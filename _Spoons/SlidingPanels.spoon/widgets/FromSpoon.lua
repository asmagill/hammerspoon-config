--
-- function returned takes the following arguments:
--
--  * spoonName    - string
--  * frameDetails - table containing frameDetails describing where to place canvas within panel (see guitk.manager)
--  * spoonConfig  - table
--    * canvas     - string specifying the name of the canvas as stored within the spoon (usually "canvas" or similar)
--    * start      - string naming method to invoke to start/show/build the canvas or function(spoon) ... end which does the starting
--    * vars       - table of key-value pairs for spoon to be set before "start", if present, is invoked

return function(name, frameDetails, config)
    local s, spoon = pcall(hs.loadSpoon, name)
    if not s then error(string.format("no spoon with the name %s was found", tostring(name))) end
    config = config or {}

    for k, v in pairs(config.vars or {}) do
        if spoon[k] ~= nil and type(spoon[k]) ~= "function" then
            spoon[k] = v
        else
            hs.printf("~~ FromSpoon SlidingPanels widget: %s is not a valid variable for the %s spoon", k, MASTER_SPOON_NAME)
        end
    end

    local start = config.start
    if type(start) == "string" then
        spoon[start](spoon)
    elseif type(start) == "function" or (getmetatable(start) or {}).__call then
        start(spoon)
    end

    frameDetails = frameDetails or {}
    frameDetails.id = frameDetails.id or name

    return spoon[config.canvas or "canvas"], frameDetails
end
