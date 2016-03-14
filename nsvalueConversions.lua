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
-- [nc]  cn: a fixed-sized string with n bytes

-- -- one or both may be useful for filling out to match actualSize from NSGetSizeAndAlignment
-- -- also to skip over types we can't handle in data field?
--       x: one byte of padding
--       Xop: an empty item that aligns according to option op (which is otherwise ignored)

-- ????  z: a zero-terminated string --
--           Objective-C -> Lua, would have to modify data from NSValue to replace * address with \0 terminated character stream
--           Lua -> Objective-C, would need some way to know when to free the char* memory... and modify the data replacing the "stream" with the address
--           ... useful for hs._asm.objc... anything else?  worth the effort?

-- probably going to need to do this in Objective-C to get a propert treatment of char*

module.toLuaTypeString = function(objCType)
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
