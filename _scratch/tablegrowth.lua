-- simplified table expansion like the hs.doc `help` function,
-- but without requiring the domain to be pre-filled

local meta
meta = {
    __index = function(self, key)
        local label = (self.__node == "") and key or (self.__node .. "." .. key)
        return setmetatable({ __action = self.__action, __node = label }, meta)
    end,

    __call = function(self, ...)
        if type(self.__action) == "function" then
            return self.__action(self.__node, ...)
        else
            return self.__node
        end
    end,

    __tostring = function(self) return self.__node end
}

return setmetatable({ __node = "" }, meta)
