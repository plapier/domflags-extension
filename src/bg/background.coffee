console.log "background.js"

updateContextMenus = (flags, port) ->
  onClickHandler = (info, tab) ->
    console.log port
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

ports = []
chrome.runtime.onConnect.addListener (port) ->
  # console.log port
  return if port.name isnt "devtools"

  port.onMessage.addListener (msg) ->
    chrome.tabs.query
      lastFocusedWindow: true
      active: true
    , (tabs) ->

      ports[tabs[0].id] = port: port, portId: port.portId_, tab: tabs[0].id

      chrome.tabs.sendMessage tabs[0].id, "Give me domflags" , (response) ->
        if response
          updateContextMenus(response.flags, port)

  port.onDisconnect.addListener (port) ->
    chrome.contextMenus.removeAll()
    console.log ports[port.portId_]
    delete ports[port.portId_]

  chrome.tabs.onActivated.addListener (activeInfo) ->
    chrome.tabs.query
      lastFocusedWindow: true
      active: true
    , (tabs) ->

      chrome.tabs.sendMessage tabs[0].id, "Give me domflags" , (response) ->
        if response
          updateContextMenus(response.flags, ports[tabs[0].id].port)

    # Object.keys(ports).forEach (portId_) ->
      # ports[portId_].postMessage(name:"TabChange")

# Run when Tab becomes active
chrome.tabs.onActivated.addListener (activeInfo) ->
  console.log ports
  chrome.contextMenus.removeAll()

