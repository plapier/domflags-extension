console.log "devtools panel"

 ## Create DevTools Sidebar in Elements Tab
chrome.devtools.panels.elements.createSidebarPane "DOM Flags", (sidebar) ->
  sidebar.setObject some_data: "Some data to show"

##################
## TODO: Disable if currect selected Node is a Domflag?

showDomFlag = (key) ->
  chrome.devtools.inspectedWindow.eval "inspect($$('[domflag]')[#{key}])"

## Select first domflag on pagerefresh
chrome.devtools.network.onRequestFinished.addListener (request) ->
  if request
    showDomFlag(0)

showDomFlag(0)

##################

## Open a port with background.js
## Receive key and inspect the element
port = chrome.runtime.connect(name: "devtools")
port.onMessage.addListener (msg) ->
  showDomFlag(msg.key)
