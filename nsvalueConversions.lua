local module = {}

--   n/a <: sets little endian
--   n/a >: sets big endian
--   n/a =: sets native endian
--   n/a ![n]: sets maximum alignment to n (default is native alignment)
--   n/a s[n]: a string preceded by its length coded as an unsigned integer with n bytes (default is a size_t)
--   n/a ' ': (empty space) ignored

-- c     b: a signed byte (char)
-- C     B: an unsigned byte (char)
-- s     h: a signed short (native size)
-- S     H: an unsigned short (native size)
-- l     l: a signed long (native size)
-- L     L: an unsigned long (native size)
-- q     j: a lua_Integer
-- Q     J: a lua_Unsigned
-- Q     T: a size_t (native size)
-- i     i[n]: a signed int with n bytes (default is native size)
-- I     I[n]: an unsigned int with n bytes (default is native size)
-- f     f: a float (native size)
-- d     d: a double (native size)
-- d     n: a lua_Number
-- [#c]  cn: a fixed-sized string with n bytes

-- -- one or both may be useful for filling out to match actualSize from NSGetSizeAndAlignment
-- -- also to skip over types we can't handle in data field?
--       x: one byte of padding
--       Xop: an empty item that aligns according to option op (which is otherwise ignored)

-- ????  z: a zero-terminated string --
--           Objective-C -> Lua, would have to modify data from NSValue to replace * address with \0 terminated character stream
--           Lua -> Objective-C, would need some way to know when to free the char* memory... and modify the data replacing the "stream" with the address
--           ... useful for hs._asm.objc... anything else?  worth the effort?

-- probably going to need to do this in Objective-C to get a propert treatment of char*

-- local objCTypeToPackType = {
--     ["c"] = "b",
--     ["i"] = "i",
--     ["s"] = "h",
--     ["l"] = "l",
--     ["q"] = "j",
--     ["C"] = "B",
--     ["I"] = "I",
--     ["S"] = "H",
--     ["L"] = "L"
--     ["Q"] = "J",
--     ["f"] = "f",
--     ["d"] = "d",
--     ["B"] =
--     ["v"] = " ",
--     ["*"] = "T",  -- will require C-Side support for anything else
--     ["@"] = "T",  -- will require C-Side support for anything else
--     ["#"] = "T",  -- will require C-Side support for anything else
--     [":"] = "T",  -- will require C-Side support for anything else
--     ["[array type]"] =
-- --    ["{name=type...}"] = ... -- stripped out via string.gsub
--     ["(name=type...)"] =
--     ["bnum"] =
--     ["^type"] =
--     ["?"] =
-- }

module.toLuaTypeString = function(objCType)
    local workingString = objCType ;
    local s, e = workingString:find("%^")

-- convert union into [#c] with same size as largest type specified
-- use _xtras.sizeAndAlignment on union substring

-- convert pointers into "T"
    while s do
        e = e + 1
        local openChar = workingString:sub(e, e)
        if openChar == "[" or openChar == "{" or openChar == "(" then
            local count = 1
            local closeChar = ({ ["["] = "]", ["("] = ")", ["{"] = "}" })[openChar]
            while (count ~= 0 and e < #workingString) do
                e = e + 1
                local nextChar = workingString:sub(e, e)
                if nextChar == openChar then count = count + 1 end
                if nextChar == closeChar then count = count - 1 end
            end
            if count ~= 0 then
                return error("mismatched pointer grouping with "..openChar)
            end
        end
        workingString = workingString:sub(1, s - 1).."T"..workingString:sub(e + 1, -1)
        s, e = workingString:find("%^")
    end

-- convert array into # copies of what follows?
-- [#c] gets turned into string of that length (c#); others... repeat?

-- strip structures


-- prefix string with '=!'..(third argument from table from _xtras.sizeAndAlignment on objCType)


    return workingString
end

module.toObjCTypeString = function(luaType)
end

module.padForNSValue = function(list, objCType)
    local luaType = module.toLuaTypeString(objCType)

end

module.tableFromNSValue = function(data, objCType)
    local luaType = module.toLuaTypeString(objCType)

end

return module
