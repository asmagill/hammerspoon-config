local linkToHtml = [[
 <?xml version="1.0" encoding="UTF-8"?>
<html>
  <head>
    <meta http-equiv="content-type" content="text/html; charset=UTF-8">
    <title>Hammerspoon link example</title>
    <link rel="stylesheet" type="text/css" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.6/css/bootstrap.min.css">
    <script type='text/javascript' src="https://craig.global.ssl.fastly.net/js/mousetrap/mousetrap.min.js?71631">
    </script>
    <script type='text/javascript' src="https://ajax.googleapis.com/ajax/libs/jquery/2.1.4/jquery.min.js">
    </script>
    <style type='text/css'>    .jumbotron {  counter-reset: btn-counter;}.btn {  font-size: 21px;  padding: 14px 24px;}.btn:before {  content: counter(btn-counter) ". ";  counter-increment: btn-counter;}  </style>
  </head>
  <body>
    <div class="jumbotron">
      <div>
        <p>
          <a class="btn btn-lg btn-success btn-block" href="#">Meeting</a>
        </p>
        <p>
          <a class="btn btn-lg btn-success btn-block" href="#">Lunch</a>
        </p>
        <p>
          <a class="btn btn-lg btn-success btn-block" href="#">Tea</a>
        </p>
        <p>
          <a class="btn btn-lg btn-success btn-block" href="#">Out</a>
        </p>
      </div>
    </div>
    <script type='text/javascript'>
    $.each($('.btn'), function (it, element) {
           var clickCallback = function () {
               window.location.href = 'hammerspoon://break-report?breakType=' + element.innerHTML
           };
           element.onclick = clickCallback;
           Mousetrap.bind((it + 1).toString(), clickCallback);
       });
    </script>
  </body>
</html>
]]

hs.hotkey.bind({"cmd", "alt", "ctrl", "shift"}, "W", function()
    showButtonsWebView()
end)

function showButtonsWebView()
    local rect = hs.geometry.rect({1, 1, 800, 200})
    local web = hs.webview.new(rect, {developerExtrasEnabled = true})
    web:windowStyle({'closable', 'titled', 'resizable'})
--     web:url(linkToHtml)
    web:html(linkToHtml)
    web:allowTextEntry(true)
    web:closeOnEscape(true)
    web:show()
end

function breakReportCallback(eventName, params)
  hs.alert.show(params.breakType)
end
hs.urlevent.bind('break-report', breakReportCallback)
