#### DEVTOOLS SCRIPT

showDomFlag = (key) ->
  chrome.devtools.inspectedWindow.eval "inspect($$('[domflag]')[#{key}])"

# Bug: http://crbug.com/178618
# See workaround in background page
# Auto-inspect first domflag when devtools first opens
# chrome.storage.sync.get autoInspectOpen: true, (items) ->
  # showDomFlag(0) if items.autoInspectOpen

##################

## Open a port with background.js
## Receive key and inspect the element
port = chrome.runtime.connect(name: "devtools")
port.postMessage(msg: "initiate")
port.onMessage.addListener (msg) ->
  if msg.name is "contextMenuClick" or "panelClick" or "pageReloaded" or "devtoolsOpened"
    showDomFlag(msg.key)
