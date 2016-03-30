local nc = require("hs._asm.notificationcenter")

local module = {}
module.watcher = nc.workspaceObserver(function(n, o, i)
    if n == "NSWorkspaceActiveSpaceDidChangeNotification" or
       n == "NSWorkspaceActiveDisplayDidChangeNotification" then
       print(os.date().."\t".."name:"..n.."\tobj:"..inspect(o):gsub("%s+"," ").."\tinfo:"..inspect(i):gsub("%s+"," "))
    end
end):start()

return module
