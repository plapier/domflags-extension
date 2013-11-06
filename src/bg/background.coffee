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

  chrome.tabs.query lastFocusedWindow: true, active: true, (tabs) ->
    ## Create array of tabs with open ports
    ports[tabs[0].id] = port: port, portId: port.portId_, tab: tabs[0].id
    tabPort = ports[tabs[0].id].port

    port.onMessage.addListener (msg) ->
      requestDomFlags(tabs, tabPort)

    tabChange = ->
      if tabPort
        requestDomFlags(tabs, tabPort)

    ## When Panel in DOM is clicked, send message to devtools
    panelClick = (message, sender, sendResponse) ->
      if sender.tab.id == tabs[0].id
        port.postMessage
          name: "panelClick"
          key: message.key

    chrome.tabs.onActivated.addListener(tabChange)
    chrome.runtime.onMessage.addListener(panelClick)

    port.onDisconnect.addListener (port) ->
      chrome.contextMenus.removeAll()
      chrome.runtime.onMessage.removeListener(panelClick)
      chrome.tabs.onActivated.removeListener(tabChange)
      delete ports[tabs[0].id]

# Run when Tab becomes active
chrome.tabs.onActivated.addListener (activeInfo) ->
  chrome.contextMenus.removeAll()
