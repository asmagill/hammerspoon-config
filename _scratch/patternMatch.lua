-- from https://gist.github.com/heptal/7e578c3129012f0e7e91965bb1f2010e

local name = "id"..hs.host.uuid():gsub("-","");

local html = [[
<div><pre>
.   all characters
%a  letters
%b  balanced delimiters
%c  control characters
%d  digits
%l  lower case letters
%p  punctuation characters
%s  space characters
%u  upper case letters
%w  alphanumeric characters
%x  hexadecimal digits
%z  the character with representation 0
</pre></div>
<input id="pattern" type="text" placeholder="pattern">
<button id="sendData" onclick="sendData()">Evaluate pattern</button><br>
<textarea id="text" rows="10" cols="70" placeholder="text to match"></textarea><br>
Result:
<div id="response"></div>
]]

local js = [[
function sendData() {
  webkit.messageHandlers.]]..name..[[.postMessage({
    pattern: document.getElementById("pattern").value,
    text: document.getElementById("text").value
  })
}
]]

local css = [[
input { width: 250px; }
body {font-family: monospace;}
span {background:rgba(0,0,200,0.2) }
#response {font-size:11px}
]]

local uc = hs.webview.usercontent.new(name):setCallback(function(input)
  local pattern, text = input.body.pattern, input.body.text;
  local result = text:gsub(pattern, function(s) return '<span>'..s..'</span>' end)
  result = result:gsub("\n", "<br>"):gsub(" ", "&nbsp;")
  webview:evaluateJavaScript("document.getElementById('response').innerHTML = "..string.format("%q",result))
end)

local frame = hs.geometry.rect(hs.screen.mainScreen():frame().topleft, "600x700")

webview = hs.webview.new(frame, {developerExtrasEnabled=true}, uc):windowStyle(1|2|4|8):deleteOnClose(true):allowTextEntry(true)
webview:html(string.format('%s<script type="text/javascript">%s</script><style>%s</style>', html, js, css)):show()