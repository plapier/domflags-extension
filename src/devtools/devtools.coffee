console.log "devtools panel"

##################
## TODO: Disable if currect selected Node is a Domflag?

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
port = chrome.runtime.connect(name: "devtoolsConnect")
port.postMessage(msg: "connected")
port.onMessage.addListener (msg) ->
  if msg.name is "contextMenuClick"
    showDomFlag(msg.key)

# chrome.runtime.sendMessage(name: "devtools")
