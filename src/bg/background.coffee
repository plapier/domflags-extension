#### BACKGROUND SCRIPT
_gaq = _gaq or []
_gaq.push ["_setAccount", "UA-48965633-1"]
_gaq.push ["_trackPageview"]
(->
  ga = document.createElement("script")
  ga.type = "text/javascript"
  ga.async = true
  ga.src = "https://ssl.google-analytics.com/ga.js"
  s = document.getElementsByTagName("script")[0]
  s.parentNode.insertBefore ga, s
)()

trackEvent = ->
  _gaq.push ['_trackEvent', 'Domflag', 'clicked']


###############

togglePanel = (message, tabId, port) ->
  chrome.tabs.sendMessage tabId, message, (response) ->
    return

ports = []
chrome.runtime.onConnect.addListener (port) ->
  return false if port.name isnt "devtools"

  chrome.tabs.query currentWindow: true, active: true, (tabs) ->
    ## Create array of tabs with open ports
    tabId = tabs[0].id
    ports[tabId] = port: port, portId: port.portId_, tab: tabId
    tabPort = ports[tabId].port

    ## Workaround for auto-inspect first flag when devtools first opens
    chrome.storage.sync.get autoInspectOpen: true, (items) ->
      if items.autoInspectOpen
        port.postMessage
          name: 'devtoolsOpened'
          key: 0

    ## When item in panel is clicked, send message to devtools
    contentScript = (message, sender, sendResponse) ->
      return if sender.tab.id isnt tabId

      if message.name is 'panelClick'
        port.postMessage
          name: message.name
          key: message.key
        trackEvent()
        return

    ## Init message passing on runtime
    chrome.runtime.onMessage.addListener(contentScript)

    port.onDisconnect.addListener (port) ->
      chrome.runtime.onMessage.removeListener(contentScript)
      togglePanel("remove", tabId, tabPort)
      delete ports[tabId]


  # Create DomFlags Panel when devtools opens
  port.onMessage.addListener (msg) ->
    chrome.tabs.query currentWindow: true, active: true, (tabs) ->
      tabId = tabs[0].id
      tabPort = ports[tabId].port
      togglePanel("create", tabId, tabPort)


## Handle PageReload Events
pageReload = (tabId, changeInfo, tab) ->
  return if !ports[tabId]? ## verify tab has open port

  tabPort = ports[tabId].port
  if changeInfo.status is 'complete'
    togglePanel("create", tabId, tabPort) ## recreate panel

    ## Auto-inspect first flag when page is reloaded
    chrome.storage.sync.get autoInspectReload: true, (items) ->
      if items.autoInspectReload
        tabPort.postMessage
          name: "pageReloaded"
          key: 0

## Setup keyboard shortcuts
keyboardShortcuts = (command) ->
  chrome.tabs.query currentWindow: true, active: true, (tabs) ->
    tabId = tabs[0].id
    return if !ports[tabId]?

    tabPort = ports[tabId].port
    if command is "toggle_domflag"
      tabPort.postMessage
        name: "getInspectedEl"

    else
      tabPort.postMessage
        name: "keyboardShortcut"
        key: command

chrome.tabs.onUpdated.addListener(pageReload)
chrome.commands.onCommand.addListener(keyboardShortcuts)
