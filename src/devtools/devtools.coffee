console.log "devtools panel"

chrome.devtools.inspectedWindow.eval "inspect($$('[domflag]')[0])"

 ## Create DevTools Sidebar in Elements Tab
chrome.devtools.panels.elements.createSidebarPane "DOM Flags", (sidebar) ->
  # sidebar initialization code here
  sidebar.setObject some_data: "Some data to show"


# Create a connection to the background page
backgroundPageConnection = chrome.runtime.connect(name: "panel")
backgroundPageConnection.postMessage
  name: "init"
  tabId: chrome.devtools.inspectedWindow.tabId

## Select first domflag on pagerefresh
## TODO: Disable is currect selected Node is a Domflag?
chrome.devtools.network.onRequestFinished.addListener (request) ->
  if request
    chrome.devtools.inspectedWindow.eval "inspect($$('[domflag]')[0])"
