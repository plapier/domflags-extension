console.log "background.js"

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


chrome.runtime.onConnect.addListener (port) ->
  if port.name is "devtoolsConnect"
    console.log port.portId_
    port.onMessage.addListener (msg) ->
      chrome.tabs.query
        lastFocusedWindow: true
        active: true
      , (tabs) ->

        chrome.tabs.sendMessage tabs[0].id, "Give me domflags" , (response) ->
          if response
            updateContextMenus(response.flags, port)

    port.onDisconnect.addListener (port) ->
      chrome.contextMenus.removeAll()

    # chrome.tabs.onActivated.addListener (activeInfo) ->
      # console.log port.portId_

# openCount = 0
# chrome.runtime.onConnect.addListener (port) ->
  # if port.name is "devtools"
    # alert "DevTools window opening."  if openCount is 0
    # openCount++
    # port.onDisconnect.addListener (port) ->
      # openCount--
      # alert "Last DevTools window closing."  if openCount is 0


# Run when Tab becomes active
chrome.tabs.onActivated.addListener (activeInfo) ->
  chrome.contextMenus.removeAll()
  # ## Send message to content script to get DOM flags. Receive flags.
  # chrome.tabs.sendMessage activeInfo.tabId, "give me domflags" , (response) ->
    # if response
      # updateContextMenus(response.flags)
