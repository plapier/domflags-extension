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


###############

@hideEmptyPanel = undefined
@autoInspectOpen = undefined
@autoInspectReload = undefined

chrome.storage.local.get (items) =>
  @hideEmptyPanel = items.hideEmptyPanel
  @autoInspectOpen = items.autoInspectOpen
  @autoInspectReload = items.autoInspectReload

chrome.storage.onChanged.addListener (changes) =>
  for key of changes
    switch key
      when 'hideEmptyPanel' then @hideEmptyPanel = changes.hideEmptyPanel.newValue
      when 'autoInspectOpen' then @autoInspectOpen = changes.autoInspectOpen.newValue
      when 'autoInspectReload' then @autoInspectReload = changes.autoInspectReload.newValue

togglePanel = (message, tabId, port) ->
  chrome.tabs.sendMessage(tabId, message)

@ports = []
chrome.runtime.onConnect.addListener (port) =>
  return if port.name isnt "devtools"

  chrome.tabs.query currentWindow: true, active: true, (tabs) =>
    ## Create array of tabs with open ports
    tabId = tabs[0].id
    @ports[tabId] = port: port, portId: port.portId_, tab: tabId
    tabPort = @ports[tabId].port

    ## Workaround for auto-inspect first flag when devtools first opens
    if @autoInspectOpen
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

    ## Init message passing on runtime
    chrome.runtime.onMessage.addListener(contentScript)

    port.onDisconnect.addListener (port) =>
      chrome.runtime.onMessage.removeListener(contentScript)
      togglePanel({action: "remove", hidePanel: undefined}, tabId, tabPort)
      delete @ports[tabId]


  # Create DomFlags Panel when devtools opens
  port.onMessage.addListener (msg) =>
    chrome.tabs.query currentWindow: true, active: true, (tabs) =>
      tabId = tabs[0].id
      tabPort = @ports[tabId].port
      togglePanel({action: "create", hidePanel: @hideEmptyPanel}, tabId, tabPort)


## Handle PageReload Events
pageReload = (tabId, changeInfo, tab) =>
  return if changeInfo.status isnt 'complete'
  return if !@ports[tabId]? ## verify tab has open port

  tabPort = @ports[tabId].port
  togglePanel({action: "create", hidePanel: @hideEmptyPanel}, tabId, tabPort) ## recreate panel

  ## Auto-inspect first flag when page is reloaded
  if @autoInspectReload
    tabPort.postMessage
      name: "pageReloaded"
      key: 0

## Setup keyboard shortcuts
keyboardShortcuts = (command) =>
  chrome.tabs.query currentWindow: true, active: true, (tabs) =>
    tabId = tabs[0].id
    return if !@ports[tabId]?

    tabPort = @ports[tabId].port
    if command is "toggle_domflag"
      tabPort.postMessage
        name: "getInspectedEl"

    else
      tabPort.postMessage
        name: "keyboardShortcut"
        key: command

chrome.tabs.onUpdated.addListener(pageReload)
chrome.commands.onCommand.addListener(keyboardShortcuts)
