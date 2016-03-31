local w = require("hs.webview")

local htmlBegin = [[
<html>
  <body bgcolor="#000000" text="#ffffff" link="#00ff00">
    <form name="inputForm" method="post">
      <table width="100%">
        <tr>
            <td><input type="text" name="cmd" style="width:100%" autofocus></td>
        </tr>
        <tr>
            <td align="center">
                <i>Hit enter to submit or click <a href="javascript:submitCmd()">here</a>.</i>
            </td>
        </tr>
      </table>
    </form>
    <script type="text/javascript">
function submitCmd() {
    try {
        webkit.messageHandlers.passItAlong.postMessage(document.forms["inputForm"]["cmd"].value);
    } catch(err) {
        console.log('The controller does not exist yet');
    }
    return ;
}
    </script>
]]

local htmlEnd = [[
  </body>
</html>
]]

local ucc = w.usercontent.new("passItAlong"):injectScript({ source = [[
    function KeyPressHappened(e)
    {
      if (!e) e=window.event;
      var code;
      if ((e.charCode) && (e.keyCode==0)) {
        code = e.charCode ;
      } else {
        code = e.keyCode;
      }
//      console.log(code) ;
      if (code == 13) {
          submitCmd() ;
          return false ; // we handled it
      } else {
          return true ;  // we didn't handle it
      }
    }
    document.onkeypress = KeyPressHappened;
    ]], mainFrame = true, injectionTime = "documentStart"}):setCallback(function(input)
    -- print(inspect(input))
    local output, status, tp, rc = hs.execute(input.body)
    myView:html(htmlBegin..[[
        <hr>
        <table width="100%">
          <tr>
            <td>Status:</td><td>]]..tostring(status)..[[</td>
            <td>Type:</td><td>]]..tostring(tp)..[[</td>
            <td>RC:</td><td>]]..tostring(rc)..[[</td>
          </tr>
        </table>
        <hr>
        <pre>]]..output..[[</pre>
        <hr>
        <div align="right"><i>Executed at: ]]..os.date()..[[</i></div>
    ]]..htmlEnd)
end)

myView = w.new({x = 50, y = 50, w = 500, h = 500}, { developerExtrasEnabled = true }, ucc)
              :windowStyle(1+2+4+8)
              :allowTextEntry(true)
              :html(htmlBegin..htmlEnd)
              :allowGestures(true)
              :show()

myView:asHSDrawing():setAlpha(.75)
