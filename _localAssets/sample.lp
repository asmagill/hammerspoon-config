<head>
  <title>Lua Template Test</title>
</head>
<!--<%
    local inspect = require("hs.inspect")
    local http    = require("hs.http")

    local makeHTMLSafe = function(inputString)
        for k, v in pairs(http.htmlEntities) do
            inputString = inputString:gsub(v, k)
        end
        return inputString
    end
%>-->
<body>
<%= "<" %><%= "!--" %>
<div align="center"><i><font color="#f00">Requires hs._asm.minweb:luaTemplateExtension("lp") to be enabled for your web server</font></i></div>
<%= "--" %><%= ">" %><br>

<b>CGILua Helper Table</b>
<pre><%= makeHTMLSafe(inspect(cgilua)) %></pre>
<hr>
<b>hsminweb Helper Variable</b>
<pre><%= makeHTMLSafe(inspect(hsminweb)) %></pre>
<hr>
<div align="right"><i><%= os.date() %></i></div>
</body>

