#### BACKGROUND SCRIPT

updateContextMenus = (flags, port) ->
  onClickHandler = (info, tab) ->
    port.postMessage
      name: "contextMenuClick"
      key: info.menuItemId
      tab: tab

  if flags.length > 0
    for own key, value of flags
      chrome.contextMenus.create
        title: value
        id: "#{key}"
        contexts: ['all']
        onclick: onClickHandler

requestDomFlags = (tabId, port) ->
  chrome.tabs.sendMessage tabId, "Give me domflags" , (response) ->
    console.log "Give me domflags"
    if response
      console.log response
      updateContextMenus(response.flags, port)

ports = []
chrome.runtime.onConnect.addListener (port) ->
  return if port.name isnt "devtools"

  chrome.tabs.query currentWindow: true, active: true, (tabs) ->
    ## Create array of tabs with open ports
    tabId = tabs[0].id
    ports[tabId] = port: port, portId: port.portId_, tab: tabId
    tabPort = ports[tabId].port

    tabChange = (activeInfo) ->
      chrome.contextMenus.removeAll()
      if activeInfo.tabId == tabId
        requestDomFlags(tabId, tabPort)

    ## When button in Tab is clicked, send message to devtools
    panelClick = (message, sender, sendResponse) ->
      if sender.tab.id == tabId
        port.postMessage
          name: "panelClick"
          key: message.key

    chrome.tabs.onActivated.addListener(tabChange)
    chrome.runtime.onMessage.addListener(panelClick)

    port.onDisconnect.addListener (port) ->
      chrome.contextMenus.removeAll()
      chrome.runtime.onMessage.removeListener(panelClick)
      chrome.tabs.onActivated.removeListener(tabChange)
      delete ports[tabId]

  # Create contextMenu when devtools opens
  port.onMessage.addListener (msg) ->
    chrome.tabs.query currentWindow: true, active: true, (tabs) ->
      tabId = tabs[0].id
      tabPort = ports[tabId].port
      chrome.contextMenus.removeAll()
      requestDomFlags(tabId, tabPort)
