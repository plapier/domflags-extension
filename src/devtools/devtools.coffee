#### DEVTOOLS SCRIPT

# Bug: http://crbug.com/178618
# See workaround in background page
# Auto-inspect first domflag when devtools first opens
# chrome.storage.local.get autoInspectOpen: true, (items) ->
  # showDomFlag(0) if items.autoInspectOpen

##################

showDomFlag = (key) ->
  chrome.devtools.inspectedWindow.eval "inspect($$('[domflag]')[#{key}])"

## Open a port with background.js
## Receive key and inspect the element
port = chrome.runtime.connect(name: "devtools")
port.postMessage(msg: "initiate")
port.onMessage.addListener (msg) ->
  if msg.name is "getInspectedEl"
    chrome.devtools.inspectedWindow.eval "toggleDomflag($0)",
      useContentScriptContext: true

  else if msg.name is "panelClick" or "pageReloaded" or "devtoolsOpened" or "keyboardShortcut"
    showDomFlag(msg.key)

  # chrome.devtools.inspectedWindow.eval "console.log($0, 'devtools')"
