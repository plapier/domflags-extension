#### DEVTOOLS SCRIPT

showDomFlag = (key) ->
  chrome.devtools.inspectedWindow.eval "inspect($$('[domflag]')[#{key}])"

showDomFlag(0)

##################

## Open a port with background.js
## Receive key and inspect the element
port = chrome.runtime.connect(name: "devtools")
port.postMessage(msg: "initiate")
port.onMessage.addListener (msg) ->
  if msg.name is "contextMenuClick" or "panelClick"
    showDomFlag(msg.key)
