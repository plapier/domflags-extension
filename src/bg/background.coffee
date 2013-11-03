console.log "background.js"

updateContextMenus = (flags, port) ->
  onClickHandler = (info, tab) ->
    console.log "Menu Clicked"
    port.postMessage
      name: "contextMenuClick"
      key: info.menuItemId
      tab: tab

  if flags.length > 0
    console.log "created context menus"
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
  # console.log port
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

  tabChange = ()->
    console.log "TabChange"
    chrome.tabs.query
      lastFocusedWindow: true
      active: true
    , (tabs) ->
      if ports[tabs[0].id]
        console.log "Found tab: " + ports[tabs[0].id]
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

# Run when Tab becomes active
chrome.tabs.onActivated.addListener (activeInfo) ->
  console.log ports
  chrome.contextMenus.removeAll()
