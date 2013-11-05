#### DEVTOOLS SCRIPT

showDomFlag = (key) ->
  chrome.devtools.inspectedWindow.eval "inspect($$('[domflag]')[#{key}])"

## Select first domflag on pagerefresh
chrome.devtools.network.onRequestFinished.addListener (request) ->
  if request
    port.postMessage(msg: "connected")
    showDomFlag(0)

showDomFlag(0)

##################

## Open a port with background.js
## Receive key and inspect the element
port = chrome.runtime.connect(name: "devtools")
port.postMessage(msg: "initiate")
port.onMessage.addListener (msg) ->
  console.log msg
  if msg.name is "contextMenuClick" or "panelClick"
    showDomFlag(msg.key)
