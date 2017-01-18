-- Time Machine widget
--
-- Based HEAVILY on Übersicht Widget at https://github.com/ttscoff/ubersicht-widgets/tree/master/timemachine

local webview = require "hs.webview"
local timer   = require "hs.timer"
local inspect = require "hs.inspect"

local frequency = 5 -- in seconds
local command   = "/usr/bin/tmutil status"

local frame     = { x = 20, y = 350, h = 300, w = 300 }

local module = {}

local PRIMARY_HTML = [==[
<script src="http://code.jquery.com/jquery-latest.min.js"></script>

<!-- style: section of original Übersicht widget -->

<style>
  border none {
    box-sizing: border-box;
    color: #141f33;
    font-family: Helvetica Neue;
    font-weight: 300;
    line-height: 1.5;
    padding: 0;
    left: 20px;
    top: 30px;
    height: auto;
    opacity: 1;
  }
  @font-face {
    font-family: 'arcfontregular';
    src: url("data:font/woff;base64,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") format("woff");
    font-weight: normal;
    font-style: normal;
  }
  border none h1 {
    line-height: 1;
    position: absolute;
    font-size: 100px;
    font-weight: 700;
    margin: 0;
    padding: 0;
    font-family: arcfontregular;
    color: rgba(255,255,255,0.1);
    animation-direction: alternate;
    border: solid 1px rgba(255,255,255,0);
    border-radius: 100px;
  }
  border none h1.spinning {
    animation-direction: reverse;
    animation-timing-function: linear !important;
    animation: spinning 2s infinite;
  }
  border none h1.background {
    border: solid 1px rgba(255,255,255,0.2);
    border-radius: 100px;
  }
  border none h1.background.prepping {
    border-color: rgba(195,59,59,0.5);
    box-shadow: 0 0 15px rgba(195,59,59,0.35);
    animation-timing-function: linear;
    animation: prepping 3s infinite;
  }
  border none h1.background.starting {
    border-color: rgba(206,154,84,0.5);
    box-shadow: 0 0 15px rgba(206,154,84,0.5);
    animation-timing-function: ease !important;
  }
  border none h1.background.running {
    border-color: rgba(96,210,255,0.5);
    box-shadow: 0 0 8px rgba(96,210,255,0.4);
  }
  border none h1.background.finishing {
    border-color: rgba(96,255,137,0.5);
    box-shadow: 0 0 15px rgba(96,255,137,0.35);
  }
  border none h1.background.spinning {
    color: rgba(255,255,255,0);
  }
  border none h1.starting {
    animation-timing-function: ease-in-out;
    animation: starting 2s infinite;
  }
  border none h1.running {
    animation-timing-function: ease-out;
    animation: running 4s infinite;
  }
</style>

<!-- update: (output, domEl) -> section of original widget as javascript function -->

<script type="text/javascript">
  function doMyUpdate(output, domEl) {
    document.write(output)
  }
</script>

<!-- render: (output) ->
        since the original didn't actually do anything but build the page framework I'm not
        bothering with treating it as a function... maybe when I have more experience with
        converting widgets I might attempt a more generic parser or interpreter...
        For now I'm just trying to see if I can make it work!
-->

<style>
  @-webkit-keyframes prepping
  {
    0% {opacity: 1;}
    50% {opacity: .7; box-shadow: none;}
    100% {opacity: 1;}
  }
  @-webkit-keyframes starting
  {
    0% {
      -webkit-transform: scale(1);
      opacity: 1;
    }
    50% {
      -webkit-transform: scale(1.2) ;
      opacity: .85;
      box-shadow: none;
    }
    100% {
      -webkit-transform: scale(1);
      opacity: 1;
    }
  }
  @-webkit-keyframes running
  {
    0% {-webkit-transform: scale(1); opacity: 1;}
    50% {-webkit-transform: scale(1.1) ; opacity: .9; box-shadow: none;}
    100% {-webkit-transform: scale(1); opacity: 1;}
  }
  @-webkit-keyframes spinning
  {
    0% { -webkit-transform: rotate(0deg); }
    100% { -webkit-transform: rotate(360deg); }
  }
</style>

<!-- so we can see it during testing -->
<style>
  body {
    background-color:rgba(0, 225, 0, 0.3)
  }
</style>
  <h1 class="background">Y</h1>
  <h1 class="progress"></h1>
]==]

--module.ucc = webview.usercontent.new("TMWidget")

module.webview = webview.new(
    frame,
    { developerExtrasEnabled = true, privateBrowsing = true, }--,
--    module.ucc
):behaviorAsLabels{ "canJoinAllSpaces" }
 :bringToFront(true)
 :transparent(true)
 :html(PRIMARY_HTML)
 :show()

timer.waitWhile(function()
    return module.webview:loading()
end, function(self)
    module.timer = timer.doEvery(frequency, function()
        local o, s, t, r = hs.execute(command)
        if s then
--            o = o:match("^(.*)\n")
            print(o)
            module.webview:evaluateJavaScript([[doMyUpdate("]] .. o:gsub([["]], [[\"]]) .. [[", document)]], function(result, err)
                if result then
                    print(result)
--                    module.webview:html(result)
                else
                    print("~~ TimeMachine widget error evaluating javascript: " .. inspect(err))
                end
            end)
        else
            print("~~ TimeMachine widget error executing " .. command ..": type = " .. t .. ", code = " .. tostring(r) .. ", with output of " .. inspect(o))
        end
    end)
end)


return module
