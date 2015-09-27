local module = {}

local nc = require("hs._asm.notificationcenter")
module.workspaceObserver = nc.workspaceObserver(function(n,o,i)
    local f = io.open("__workspaceobserver.txt","a") ;
    f:write(os.date().."\t".."name:"..n.."\tobj:"..inspect(o):gsub("%s+"," ").."\tinfo:"..inspect(i):gsub("%s+"," ").."\n")
    f:close()
end):start()

module.distributedObserver = nc.distributedObserver(function(n,o,i)
    local f = io.open("__distributedobserver.txt","a") ;
    f:write(os.date().."\t".."name:"..n.."\tobj:"..inspect(o):gsub("%s+"," ").."\tinfo:"..inspect(i):gsub("%s+"," ").."\n")
    f:close()
end):start()

return module