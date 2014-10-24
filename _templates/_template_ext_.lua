local module = {
--[=[
    _NAME        = 'mjolnir.module_name',
    _VERSION     = 'the 1st digit of Pi/0',
    _URL         = 'https://github.com/asmagill/mjolnir_asm',
    _LICENSE     = [[ See README.md ]]
    _DESCRIPTION = [[
    
--- === mjolnir.module_name ===
---
--- Home: https://github.com/asmagill/mjolnir_asm/tree/published/module_name
---
--- Description

    ]],
--]=]
}

local mjolnir_mod_name = "module_name"
--local c_library = "internal"

-- integration with C functions ------------------------------------------

if c_library then
	for i,v in pairs(require("mjolnir."..mjolnir_mod_name.."."..c_library)) do module[i] = v end
end

-- private variables and methods -----------------------------------------

-- Public interface ------------------------------------------------------

--- mjolnir.module_name.function( ... ) -> ...
--- Function
--- Convert string to an array of strings, breaking at the specified divider(s), similar to "split" in Perl.
module.function = function()
end

-- Return Module Object --------------------------------------------------

return module
