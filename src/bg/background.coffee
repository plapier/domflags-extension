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

requestDomFlags = (tabs, port) ->
  chrome.tabs.sendMessage tabs[0].id, "Give me domflags" , (response) ->
    if response
      updateContextMenus(response.flags, port)

ports = []
chrome.runtime.onConnect.addListener (port) ->
  return if port.name isnt "devtools"

  port.onMessage.addListener (msg) ->
    chrome.tabs.query
      lastFocusedWindow: true
      active: true
    , (tabs) ->
      ## Create array of tabs with open ports
      ports[tabs[0].id] = port: port, portId: port.portId_, tab: tabs[0].id
      tabPort = ports[tabs[0].id].port
      requestDomFlags(tabs, tabPort)

  tabChange = ->
    chrome.tabs.query
      lastFocusedWindow: true
      active: true
    , (tabs) ->
      if ports[tabs[0].id]
        tabPort = ports[tabs[0].id].port
        requestDomFlags(tabs, tabPort)

  port.onDisconnect.addListener (port) ->
    chrome.contextMenus.removeAll()
    chrome.tabs.onActivated.removeListener(tabChange)
    chrome.tabs.query
      lastFocusedWindow: true
      active: true
    , (tabs) ->
      delete ports[tabs[0].id]

  chrome.tabs.onActivated.addListener(tabChange)

  # chrome.runtime.onMessage.addListener(panelClick)
  # chrome.runtime.onMessage.addListener (message, sender, sendResponse) ->
    # console.log message
    # port.postMessage
      # name: "panelClick"
      # key: message.key

# Run when Tab becomes active
chrome.tabs.onActivated.addListener (activeInfo) ->
  chrome.contextMenus.removeAll()
