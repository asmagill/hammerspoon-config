local objc    = require("hs._asm.objc")
local inspect = require("hs.inspect")
local fnutils = require("hs.fnutils")
local module = {}




module.examineClass = function(className)
    local class, tmpString

    if type(className) == "string" then
        class = objc.class(className)
    else
        class = className
    end

    local propList = class:propertyList()
    local methList = class:methodList()
    local ivarList = class:ivarList()
    local protList = class:adoptedProtocols()

    print("Class: "..class:name().." isMetaClass: ", (class:isMetaClass() and "Yes" or "No"))
    print("Meta Class:"..class:metaClass():name())
    if class:superclass() then
        print("Superclass: "..class:superclass():name())
        print("")
    end

    print("Adopted Protocols")
    tmpString = ""
    for k,v in fnutils.sortByKeys(protList) do tmpString = "\t"..k end
    if tmpString ~= "" then print(tmpString) end
    print("")

    print("Instance Variables")
    for k,v in fnutils.sortByKeys(ivarList) do
        print(string.format("\t%s = %s (@ %d)", k, v:typeEncoding(), v:offset()))
    end
    print("")

    print("Properties")
    for k,v in fnutils.sortByKeys(propList) do
        print(string.format("\t%s: %s", k, v:attributes()))
    end
    print("")

    print("Methods")
    for k,v in fnutils.sortByKeys(methList) do
        print(string.format("\t%s = %s(%s) (%d arguments)", v:returnType(), k, v:typeEncoding(), v:numberOfArguments()))
    end
end


return module