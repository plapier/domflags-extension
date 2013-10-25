console.log "devtools panel"
chrome.devtools.inspectedWindow.eval "inspect($$('[domflag]')[0])"
 ## Create DevTools Sidebar in Elements Tab
chrome.devtools.panels.elements.createSidebarPane "DOM Flags", (sidebar) ->
  sidebar.setObject some_data: "Some data to show"

## Select first domflag on pagerefresh
## TODO: Disable is currect selected Node is a Domflag?
chrome.devtools.network.onRequestFinished.addListener (request) ->
  if request
    chrome.devtools.inspectedWindow.eval "inspect($$('[domflag]')[0])"

##################

## Open a port with background.js
## Receive key and inspect the element
port = chrome.runtime.connect(name: "devtools")
port.onMessage.addListener (msg) ->
  key = msg.key
  chrome.devtools.inspectedWindow.eval "inspect($$('[domflag]')[#{key}])"
